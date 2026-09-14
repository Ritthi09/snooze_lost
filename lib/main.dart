import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/splash_screen.dart';
import 'pages/detect_page.dart';
import 'pages/settings_sheet.dart';

void main() {
  runApp(const SnoozeLostApp());
}

class SnoozeLostApp extends StatelessWidget {
  const SnoozeLostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Snooze Lost',
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _checkPdpa();
  }

  Future<void> _checkPdpa() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('pdpa_accepted') ?? false;
    if (!accepted && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _showPdpaDialog();
    }
  }

  Future<void> _showPdpaDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PdpaDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.nightlight_round,
                      color: Colors.greenAccent,
                      size: 100,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Snooze',
                      style: GoogleFonts.kanit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Lost',
                      style: GoogleFonts.kanit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF09F169),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ตรวจจับความง่วงขณะขับรถ',
                      style: GoogleFonts.kanit(fontSize: 18, color: Colors.white),
                    ),
                    Text(
                      'เพื่อความปลอดภัยของคุณ',
                      style: GoogleFonts.kanit(fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),

              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 240,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF09F169),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final accepted = prefs.getBool('pdpa_accepted') ?? false;
                          if (!accepted && mounted) {
                            await _showPdpaDialog();
                            return;
                          }
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DetectPage()),
                            );
                          }
                        },
                        child: Text(
                          'เริ่มใช้งาน',
                          style: GoogleFonts.kanit(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: 135,
                      height: 60,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF242424),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => showSettingsSheet(context),
                        icon: const Icon(Icons.settings, size: 20),
                        label: Text('ตั้งค่า', style: GoogleFonts.kanit(fontSize: 22)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'AI Drowsiness Detection App',
                      style: GoogleFonts.kanit(fontSize: 16, color: Colors.white70),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PDPA Dialog
// ==========================================

class _PdpaDialog extends StatefulWidget {
  const _PdpaDialog();

  @override
  State<_PdpaDialog> createState() => _PdpaDialogState();
}

class _PdpaDialogState extends State<_PdpaDialog> {
  bool _scrolledToBottom = false;
  bool _agreed = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 10) {
        if (!_scrolledToBottom) setState(() => _scrolledToBottom = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onAccept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pdpa_accepted', true);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _onDecline() async {
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF09F169).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.privacy_tip_outlined,
                    color: Color(0xFF09F169),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'นโยบายความเป็นส่วนตัว',
                  style: GoogleFonts.kanit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),
            Text(
              'PDPA — โปรดอ่านก่อนใช้งาน',
              style: GoogleFonts.kanit(
                color: const Color(0xFF09F169),
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section('📷 การเข้าถึงกล้อง',
                          'แอปนี้ต้องการเข้าถึงกล้องหน้าของอุปกรณ์เพื่อวิเคราะห์ความง่วงของผู้ขับขี่แบบ Real-time โดยใช้ AI'),
                      _section('🔒 การเก็บข้อมูล',
                          'ภาพจากกล้องจะถูกประมวลผลบนอุปกรณ์ของคุณเท่านั้น (On-device) ไม่มีการส่งภาพหรือวิดีโอไปยังเซิร์ฟเวอร์ใดๆ'),
                      _section('📊 สถิติการใช้งาน',
                          'แอปจะบันทึกจำนวนครั้งที่ตรวจพบอาการง่วงและระยะเวลาการใช้งาน เพื่อแสดงในหน้าสถิติ ข้อมูลนี้เก็บไว้ในอุปกรณ์ของคุณเท่านั้น'),
                      _section('⚠️ ข้อจำกัดความรับผิดชอบ',
                          'แอปนี้เป็นเครื่องมือช่วยเตือน ไม่ใช่อุปกรณ์ทางการแพทย์ ผู้ขับขี่ต้องรับผิดชอบต่อความปลอดภัยในการขับขี่ด้วยตนเองเสมอ'),
                      _section('📞 ติดต่อ',
                          'หากมีข้อสงสัยเกี่ยวกับนโยบายความเป็นส่วนตัว กรุณาติดต่อทีมพัฒนา'),
                      const SizedBox(height: 8),
                      Text(
                        'การกดยอมรับถือว่าคุณได้อ่านและยินยอมตามนโยบายนี้แล้ว',
                        style: GoogleFonts.kanit(
                          color: Colors.white54,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (!_scrolledToBottom) ...[
              const SizedBox(height: 8),
              Text(
                '⬇ เลื่อนลงเพื่ออ่านให้ครบก่อนยอมรับ',
                style: GoogleFonts.kanit(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Checkbox
            GestureDetector(
              onTap: _scrolledToBottom
                  ? () => setState(() => _agreed = !_agreed)
                  : null,
              child: Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: _scrolledToBottom
                        ? (v) => setState(() => _agreed = v ?? false)
                        : null,
                    activeColor: const Color(0xFF09F169),
                    checkColor: Colors.black,
                    side: BorderSide(
                      color: _scrolledToBottom
                          ? Colors.white54
                          : Colors.white24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'ฉันได้อ่านและยอมรับนโยบายความเป็นส่วนตัว',
                      style: GoogleFonts.kanit(
                        color: _scrolledToBottom
                            ? Colors.white70
                            : Colors.white30,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _onDecline,
                    child: Text(
                      'ไม่ยอมรับ',
                      style: GoogleFonts.kanit(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _agreed
                          ? const Color(0xFF09F169)
                          : Colors.white12,
                      foregroundColor: _agreed ? Colors.black : Colors.white30,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _agreed ? _onAccept : null,
                    child: Text(
                      'ยอมรับ',
                      style: GoogleFonts.kanit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.kanit(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: GoogleFonts.kanit(
              color: Colors.white60,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}