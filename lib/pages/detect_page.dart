import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'statistics_page.dart';
import 'stats_manager.dart';

@JS('detectVideo')
external JSPromise _callDetectVideo(web.Element video);

enum DrowsinessLevel { normal, warning, danger }

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

  bool _isProcessing = false;
  bool _modelReady = false;
  Timer? _inferenceTimer;

  DateTime? _eyeClosedStart;
  bool _alertShowing = false;

  // 🟢 Buffer สำหรับทำ Temporal Smoothing (กันเฟรมหลุด/กระพริบตา)
  final List<bool> _historyFrames = [];

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

  Future<void> _initModel() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _modelReady = true;
        });
      }
    } catch (e) {
      debugPrint('Model load error: $e');
    }
  }

  Future<void> _runInferenceOnWeb() async {
    if (_isProcessing ||
        !_modelReady ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    _isProcessing = true;

    try {
      final videoElement = web.document.querySelector('video');

      if (videoElement != null) {
        final JSAny? resultJS = await _callDetectVideo(videoElement).toDart;

        if (resultJS != null) {
          final String resultStr = resultJS.isA<JSString>()
              ? (resultJS as JSString).toDart
              : resultJS.toString();

          _processYoloResult(resultStr);
        }
      }
    } catch (e) {
      debugPrint("Error running inference: $e");
    } finally {
      _isProcessing = false;
    }
  }

  // 🟢 ประกาศตัวแปรนับเฟรมสะสมไว้ที่ระดับ Class (ใส่นอกฟังก์ชัน หรือด้านบนสุดของ State)
  int _consecutiveClosedFrames = 0;

  void _processYoloResult(String rawJsonStr) {
    try {
      final List<dynamic> rawList = jsonDecode(rawJsonStr);
      if (rawList.isEmpty) return;

      double maxEyeOpenConf = 0.0;
      double maxEyeClosedConf = 0.0;
      const double confThreshold = 0.30;

      // 1. Parse Data จาก Output
      if (rawList.first is List) {
        for (var box in rawList) {
          final List<dynamic> row = box as List<dynamic>;
          if (row.length >= 6) {
            double score = (row[4] as num).toDouble();
            int classId = (row[5] as num).toInt();

            if (score > confThreshold) {
              if (classId == 0 && score > maxEyeOpenConf) {
                maxEyeOpenConf = score;
              } else if (classId == 1 && score > maxEyeClosedConf) {
                maxEyeClosedConf = score;
              }
            }
          }
        }
      } else {
        final List<double> output =
            rawList.map((e) => (e as num).toDouble()).toList();
        if (output.length < 1800) return;

        for (int i = 0; i < 300; i++) {
          int baseIdx = i * 6;
          if (baseIdx + 5 < output.length) {
            double score = output[baseIdx + 4];
            int classId = output[baseIdx + 5].round();

            if (score > confThreshold) {
              if (classId == 0 && score > maxEyeOpenConf) {
                maxEyeOpenConf = score;
              } else if (classId == 1 && score > maxEyeClosedConf) {
                maxEyeClosedConf = score;
              }
            }
          }
        }
      }

      debugPrint(
          "Open: ${maxEyeOpenConf.toStringAsFixed(2)} | Closed: ${maxEyeClosedConf.toStringAsFixed(2)}");

      // 🟢 2. เช็กว่าเฟรมปัจจุบัน "หลับตา" หรือไม่
      bool isClosedThisFrame = (maxEyeClosedConf > (maxEyeOpenConf + 0.10)) &&
          (maxEyeClosedConf > confThreshold);

      // 🟢 3. คำนวณตามจำนวนเฟรมที่หลับตาติดต่อกัน (Inference ทำงานทุก 150ms)
      if (isClosedThisFrame) {
        _consecutiveClosedFrames++;
      } else {
        // ถ้าลืมตาแม้แต่เฟรมเดียว หรือมั่นใจว่าตาเปิด ให้ตัดนับใหม่ทันที
        _consecutiveClosedFrames = 0;
      }

      // 🟢 4. กำหนดสถานะตามจำนวนเฟรมหลับตา (150ms ต่อ 1 เฟรม)
      // - หลับตาต่อเนื่อง 15 เฟรม (~2.25 วินาทีขึ้นไป) -> ง่วงมาก (Danger)
      // - หลับตาต่อเนื่อง 5 เฟรม (~0.75 วินาทีขึ้นไป)  -> เริ่มง่วง (Warning)
      // - น้อยกว่า 5 เฟรม                           -> ปกติ (Normal)
      if (_consecutiveClosedFrames >= 8) {
        _setLevel(DrowsinessLevel.danger);
      } else if (_consecutiveClosedFrames >= 2) {
        _setLevel(DrowsinessLevel.warning);
      } else {
        _setLevel(DrowsinessLevel.normal);
      }

    } catch (e) {
      debugPrint("Error parsing YOLO result: $e");
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
        StatsManager().startSession();

        _inferenceTimer = Timer.periodic(
          const Duration(milliseconds: 150),
          (_) => _runInferenceOnWeb(),
        );
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  void _setLevel(DrowsinessLevel level) {
    if (!mounted || _level == level) return;
    setState(() => _level = level);

    if (level == DrowsinessLevel.warning) {
      StatsManager().addLog('warning');
    } else if (level == DrowsinessLevel.danger) {
      StatsManager().addLog('danger');
      if (!_alertShowing) {
        _alertShowing = true;
        _showDangerAlert();
      }
    }
  }

  @override
  void dispose() {
    StatsManager().stopSession();
    _inferenceTimer?.cancel();
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color get _boxColor {
    switch (_level) {
      case DrowsinessLevel.normal:
        return const Color(0xFF09F169);
      case DrowsinessLevel.warning:
        return const Color(0xFFFFC107);
      case DrowsinessLevel.danger:
        return const Color(0xFFFF3B30);
    }
  }

  String get _statusLabel {
    switch (_level) {
      case DrowsinessLevel.normal:
        return 'ปกติ';
      case DrowsinessLevel.warning:
        return 'เริ่มง่วง';
      case DrowsinessLevel.danger:
        return 'ง่วงมาก!';
    }
  }

  String get _statusDescription {
    switch (_level) {
      case DrowsinessLevel.normal:
        return 'คุณมีสติในการขับขี่';
      case DrowsinessLevel.warning:
        return 'โปรดมีสติในการขับขี่';
      case DrowsinessLevel.danger:
        return 'ควรพักผ่อนทันที';
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
                width: 64,
                height: 64,
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
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('กรุณาพักผ่อนทันที\nเพื่อความปลอดภัยของคุณ',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.kanit(
                      color: Colors.white60, fontSize: 15)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
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
                    _consecutiveClosedFrames = 0; // 👈 รีเซ็ตจำนวนเฟรมเมื่อกดปิดแจ้งเตือน
                    _setLevel(DrowsinessLevel.normal);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_cameraController != null &&
                        _cameraController!.value.isInitialized)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double cameraAspectRatio =
                              _cameraController!.value.aspectRatio;

                          if (cameraAspectRatio > 1) {
                            cameraAspectRatio = 1 / cameraAspectRatio;
                          }
                          return ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  height: constraints.maxWidth /
                                      cameraAspectRatio,
                                  child: CameraPreview(_cameraController!),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(Icons.person,
                              size: 100, color: Colors.white24),
                        ),
                      ),
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: _boxColor, width: 2.5),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (_, __) => Opacity(
                              opacity: _pulseAnimation.value,
                              child: Container(
                                width: 10,
                                height: 10,
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
                    Positioned(
                      top: 16,
                      right: 16,
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

            // Status Card
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _boxColor,
                          shape: BoxShape.circle,
                        ),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: _navItem(
              icon: Icons.home,
              label: 'หน้าแรก',
              index: 0,
            ),
          ),
          Expanded(
            child: _navItemCenter(label: 'ตรวจจับ'),
          ),
          Expanded(
            child: _navItem(
              icon: Icons.bar_chart,
              label: 'สถิติ',
              index: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFF09F169) : Colors.white54;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (index == 0) Navigator.pop(context);
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatisticsPage()),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 28,
            child: Center(
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.kanit(
              fontSize: 13,
              color: color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItemCenter({required String label}) {
    final isActive = _currentIndex == 1;
    final color = isActive ? const Color(0xFF09F169) : Colors.white30;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 28,
            child: Center(
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.kanit(
              fontSize: 13,
              color: isActive ? const Color(0xFF09F169) : Colors.white54,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}