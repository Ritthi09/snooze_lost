import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'log_service.dart';


class DrowsinessLog {
  final DateTime timestamp;
  final String level; // 'warning' หรือ 'danger'

  DrowsinessLog({required this.timestamp, required this.level});
}

class SessionLog {
  final DateTime startTime;
  DateTime? endTime;

  SessionLog({required this.startTime, this.endTime});

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
}

class StatsManager {
  static final StatsManager _instance = StatsManager._internal();
  factory StatsManager() => _instance;
  StatsManager._internal();

  final List<DrowsinessLog> logs = [];
  final List<SessionLog> sessions = [];
  SessionLog? _currentSession;

  // --- ระบบการจัดการ Session (จับเวลาการใช้งาน) ---
  void startSession() {
    if (_currentSession == null || _currentSession!.endTime != null) {
      _currentSession = SessionLog(startTime: DateTime.now());
      sessions.add(_currentSession!);
    }
  }

  void stopSession() {
    if (_currentSession != null && _currentSession!.endTime == null) {
      _currentSession!.endTime = DateTime.now();
    }
  }

  // --- ระบบบันทึก Log ---
  void addLog(String level) {
    if (level == 'warning' || level == 'danger') {
      logs.add(DrowsinessLog(timestamp: DateTime.now(), level: level));
    }
  }

  // --- Helper ตรวจสอบช่วงเวลา ---
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isInPeriod(DateTime date, int periodIndex) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (periodIndex) {
      case 0: // วันนี้
        return date.isAfter(todayStart);
      case 1: // 7 วันย้อนหลัง
        return date.isAfter(todayStart.subtract(const Duration(days: 6)));
      case 2: // 30 วันย้อนหลัง
        return date.isAfter(todayStart.subtract(const Duration(days: 29)));
      case 3: // ทั้งหมด
      default:
        return true;
    }
  }

  // --- ฟังก์ชันคำนวณค่าต่างๆ แยกตาม Filter ---

  // 1. ตรวจพบอาการง่วง (Warning Count)
  int getWarningCount(int periodIndex) {
    return logs.where((l) => l.level == 'warning' && _isInPeriod(l.timestamp, periodIndex)).length;
  }

  // คำนวณความต่างจากเมื่อวาน (ใช้เฉพาะกรณี periodIndex == 0)
  int getWarningDiffFromYesterday() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final todayCount = logs.where((l) => l.level == 'warning' && l.timestamp.isAfter(todayStart)).length;
    final yesterdayCount = logs.where((l) => l.level == 'warning' && l.timestamp.isAfter(yesterdayStart) && l.timestamp.isBefore(todayStart)).length;

    return todayCount - yesterdayCount;
  }

  // 2. อาการง่วงมาก (Danger Count)
  int getDangerCount(int periodIndex) {
    return logs.where((l) => l.level == 'danger' && _isInPeriod(l.timestamp, periodIndex)).length;
  }

  // 3. ระยะเวลาการใช้งาน
  Duration getTotalUsageDuration(int periodIndex) {
    Duration total = Duration.zero;
    for (var session in sessions) {
      // พิจารณาเฉพาะ session ที่อยู่ในช่วงเวลา
      if (_isInPeriod(session.startTime, periodIndex)) {
        total += session.duration;
      }
    }
    return total;
  }

  // ข้อความบอกเวลาเริ่มใช้งาน
  String getStartUsageText(int periodIndex) {
    final filteredSessions = sessions.where((s) => _isInPeriod(s.startTime, periodIndex)).toList();
    if (filteredSessions.isEmpty) return 'ยังไม่มีข้อมูลการใช้';

    final firstSession = filteredSessions.first;
    final start = firstSession.startTime;

    if (periodIndex == 0) {
      final hour = start.hour.toString().padLeft(2, '0');
      final minute = start.minute.toString().padLeft(2, '0');
      return 'เริ่มใช้งาน $hour.$minute น.';
    } else if (periodIndex == 1 || periodIndex == 2) {
      return 'เริ่มใช้งาน ${start.day}/${start.month}/${start.year}';
    } else {
      return 'เริ่มใช้งานทั้งหมด';
    }
  }

  // 4. ระดับความง่วงเฉลี่ย (0 = ต่ำ, 1 = ปานกลาง, 2 = สูง)
  double getAverageDrowsinessValue(int periodIndex) {
    final totalEvents = getWarningCount(periodIndex) + (getDangerCount(periodIndex) * 2);
    if (totalEvents == 0) return 0.0;
    if (totalEvents <= 3) return 0.0; // ต่ำ
    if (totalEvents <= 8) return 1.0; // ปานกลาง
    return 2.0; // สูง
  }

  String getAverageDrowsinessLabel(int periodIndex) {
    final val = getAverageDrowsinessValue(periodIndex);
    if (val == 0.0) return 'ต่ำ';
    if (val == 1.0) return 'ปานกลาง';
    return 'สูง';
  }

  // 5. ข้อมูลกราฟแท่ง
  List<double> getChartData(int periodIndex) {
    final now = DateTime.now();
    if (periodIndex == 0) { // รายชั่วโมง (แบ่งเป็นช่วงละ 3 ชม. 8 ช่วง)
      List<double> hourly = List.filled(8, 0);
      final todayLogs = logs.where((l) => _isSameDay(l.timestamp, now));
      for (var l in todayLogs) {
        int index = l.timestamp.hour ~/ 3;
        if (index < 8) hourly[index]++;
      }
      return hourly;
    } else if (periodIndex == 1) { // 7 วัน (จ. - อาท.)
      List<double> daily = List.filled(7, 0);
      final todayStart = DateTime(now.year, now.month, now.day);
      for (int i = 0; i < 7; i++) {
        final day = todayStart.subtract(Duration(days: 6 - i));
        daily[i] = logs.where((l) => _isSameDay(l.timestamp, day)).length.toDouble();
      }
      return daily;
    } else if (periodIndex == 2) { // 30 วัน / เดือนนี้ (แบ่งตามสัปดาห์ปฏิทิน)
        List<double> weekly = List.filled(4, 0);
        final now = DateTime.now();
        
        // กรองเฉพาะ log ที่เกิดใน "เดือนนี้" และ "ปีนี้" เท่านั้น
        final currentMonthLogs = logs.where((l) => 
          l.timestamp.year == now.year && l.timestamp.month == now.month
        );

        for (var l in currentMonthLogs) {
          // หาว่าวันที่ของ Log อยู่ในสัปดาห์ที่เท่าไหร่ของเดือน (1-7 = สัปดาห์ 1, 8-14 = สัปดาห์ 2, ...)
          int weekIndex = (l.timestamp.day - 1) ~/ 7;
          
          // หากเกิน 4 สัปดาห์ (เช่น วันที่ 29-31) ให้ปัดมารวมในสัปดาห์ที่ 4 (index 3)
          if (weekIndex > 3) weekIndex = 3;
          
          weekly[weekIndex]++;
        }
        return weekly;
    } else { // ภาพรวม 6 เดือน
      List<double> monthly = List.filled(6, 0);
      for (var l in logs) {
        int monthDiff = (now.year - l.timestamp.year) * 12 + (now.month - l.timestamp.month);
        int index = 5 - monthDiff;
        if (index >= 0 && index < 6) monthly[index]++;
      }
      return monthly;
    }
  }

  void clearStats() {
    logs.clear();
    sessions.clear();
    _currentSession = null;
  }
}