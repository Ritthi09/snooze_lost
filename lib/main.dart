import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
              // ส่วนบน — โลโก้ + ชื่อ + คำอธิบาย
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
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'เพื่อความปลอดภัยของคุณ',
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // ส่วนล่าง — ปุ่ม
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DetectPage()),
                        );
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
                      label: Text(
                        'ตั้งค่า',
                        style: GoogleFonts.kanit(fontSize: 22),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'AI Drowsiness Detection App',
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
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