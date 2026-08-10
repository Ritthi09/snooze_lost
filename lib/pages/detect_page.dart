import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:tflite_plus/tflite_plus.dart';
import 'statistics_page.dart';

// ==========================================
// ENUMS
// ==========================================

enum DrowsinessLevel { normal, warning, danger }

// ==========================================
// ISOLATE DATA — ส่งข้อมูลระหว่าง isolate
// ==========================================


// ==========================================
// PREPROCESS ใน isolate แยก (ไม่ block UI)
// ==========================================

Float32List _preprocessYUV(
  Uint8List yPlane,
  Uint8List uPlane,
  Uint8List vPlane,
  int srcW,
  int srcH,
  int uvRowStride,
  int uvPixelStride,
) {
  const int targetSize = 640;
  final output = Float32List(targetSize * targetSize * 3);

  final scaleX = srcW / targetSize;
  final scaleY = srcH / targetSize;

  int idx = 0;
  for (int ty = 0; ty < targetSize; ty++) {
    final sy = (ty * scaleY).toInt().clamp(0, srcH - 1);
    for (int tx = 0; tx < targetSize; tx++) {
      final sx = (tx * scaleX).toInt().clamp(0, srcW - 1);

      // Y value
      final yVal = yPlane[sy * srcW + sx] & 0xFF;

      // UV index — handle both interleaved (NV21/NV12) and planar
      final uvRow = sy >> 1;
      final uvCol = sx >> 1;
      final uvIdx = uvRow * uvRowStride + uvCol * uvPixelStride;
      
      final uVal = uvIdx < uPlane.length 
          ? (uPlane[uvIdx] & 0xFF).toDouble() - 128.0
          : 0.0;
      final vVal = uvIdx < vPlane.length 
          ? (vPlane[uvIdx] & 0xFF).toDouble() - 128.0
          : 0.0;

      final r = (yVal + 1.402 * vVal).clamp(0.0, 255.0) / 255.0;
      final g = (yVal - 0.344136 * uVal - 0.714136 * vVal).clamp(0.0, 255.0) / 255.0;
      final b = (yVal + 1.772 * uVal).clamp(0.0, 255.0) / 255.0;

      output[idx++] = r;
      output[idx++] = g;
      output[idx++] = b;
    }
  }
  return output;
}

// Top-level function สำหรับ compute()
Float32List _preprocessIsolate(List<dynamic> args) {
  final result = _preprocessYUV(
    args[0] as Uint8List,
    args[1] as Uint8List,
    args[2] as Uint8List,
    args[3] as int,
    args[4] as int,
    args[5] as int,
    args[6] as int,
  );
  
  // Debug pixel ตรงกลางภาพ
  final mid = (640 * 320 + 320) * 3;
  debugPrint('Pixel center: R=${result[mid].toStringAsFixed(3)} G=${result[mid+1].toStringAsFixed(3)} B=${result[mid+2].toStringAsFixed(3)}');
  debugPrint('Input range: min=${result.reduce((a,b) => a<b?a:b).toStringAsFixed(3)} max=${result.reduce((a,b) => a>b?a:b).toStringAsFixed(3)}');
  
  return result;
}

// ==========================================
// DETECT PAGE
// ==========================================

class DetectPage extends StatefulWidget {
  const DetectPage({super.key});

  @override
  State<DetectPage> createState() => _DetectPageState();
}

