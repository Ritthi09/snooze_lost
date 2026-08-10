import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

//เรียกไอคอน จาก iconify
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

  final Map<int, List<double>> _chartData = {
    0: [1, 0, 2, 0, 8, 3, 0, 1, 2],
    1: [2, 1, 0, 3, 6, 4, 2],
    2: [1, 3, 2, 6],
    3: [1, 2, 4, 3, 5, 3],
  };

  final Map<int, List<String>> _chartLabels = {
    0: ['00', '03', '06', '09', '12', '15', '18', '21', '24'],
    1: ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'],
    2: ['สัปดาห์ 1', 'สัปดาห์ 2', 'สัปดาห์ 3', 'สัปดาห์ 4'],
    3: ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.'],
  };

  final Map<int, String> _chartTitle = {
    0: 'แนวโน้มการตรวจพบอาการง่วง (รายชั่วโมง)',
    1: 'แนวโน้มการตรวจพบอาการง่วง (รายวัน)',
    2: 'แนวโน้มการตรวจพบอาการง่วง (รายสัปดาห์)',
    3: 'แนวโน้มการตรวจพบอาการง่วง (ภาพรวม)',
  };

  @override
  Widget build(BuildContext context) {
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
                              value: '2 ครั้ง',
                              subtitle: 'เพิ่มขึ้นจากเมื่อวาน +1 ครั้ง',
                              subtitleColor: const Color(0xFF09F169),
                              iconSize: 24
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              iconifyIcon: Mdi.clock_outline,
                              iconColor: const Color(0xFFFFD600),
                              title: 'ระยะเวลาการใช้งาน',
                              value: '1 ชม. 9 นาที',
                              subtitle: 'เริ่มใช้งาน 19.30 น.',
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
                          Expanded(child: _sensitivityCard()),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              iconifyIcon: caution,
                              iconColor: const Color(0xFFFF3B30),
                              title: 'อาการง่วงมาก',
                              value: '2 ครั้ง',
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
                    _buildChart(),
                    const SizedBox(height: 16),
                    _buildAdviceCard(),
                    const SizedBox(height: 8),
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
      padding: const EdgeInsets.all(14),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.31),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: iconifyIcon != null
                      ? Iconify(iconifyIcon, color: iconColor, size: iconSize) // ดึงขนาดตามที่สั่งมา
                      : Icon(icon, color: iconColor, size: iconSize),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.kanit(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.kanit(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.kanit(
              color: subtitleColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sensitivityCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0833D).withOpacity(0.31),
                  shape: BoxShape.circle,
                ),
                child: Center( 
                  child: Iconify(
                    pulse, 
                    color: const Color(0xFFE0833D), 
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ระดับความง่วงเฉลี่ย',
                style: GoogleFonts.kanit(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ปานกลาง',
            style: GoogleFonts.kanit(
              color: const Color(0xFFFF9500),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFF9500),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFFFF9500),
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              trackHeight: 2,
            ),
            child: Slider(
              value: 1,
              min: 0,
              max: 2,
              onChanged: null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['ต่ำ', 'ปานกลาง', 'สูง'].map((l) => Text(
                l,
                style: GoogleFonts.kanit(color: Colors.white38, fontSize: 10),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildChart() {
  final data = _chartData[_selectedPeriod] ?? [];
  final labels = _chartLabels[_selectedPeriod] ?? [];
  const int yMax = 8;
  const chartHeight = 140.0;
  const labelHeight = 20.0;

  // 8, 6, 4, 2, 0
  final yLabels = [8, 6, 4, 2, 0];

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
            // Y-axis labels
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

            // Chart area
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: chartHeight,
                    child: Stack(
                      children: [
                        // เส้นประ grid
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(yLabels.length, (_) =>
                            Row(children: [
                              Expanded(child: Container(height: 1, color: Colors.white12)),
                            ]),
                          ),
                        ),

                        // เส้น Y ซ้าย
                        Positioned(
                          left: 0, top: 0, bottom: 0,
                          child: Container(width: 1, color: Colors.white24),
                        ),

                        // เส้น X ล่าง
                        Positioned(
                          left: 0, right: 0, bottom: 0,
                          child: Container(height: 1, color: Colors.white24),
                        ),

                        // Bars
                        Positioned.fill(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(data.length, (i) {
                              final ratio = data[i] / yMax;
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
                          child: Text(
                            i < labels.length ? labels[i] : '',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.kanit(color: Colors.white54, fontSize: 10),
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
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16, right: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Iconify(
            moon, 
            color: const Color(0xFF09F169), 
            size: 64, 
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
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Iconify(
            sleeping, 
            color: const Color(0xFF09F169), 
            size: 44, 
          )
        ],
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
          _navItem(icon: Icons.videocam, label: 'ตรวจจับ', index: 1),
          _navItem(icon: Icons.bar_chart, label: 'สถิติ', index: 2),
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

    if (index == 1) {
      final isActive = _currentIndex == 1;
      return GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? const Color(0xFF09F169) : Colors.white30,
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF09F169) : Colors.white30,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.kanit(
                fontSize: 16,
                color: isActive ? const Color(0xFF09F169) : Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
        // index 2 อยู่หน้านี้แล้ว
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.kanit(fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }
}