import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SensitivityLevel {
  low,
  medium,
  high,
}

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const SettingsSheet(),
  );
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  bool _notificationEnabled = true;
  bool _vibrationEnabled = true;
  SensitivityLevel _sensitivity = SensitivityLevel.medium;

 // share ref
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationEnabled = prefs.getBool('notification') ?? true;
      _vibrationEnabled = prefs.getBool('vibration') ?? true;
      final s = prefs.getInt('sensitivity') ?? 1;
      if (s >= 0 && s < SensitivityLevel.values.length) {
        _sensitivity = SensitivityLevel.values[s];
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification', _notificationEnabled);
    await prefs.setBool('vibration', _vibrationEnabled);
    await prefs.setInt('sensitivity', _sensitivity.index);
  }
 ///

  double get _sliderValue {
    switch (_sensitivity) {
      case SensitivityLevel.low:
        return 0;
      case SensitivityLevel.medium:
        return 1;
      case SensitivityLevel.high:
        return 2;
    }
  }

  String get _sensitivityDescription {
    switch (_sensitivity) {
      case SensitivityLevel.low:
        return 'ตรวจจับเมื่อหลับตานานกว่า 4-5 วินาที';
      case SensitivityLevel.medium:
        return 'ตรวจจับเมื่อหลับตานานกว่า 3 วินาที';
      case SensitivityLevel.high:
        return 'ตรวจจับเมื่อหลับตานานกว่า 1-2 วินาที';
    }
  }

  void _onSliderChanged(double value) async {
    setState(() {
      if (value <= 0.5) {
        _sensitivity = SensitivityLevel.low;
      } else if (value <= 1.5) {
        _sensitivity = SensitivityLevel.medium;
      } else {
        _sensitivity = SensitivityLevel.high;
      }
    });
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 20),

          // หัวข้อ
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                ),
              ),
              Text(
                'ตั้งค่า',
                style: GoogleFonts.kanit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Toggle options
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _toggleItem(
                  icon: Icons.notifications_outlined,
                  label: 'เปิดแจ้งเตือน',
                  value: _notificationEnabled,
                  onChanged: (v) async {
                    setState(() => _notificationEnabled = v);
                    await _saveSettings();
                  },
                ),
                const Divider(
                  color: Color.fromARGB(31, 255, 255, 255),
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                _toggleItem(
                  icon: Icons.vibration,
                  label: 'เปิดการสั่น',
                  value: _vibrationEnabled,
                  onChanged: (v) async {
                    setState(() => _vibrationEnabled = v);
                    await _saveSettings();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ระดับความไวในการตรวจจับ
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'ระดับความไวในการตรวจจับ',
              style: GoogleFonts.kanit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF09F169),
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF09F169).withOpacity(0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _sliderValue,
              min: 0,
              max: 2,
              divisions: 2,
              onChanged: _onSliderChanged,
            ),
          ),

          // Labels ต่ำ กลาง สูง
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sliderLabel('ต่ำ', SensitivityLevel.low),
                _sliderLabel('กลาง', SensitivityLevel.medium),
                _sliderLabel('สูง', SensitivityLevel.high),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _sensitivityDescription,
            style: GoogleFonts.kanit(
              color: Colors.white54,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _toggleItem({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.kanit(color: Colors.white, fontSize: 15),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF2FBD6A),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFD9D9D9),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderLabel(String label, SensitivityLevel level) {
    final isActive = _sensitivity == level;
    return Text(
      label,
      style: GoogleFonts.kanit(
        color: isActive ? Colors.white : Colors.white54,
        fontSize: 13,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}