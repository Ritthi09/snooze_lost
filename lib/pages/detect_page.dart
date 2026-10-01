import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:camera/camera.dart';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/log_service.dart';
import '../services/stats_manager.dart';
import 'statistics_page.dart';

// ==========================================
// JS Interop
// ==========================================

@JS('detectVideo')
external JSPromise _callDetectVideo(web.Element video);

@JS('playWarningAlert')
external void _playWarningAlert();

@JS('playDangerAlert')
external void _playDangerAlert();

@JS('stopDangerAlert')
external void _stopDangerAlert();

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

  // 🟢 ตัวแปรสำหรับจับเวลาจริง (Real-time tracking)
  DateTime? _eyeClosedStartTime;
  DateTime? _eyeOpenStartTime;

  bool _alertShowing = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ⚡ ตัวแปรสำหรับโหมดประหยัดพลังงาน (Power Saving Mode)
  Timer? _powerSaveTimer;
  bool _isPowerSaving = false;
  static const Duration _powerSaveTimeout = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    LogService().loadLogs();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initModel().then((_) => _initCamera());

    // เริ่มจับเวลา 5 นาทีสำหรับโหมดประหยัดพลังงาน
    _resetPowerSaveTimer();
  }

  /// รีเซ็ตตัวจับเวลา 5 นาทีเพื่อเข้าสู่โหมดประหยัดพลังงาน
  void _resetPowerSaveTimer() {
    _powerSaveTimer?.cancel();
    _powerSaveTimer = Timer(_powerSaveTimeout, _enterPowerSavingMode);
  }

  /// เข้าสู่โหมดประหยัดพลังงาน
  void _enterPowerSavingMode() {
    if (!mounted || _isPowerSaving) return;

    setState(() {
      _isPowerSaving = true;
    });

    // หยุด Animation ชั่วคราวเพื่อประหยัด GPU/CPU
    _pulseController.stop();

    // ปรับรอบการทำงานของ AI ให้ช้าลง (จาก 150ms เป็น 1000ms)
    _startInferenceTimer(intervalMs: 150);
  }

  /// ออกจากโหมดประหยัดพลังงาน
  void _disablePowerSavingMode() {
    if (!mounted) return;

    setState(() {
      _isPowerSaving = false;
    });

    // เล่น Animation ต่อ
    _pulseController.repeat(reverse: true);

    // ปรับรอบการทำงานของ AI กลับมาเป็นความเร็วปกติ (150ms)
    _startInferenceTimer(intervalMs: 150);

    // เริ่มนับเวลา 5 นาทีใหม่อีกครั้ง
    _resetPowerSaveTimer();
  }

  /// เริ่มต้น / เปลี่ยนรอบเวลาของ Inference Timer
  void _startInferenceTimer({int intervalMs = 150}) {
    _inferenceTimer?.cancel();
    _inferenceTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => _runInferenceOnWeb(),
    );
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

  void _processYoloResult(String rawJsonStr) {
    if (_alertShowing) return;
    try {
      final List<dynamic> rawList = jsonDecode(rawJsonStr);
      if (rawList.isEmpty) return;

      double maxEyeOpenConf = 0.0;
      double maxEyeClosedConf = 0.0;
      const double confThreshold = 0.40;

      if (rawList.first is List) {
        for (var box in rawList) {
          final List<dynamic> row = box as List<dynamic>;
          if (row.length >= 6) {
            double score = (row[4] as num).toDouble();
            int classId = (row[5] as num).toInt();
            if (score > confThreshold) {
              if (classId == 0 && score > maxEyeOpenConf) maxEyeOpenConf = score;
              if (classId == 1 && score > maxEyeClosedConf) maxEyeClosedConf = score;
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
              if (classId == 0 && score > maxEyeOpenConf) maxEyeOpenConf = score;
              if (classId == 1 && score > maxEyeClosedConf) maxEyeClosedConf = score;
            }
          }
        }
      }

      debugPrint('Open: ${maxEyeOpenConf.toStringAsFixed(2)} | Closed: ${maxEyeClosedConf.toStringAsFixed(2)}');

      bool isClosedThisFrame = (maxEyeClosedConf > (maxEyeOpenConf + 0.40)) && (maxEyeClosedConf > 0.60);

      final now = DateTime.now();

      if (isClosedThisFrame) {
        _eyeOpenStartTime = null;
        _eyeClosedStartTime ??= now;

        final closedMs = now.difference(_eyeClosedStartTime!).inMilliseconds;

        if (closedMs >= 4500) {
          _setLevel(DrowsinessLevel.danger);
        } else if (closedMs >= 1300) {
          if (_level == DrowsinessLevel.normal) {
            _setLevel(DrowsinessLevel.warning);
          }
        }
      } else {
        _eyeClosedStartTime = null;
        _eyeOpenStartTime ??= now;

        final openMs = now.difference(_eyeOpenStartTime!).inMilliseconds;

        if (_level == DrowsinessLevel.danger) {
          if (openMs >= 2000) {
            _setLevel(DrowsinessLevel.warning);
          }
        } else if (_level == DrowsinessLevel.warning) {
          if (openMs >= 500) {
            _setLevel(DrowsinessLevel.normal);
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing YOLO result: $e');
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
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
        StatsManager().startSession();

        _startInferenceTimer(intervalMs: 150);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  void _setLevel(DrowsinessLevel level) {
    if (!mounted || _level == level) return;
    
    setState(() => _level = level);

    if (level == DrowsinessLevel.normal) {
      _stopDangerAlert();
    } else if (level == DrowsinessLevel.warning) {
      _stopDangerAlert();
      _playWarningAlert();
      final duration = _eyeClosedStartTime != null
        ? DateTime.now().difference(_eyeClosedStartTime!).inMilliseconds / 1000.0
        : 0.0;
      StatsManager().addLog('warning');
      LogService().addLog(type: 'eye-closed', level: 'warning', duration: duration);

    } else if (level == DrowsinessLevel.danger) {
      _playDangerAlert();
      final duration = _eyeClosedStartTime != null
        ? DateTime.now().difference(_eyeClosedStartTime!).inMilliseconds / 1000.0
        : 0.0;
      StatsManager().addLog('danger');
      LogService().addLog(type: 'eye-closed', level: 'danger', duration: duration);
      if (!_alertShowing) {
        _alertShowing = true;
        _showDangerAlert();
      }
    }
  }

  @override
  void dispose() {
    _powerSaveTimer?.cancel();
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
    if (!mounted) return;

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
                    _stopDangerAlert();
                    if (Navigator.canPop(context)) Navigator.pop(context);
                    _alertShowing = false;
                    _eyeClosedStartTime = null;
                    _eyeOpenStartTime = null;
                    if (mounted) _setLevel(DrowsinessLevel.normal);
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
                    // 1. ตัวกล้อง
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

                    // 🟢 2. Border Glow (เรืองแสงแค่ขอบ ละลายเข้าข้างใน ไม่บังหน้า)
                    if (_level != DrowsinessLevel.normal)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              final double opacity = _level == DrowsinessLevel.danger
                                  ? _pulseAnimation.value
                                  : _pulseAnimation.value * 0.6;

                              return CustomPaint(
                                painter: EdgeGlowPainter(
                                  color: _boxColor.withOpacity(opacity),
                                  strokeWidth: _level == DrowsinessLevel.danger ? 16.0 : 8.0,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // 3. REC Badge (มุมซ้ายบน)
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

                    // 4. AI Status Badge (มุมขวาบน)
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

                    // ⚡ 5. Power Saving Mode Overlay (แสดงเมื่อเปิดค้างไว้เกิน 5 นาที)
                    if (_isPowerSaving)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.95),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.battery_saver_rounded,
                                  color: Color(0xFF09F169),
                                  size: 56,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'โหมดประหยัดพลังงาน',
                                  style: GoogleFonts.kanit(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'ตรวจจับความถี่ลดลงเพื่อประหยัดแบตเตอรี่',
                                  style: GoogleFonts.kanit(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF09F169),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: _disablePowerSavingMode,
                                  icon: const Icon(Icons.power_settings_new),
                                  label: Text(
                                    'ปิดโหมดประหยัดพลังงาน',
                                    style: GoogleFonts.kanit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                        duration: const Duration(milliseconds: 150), // 🟢 ลดเวลาลงเหลือ 150ms เพื่อให้สลับข้อความไวขึ้น ไม่ค้างซ้อน
                        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                          return Stack(
                            alignment: Alignment.center, // 🟢 ซ้อนทับตรงจุดศูนย์กลางเป๊ะๆ ไม่เยื้อง
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: Text(
                          _statusLabel,
                          key: ValueKey('label_${_level.name}'), // 🟢 ใส่ Key แบบเฉพาะเจาะจง
                          style: GoogleFonts.kanit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _boxColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150), // 🟢 ลดเวลาลงเหลือ 150ms
                    layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    child: Text(
                      _statusDescription,
                      key: ValueKey('desc_${_level.name}'), // 🟢 ใส่ Key แบบเฉพาะเจาะจง
                      style: GoogleFonts.kanit(
                        fontSize: 15, 
                        color: Colors.white70,
                      ),
                    ),
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
        if (!mounted) return;
        if (index == 0) Navigator.pop(context);
        if (index == 2) {
          _inferenceTimer?.cancel();
          _stopDangerAlert();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatisticsPage()),
          ).then((_) {
            _startInferenceTimer(intervalMs: _isPowerSaving ? 1000 : 150);
          });
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
      onTap: () {
        if (!mounted) return;
        setState(() => _currentIndex = 1);
      },
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

class EdgeGlowPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  EdgeGlowPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // วาดเฉพาะเส้นขอบตรงๆ ไม่มี Effect ฟุ้ง
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), strokePaint);
  }

  @override
  bool shouldRepaint(covariant EdgeGlowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}