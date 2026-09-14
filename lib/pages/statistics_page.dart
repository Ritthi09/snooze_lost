import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import '../services/stats_manager.dart';
import '../services/log_service.dart';

const String pulse = '<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 28 28"><path d="M0 0h28v28H0z" fill="none" /><path fill="currentColor" d="M10.035 3a1 1 0 0 1 .94.78l3.712 16.496l3.864-11.592a1 1 0 0 1 1.878-.055L22.177 13H25a1 1 0 1 1 0 2h-3.5a1 1 0 0 1-.928-.629l-.987-2.465l-4.136 12.41a1 1 0 0 1-1.925-.096L9.862 7.94l-1.904 6.347A1 1 0 0 1 7 15H3a1 1 0 1 1 0-2h3.256l2.786-9.287A1 1 0 0 1 10.035 3" /></svg>';
const String bell = '<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24"><path d="M0 0h24v24H0z" fill="none" /><path fill="currentColor" d="M17.133 12.632v-1.8a5.406 5.406 0 0 0-4.154-5.262A1 1 0 0 0 13 5.464V3.1a1 1 0 0 0-2 0v2.364a1 1 0 0 0 .021.106a5.406 5.406 0 0 0-4.154 5.262v1.8C6.867 15.018 5 15.614 5 16.807C5 17.4 5 18 5.538 18h12.924C19 18 19 17.4 19 16.807c0-1.193-1.867-1.789-1.867-4.175M6 6a1 1 0 0 1-.707-.293l-1-1a1 1 0 0 1 1.414-1.414l1 1A1 1 0 0 1 6 6m-2 4H3a1 1 0 0 1 0-2h1a1 1 0 1 1 0 2m14-4a1 1 0 0 1-.707-1.707l1-1a1 1 0 1 1 1.414 1.414l-1 1A1 1 0 0 1 18 6m3 4h-1a1 1 0 1 1 0-2h1a1 1 0 1 1 0 2M8.823 19a3.453 3.453 0 0 0 6.354 0z" /></svg>';
const String caution = '<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 48 50"><path d="M0 0h48v48H0z" fill="none" /><defs><mask id="SVG5u6ebeaz"><g fill="none" stroke-width="4"><path fill="#fff" fill-rule="evenodd" stroke="#fff" stroke-linejoin="round" d="M24 5L2 43h44z" clip-rule="evenodd" /><path stroke="#000" stroke-linecap="round" d="M24 35v1m0-17l.008 10" /></g></mask></defs><path fill="currentColor" d="M0 0h48v48H0z" mask="url(#SVG5u6ebeaz)" /></svg>';
const String moon = '<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24"> <path d="M0 0h24v24H0z" fill="none" /> <path fill="currentColor" d="M20.71 13.51c-.78.23-1.58.35-2.38.35c-4.52 0-8.2-3.68-8.2-8.2c0-.8.12-1.6.35-2.38a1.002 1.002 0 0 0-1.25-1.25A10.17 10.17 0 0 0 2 11.8C2 17.42 6.58 22 12.2 22c4.53 0 8.45-2.91 9.76-7.24a1.002 1.002 0 0 0-1.25-1.25" /> <path fill="currentColor" d="m16 8l.94-2.06L19 5l-2.06-.94L16 2l-.94 2.06L13 5l2.06.94zm4.25-.5l-.55 1.2l-1.2.55l1.2.55l.55 1.2l.55-1.2l1.2-.55l-1.2-.55z" /> </svg>';
const String sleeping = '<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24"><path d="M0 0h24v24H0z" fill="none" /><g fill="none"><path stroke="currentColor" stroke-linecap="round" stroke-width="1" d="M6.5 11c.567.63 1.256 1 2 1s1.433-.37 2-1m3 0c.567.63 1.256 1 2 1s1.433-.37 2-1" /><path fill="currentColor" d="M13 16a1 1 0 1 1-2 0a1 1 0 0 1 2 0" /><path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="m17 4l3.464-2L19 7.464l3.464-2m-8.416.036l1.732 1l-2.732.732l1.732 1" /><path stroke="currentColor" stroke-linecap="round" stroke-width="1" d="M22 12c0 5.523-4.477 10-10 10a9.96 9.96 0 0 1-5-1.338M12 2C6.477 2 2 6.477 2 12c0 1.821.487 3.53 1.338 5" /></g></svg>';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _currentIndex = 2;
  int _selectedPeriod = 0;

  final List<String> _periods = ['วันนี้', '7 วัน', '30 วัน', 'ทั้งหมด'];

  final Map<int, List<String>> _chartLabels = {
    0: ['00', '03', '06', '09', '12', '15', '18', '21'],
    1: ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'],
    2: ['สัปดาห์ 1', 'สัปดาห์ 2', 'สัปดาห์ 3', 'สัปดาห์ 4'],
  };

  final Map<int, String> _chartTitle = {
    0: 'แนวโน้มการตรวจพบอาการง่วง (รายชั่วโมง)',
    1: 'แนวโน้มการตรวจพบอาการง่วง (รายวัน)',
    2: 'แนวโน้มการตรวจพบอาการง่วง (รายสัปดาห์)',
    3: 'แนวโน้มการตรวจพบอาการง่วง (ภาพรวม)',
  };

  List<String> _getLast7DaysLabels() {
  const dayNames = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
  final now = DateTime.now();
  return List.generate(7, (i) {
    DateTime date = now.subtract(Duration(days: 6 - i));
    return dayNames[date.weekday - 1];
  });
}
  // 🟢 เพิ่มฟังก์ชันนี้ลงไปตรงนี้ครับ
  List<String> _getLast6MonthsLabels() {
    const monthNames = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    final now = DateTime.now();
    return List.generate(6, (i) {
      int monthIndex = (now.month - 1 - (5 - i)) % 12;
      if (monthIndex < 0) monthIndex += 12;
      return monthNames[monthIndex];
    });
  }

  // แปลง Duration ให้เป็นข้อความแบบ "X ชม. Y นาที"
  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours ชม. $minutes นาที';
    }
    return '$minutes นาที';
  }

  @override
  Widget build(BuildContext context) {
    final stats = StatsManager();

    // ดึงค่าตาม Period ที่กดเลือก
    final warningCount = stats.getWarningCount(_selectedPeriod);
    final dangerCount = stats.getDangerCount(_selectedPeriod);
    final usageDuration = stats.getTotalUsageDuration(_selectedPeriod);
    final startText = stats.getStartUsageText(_selectedPeriod);
    final avgLevelLabel = stats.getAverageDrowsinessLabel(_selectedPeriod);
    final avgLevelValue = stats.getAverageDrowsinessValue(_selectedPeriod);

    // Subtitle การตรวจพบอาการง่วง
    String warningSubtitle = '';
    Color warningSubtitleColor = const Color(0xFF09F169);
    if (_selectedPeriod == 0) {
      int diff = stats.getWarningDiffFromYesterday();
      warningSubtitle = diff >= 0 ? 'เพิ่มขึ้นจากเมื่อวาน +$diff ครั้ง' : 'ลดลงจากเมื่อวาน $diff ครั้ง';
    } else {
      warningSubtitle = 'รวมการตรวจพบทั้งหมด';
      warningSubtitleColor = Colors.white54;
    }

    // สีของระดับความง่วง
    Color avgColor = const Color(0xFF09F169); // ต่ำ = เขียว
    if (avgLevelValue == 1.0) avgColor = const Color(0xFFFF9500); // ปานกลาง = ส้ม
    if (avgLevelValue == 2.0) avgColor = const Color(0xFFFF3B30); // สูง = แดง

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                'สถิติ',
                style: GoogleFonts.kanit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildPeriodSelector(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Row 1
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _statCard(
                              iconifyIcon: bell,
                              iconColor: const Color(0xFF09F169),
                              title: 'ตรวจพบอาการง่วง',
                              value: '$warningCount ครั้ง',
                              subtitle: warningSubtitle,
                              subtitleColor: warningSubtitleColor,
                              iconSize: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              iconifyIcon: Mdi.clock_outline,
                              iconColor: const Color(0xFFFFD600),
                              title: 'ระยะเวลาการใช้งาน',
                              value: _formatDuration(usageDuration),
                              subtitle: startText,
                              subtitleColor: Colors.white54,
                              iconSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Row 2
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _sensitivityCard(
                              levelLabel: avgLevelLabel,
                              levelValue: avgLevelValue,
                              levelColor: avgColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              iconifyIcon: caution,
                              iconColor: const Color(0xFFFF3B30),
                              title: 'อาการง่วงมาก',
                              value: '$dangerCount ครั้ง',
                              valueColor: const Color(0xFFFF3B30),
                              subtitle: 'ควรพักผ่อนให้เพียงพอ',
                              subtitleColor: Colors.white54,
                              iconSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildChart(stats.getChartData(_selectedPeriod)),
                    const SizedBox(height: 16),
                    _buildAdviceCard(),
                    const SizedBox(height: 8),
                    // เพิ่มใน SingleChildScrollView ต่อจาก _buildAdviceCard()
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C2E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          debugPrint('Logs count: ${LogService().logs.length}');
                          if (LogService().logs.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('ยังไม่มีข้อมูล log ครับ',
                                    style: GoogleFonts.kanit()),
                                backgroundColor: const Color(0xFF2C2C2E),
                              ),
                            );
                            return;
                          }
                          LogService().exportCsv();
                        },
                        icon: const Icon(Icons.download, color: Color(0xFF09F169)),
                        label: Text('Export Log (.csv)',
                            style: GoogleFonts.kanit(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        children: List.generate(_periods.length, (i) {
          final isSelected = _selectedPeriod == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF09F169) : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _periods[i],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.kanit(
                    color: isSelected ? Colors.black : Colors.white54,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _statCard({
    IconData? icon,
    String? iconifyIcon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
    Color valueColor = Colors.white,
    required double iconSize,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.31),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: iconifyIcon != null
                      ? Iconify(iconifyIcon, color: iconColor, size: iconSize - 4)
                      : Icon(icon, color: iconColor, size: iconSize - 4),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: GoogleFonts.kanit(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.kanit(
                color: valueColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subtitle,
              style: GoogleFonts.kanit(
                color: subtitleColor,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sensitivityCard({
    required String levelLabel,
    required double levelValue,
    required Color levelColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.31),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Iconify(
                    pulse,
                    color: levelColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ระดับความง่วงเฉลี่ย',
                    style: GoogleFonts.kanit(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              levelLabel,
              style: GoogleFonts.kanit(
                color: levelColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: levelColor,
              inactiveTrackColor: Colors.white24,
              thumbColor: levelColor,
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              trackHeight: 2,
            ),
            child: Slider(
              value: levelValue,
              min: 0,
              max: 2,
              onChanged: null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['ต่ำ', 'ปานกลาง', 'สูง'].map((l) => Text(
                l,
                style: GoogleFonts.kanit(color: Colors.white38, fontSize: 9),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<double> data) {
    final labels = _selectedPeriod == 1
      ? _getLast7DaysLabels()
      : (_selectedPeriod == 3 
          ? _getLast6MonthsLabels() 
          : (_chartLabels[_selectedPeriod] ?? []));

  double maxVal = data.isEmpty ? 8 : data.reduce((a, b) => a > b ? a : b);
    final double yMax = maxVal < 8 ? 8 : maxVal; // สเกลขั้นต่ำ 8
    const chartHeight = 140.0;
    const labelHeight = 20.0;

    final yLabels = [yMax.toInt(), (yMax * 0.75).toInt(), (yMax * 0.5).toInt(), (yMax * 0.25).toInt(), 0];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _chartTitle[_selectedPeriod] ?? '',
            style: GoogleFonts.kanit(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: chartHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: yLabels.map((v) => Text(
                    '$v',
                    style: GoogleFonts.kanit(color: Colors.white38, fontSize: 10),
                  )).toList(),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: chartHeight,
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(yLabels.length, (_) =>
                              Row(children: [
                                Expanded(child: Container(height: 1, color: Colors.white12)),
                              ]),
                            ),
                          ),
                          Positioned(
                            left: 0, top: 0, bottom: 0,
                            child: Container(width: 1, color: Colors.white24),
                          ),
                          Positioned(
                            left: 0, right: 0, bottom: 0,
                            child: Container(height: 1, color: Colors.white24),
                          ),
                          Positioned.fill(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(data.length, (i) {
                                final ratio = yMax == 0 ? 0.0 : data[i] / yMax;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 400),
                                        height: (chartHeight - 1) * ratio,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF09F169),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: labelHeight,
                      child: Row(
                        children: List.generate(data.length, (i) =>
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                i < labels.length ? labels[i] : '',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.kanit(color: Colors.white54, fontSize: 10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Iconify(
            moon, 
            color: const Color(0xFF09F169), 
            size: 44, 
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'คำแนะนำ',
                  style: GoogleFonts.kanit(
                    color: const Color(0xFF09F169),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'คุณควรพักผ่อนให้เพียงพอ\nเพื่อความปลอดภัยในการขับขี่',
                  style: GoogleFonts.kanit(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Iconify(
            sleeping, 
            color: const Color(0xFF09F169), 
            size: 36, 
          )
        ],
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _navItem(icon: Icons.home, label: 'หน้าแรก', index: 0)),
          Expanded(child: _navItem(icon: Icons.videocam, label: 'ตรวจจับ', index: 1)),
          Expanded(child: _navItem(icon: Icons.bar_chart, label: 'สถิติ', index: 2)),
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
        if (index == 0) {
          Navigator.popUntil(context, (route) => route.isFirst);
        } else if (index == 1) {
          Navigator.pop(context);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 28,
            child: Center(
              child: index == 1
                  ? Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color,
                          width: 2,
                        ),
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
                    )
                  : Icon(icon, color: color, size: 28),
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
}