class _DetectPageState extends State<DetectPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 1;
  DrowsinessLevel _level = DrowsinessLevel.normal;
  CameraController? _cameraController;

  // ── AI Model ──
  Interpreter? _interpreter;
  List<List<List<double>>>? _outputBuffer; // reuse buffer
  bool _isProcessing = false;
  bool _modelReady = false;

  // ── Temporal Smoothing ──
  final List<bool> _eyeClosedHistory = [];
  static const int _historySize = 9;
  static const int _closedThreshold = 7;

  // ── Timer ──
  DateTime? _eyeClosedStart;
  static const double _warningDuration = 1.0;
  static const double _dangerDuration = 3.0;
  bool _alertShowing = false;

  // ── Frame control ──
  int _frameCount = 0;
  static const int _frameSkip = 5; // inference ทุก 5 frames ≈ 6fps inference

  // ── REC animation ──
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initModel().then((_) => _initCamera());
  }
  // ==========================================
  // LOAD MODEL
  // ==========================================

  Future<void> _initModel() async {
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/best_float32.tflite',
        options: options,
      );

      debugPrint('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      debugPrint('Input type: ${_interpreter!.getInputTensor(0).type}');
      debugPrint('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      debugPrint('Output type: ${_interpreter!.getOutputTensor(0).type}');
      // Pre-allocate output buffer ครั้งเดียว
      final outShape = _interpreter!.getOutputTensor(0).shape;
      debugPrint('Output shape: $outShape');
      _outputBuffer = List.generate(
        outShape[0],
        (_) => List.generate(
          outShape[1],
          (_) => List.filled(outShape[2], 0.0),
        ),
      );
      _modelReady = true;
      debugPrint('Model loaded ✅ output shape: $outShape');
    } catch (e) {
      debugPrint('Model load error: $e');
    }
  }

  // ==========================================
  // CAMERA INIT
  // ==========================================

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        front,
        ResolutionPreset.medium, // medium = 720p ดีกว่า low สำหรับ face detection
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() {});

      _cameraController!.startImageStream(_onFrame);
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  // ==========================================
  // FRAME HANDLER
  // ==========================================

  void _onFrame(CameraImage image) {
    _frameCount++;
    if (_frameCount % _frameSkip != 0) return;
    if (_isProcessing || !_modelReady || _interpreter == null) return;

    _isProcessing = true;

    // Copy plane data ก่อนส่ง isolate (ป้องกัน GC เก็บ)
    final yBytes = Uint8List.fromList(image.planes[0].bytes);
    final uBytes = Uint8List.fromList(image.planes[1].bytes);
    final vBytes = Uint8List.fromList(image.planes[2].bytes);
    final w = image.width;
    final h = image.height;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    // Preprocess ใน isolate แยก (ไม่ block UI thread)
    compute<List<dynamic>, Float32List>(_preprocessIsolate, [
      yBytes, uBytes, vBytes, w, h, uvRowStride, uvPixelStride,
    ]).then((inputData) {
      _runInference(inputData);
    }).catchError((e) {
      debugPrint('Preprocess error: $e');
      _isProcessing = false;
    });
  }

  // ==========================================
  // INFERENCE (main thread แต่ preprocess แยกแล้ว)
  // ==========================================

  void _runInference(Float32List inputData) {
  try {
    // แปลง HWC → CHW
    final nchw = Float32List(3 * 640 * 640);
    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final srcIdx = (y * 640 + x) * 3;
        nchw[0 * 640 * 640 + y * 640 + x] = inputData[srcIdx];
        nchw[1 * 640 * 640 + y * 640 + x] = inputData[srcIdx + 1];
        nchw[2 * 640 * 640 + y * 640 + x] = inputData[srcIdx + 2];
      }
    }
    
    final inputTensor = nchw.reshape([1, 3, 640, 640]);
    
    final buffer = _outputBuffer;
    if (buffer == null) return;

    for (var row in buffer[0]) {
      row.fillRange(0, row.length, 0.0);
    }

    _interpreter!.run(inputTensor, buffer as Object);
    _parseDetections(buffer[0]);
  } catch (e) {
    debugPrint('Inference error: $e');
  } finally {
    _isProcessing = false;
  }
}

  // ==========================================
  // PARSE DETECTIONS
  // ==========================================

  void _parseDetections(List<List<double>> detections) {
    final sorted = detections.where((d) => d.length >= 6).toList()
      ..sort((a, b) => b[4].compareTo(a[4]));
  
    for (int i = 0; i < 5 && i < sorted.length; i++) {
      final d = sorted[i];
      debugPrint('det[$i] conf=${d[4].toStringAsFixed(3)} class=${d[5].round()} box=[${d[0].toStringAsFixed(1)},${d[1].toStringAsFixed(1)},${d[2].toStringAsFixed(1)},${d[3].toStringAsFixed(1)}]');
    }
    double eyeOpenConf = 0.0;
    double eyeClosedConf = 0.0;
    int detectedCount = 0;

    for (final det in detections) {
      if (det.length < 6) continue;
      final conf = det[4];
      if (conf < 0.4) continue; // threshold ต่ำกว่าเดิมเพื่อ debug

      detectedCount++;
      final classId = det[5].round();

      if (classId == 0 && conf > eyeOpenConf) eyeOpenConf = conf;
      if (classId == 1 && conf > eyeClosedConf) eyeClosedConf = conf;
    }

    if (detectedCount > 0) {
      debugPrint('Detections above 0.4: $detectedCount | eye-open: ${eyeOpenConf.toStringAsFixed(2)} | eye-closed: ${eyeClosedConf.toStringAsFixed(2)}');
    }

    // Conflict resolution
    bool isEyeClosed = false;
    if (eyeClosedConf > 0 && eyeOpenConf > 0) {
      isEyeClosed = (eyeClosedConf - eyeOpenConf) >= 0.10;
    } else if (eyeClosedConf > 0.4) {
      isEyeClosed = true;
    }

    // Temporal smoothing
    _eyeClosedHistory.add(isEyeClosed);
    if (_eyeClosedHistory.length > _historySize) {
      _eyeClosedHistory.removeAt(0);
    }

    final closedCount = _eyeClosedHistory.where((v) => v).length;
    final confirmed = _eyeClosedHistory.length == _historySize &&
        closedCount >= _closedThreshold;

    _updateTimer(confirmed);
  }

  void _updateTimer(bool eyesClosed) {
    if (eyesClosed) {
      _eyeClosedStart ??= DateTime.now();
      final elapsed =
          DateTime.now().difference(_eyeClosedStart!).inMilliseconds / 1000.0;
      if (elapsed >= _dangerDuration) {
        _setLevel(DrowsinessLevel.danger);
      } else if (elapsed >= _warningDuration) {
        _setLevel(DrowsinessLevel.warning);
      }
    } else {
      _eyeClosedStart = null;
      _setLevel(DrowsinessLevel.normal);
    }
  }

  void _setLevel(DrowsinessLevel level) {
    if (!mounted) return;
    if (_level == level) return; // ไม่ setState ถ้าไม่เปลี่ยน
    setState(() => _level = level);
    if (level == DrowsinessLevel.danger && !_alertShowing) {
      _alertShowing = true;
      _showDangerAlert();
    }
  }

  // Public สำหรับ debug panel
  void updateDrowsinessLevel(DrowsinessLevel level) => _setLevel(level);

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _interpreter?.close();
    _pulseController.dispose();
    super.dispose();
  }

  // ==========================================
  // UI HELPERS
  // ==========================================

  Color get _boxColor {
    switch (_level) {
      case DrowsinessLevel.normal: return const Color(0xFF09F169);
      case DrowsinessLevel.warning: return const Color(0xFFFFC107);
      case DrowsinessLevel.danger: return const Color(0xFFFF3B30);
    }
  }

  String get _statusLabel {
    switch (_level) {
      case DrowsinessLevel.normal: return 'ปกติ';
      case DrowsinessLevel.warning: return 'เริ่มง่วง';
      case DrowsinessLevel.danger: return 'ง่วงมาก!';
    }
  }

  String get _statusDescription {
    switch (_level) {
      case DrowsinessLevel.normal: return 'คุณมีสติในการขับขี่';
      case DrowsinessLevel.warning: return 'โปรดมีสติในการขับขี่';
      case DrowsinessLevel.danger: return 'ควรพักผ่อนทันที';
    }
  }

  void _showDangerAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF5C5C5C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded,
                    color: Color(0xFFFF3B30), size: 40),
              ),
              const SizedBox(height: 20),
              Text('คุณกำลังง่วง',
                  style: GoogleFonts.kanit(
                      color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('กรุณาพักผ่อนทันที\nเพื่อความปลอดภัยของคุณ',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.kanit(
                      color: Colors.white60, fontSize: 15)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _alertShowing = false;
                    _eyeClosedStart = null;
                  },
                  child: Text('เข้าใจแล้ว',
                      style: GoogleFonts.kanit(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Camera
            Expanded(
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_cameraController != null &&
                        _cameraController!.value.isInitialized)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _cameraController!.value.previewSize!.height,
                          height: _cameraController!.value.previewSize!.width,
                          child: CameraPreview(_cameraController!),
                        ),
                      )
                    else
                      const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF09F169)),
                      ),

                    // กรอบ
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 200, height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: _boxColor, width: 2.5),
                        ),
                      ),
                    ),

                    // REC
                    Positioned(
                      top: 16, left: 16,
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (_, __) => Opacity(
                              opacity: _pulseAnimation.value,
                              child: Container(
                                width: 10, height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF09F169),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('REC',
                              style: GoogleFonts.kanit(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),

                    // Model status
                    Positioned(
                      top: 16, right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _modelReady ? 'AI ✅' : 'AI loading...',
                          style: GoogleFonts.kanit(
                              color: _modelReady
                                  ? const Color(0xFF09F169)
                                  : Colors.white54,
                              fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Status card
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                            color: _boxColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(_statusLabel,
                            key: ValueKey(_level),
                            style: GoogleFonts.kanit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _boxColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(_statusDescription,
                        key: ValueKey(_statusDescription),
                        style: GoogleFonts.kanit(
                            fontSize: 15, color: Colors.white70)),
                  ),
                ],
              ),
            ),

            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(icon: Icons.home, label: 'หน้าแรก', index: 0),
          _navItemCenter(label: 'ตรวจจับ'),
          _navItem(icon: Icons.bar_chart, label: 'สถิติ', index: 2),
        ],
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required int index}) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFF09F169) : Colors.white54;
    return GestureDetector(
      onTap: () {
        if (index == 0) Navigator.pop(context);
        if (index == 2) Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StatisticsPage()));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.kanit(fontSize: 16, color: color)),
        ],
      ),
    );
  }

  Widget _navItemCenter({required String label}) {
    final isActive = _currentIndex == 1;
    final color = isActive ? const Color(0xFF09F169) : Colors.white30;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.kanit(
                  fontSize: 16,
                  color: isActive
                      ? const Color(0xFF09F169)
                      : Colors.white54)),
        ],
      ),
    );
  }
}