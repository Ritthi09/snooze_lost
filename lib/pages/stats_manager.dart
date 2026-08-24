import 'package:flutter/foundation.dart';
import 'detect_page.dart';
import 'statistics_page.dart';

class DrowsinessLog {
  final DateTime timestamp;
  final String level; // 'warning' หรือ 'danger'

  DrowsinessLog({required this.timestamp, required this.level});
}

class StatsManager {
  // Singleton pattern เพื่อให้ใช้ข้อมูลชุดเดียวกันทั้งแอป
  static final StatsManager _instance = StatsManager._internal();
  factory StatsManager() => _instance;
  StatsManager._internal();

  int warningCount = 0;
  int dangerCount = 0;
  final List<DrowsinessLog> logs = [];

  void addLog(String level) {
    if (level == 'warning') {
      warningCount++;
      logs.add(DrowsinessLog(timestamp: DateTime.now(), level: 'warning'));
    } else if (level == 'danger') {
      dangerCount++;
      logs.add(DrowsinessLog(timestamp: DateTime.now(), level: 'danger'));
    }
  }

  void clearStats() {
    warningCount = 0;
    dangerCount = 0;
    logs.clear();
  }
}