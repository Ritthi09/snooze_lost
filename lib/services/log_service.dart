import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

// ==========================================
// LOG MODEL
// ==========================================

class DrowsinessLog {
  final DateTime timestamp;
  final String type;
  final String level;
  final double duration;

  DrowsinessLog({
    required this.timestamp,
    required this.type,
    required this.level,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type,
    'level': level,
    'duration': duration,
  };

  factory DrowsinessLog.fromJson(Map<String, dynamic> json) => DrowsinessLog(
    timestamp: DateTime.parse(json['timestamp']),
    type: json['type'],
    level: json['level'],
    duration: (json['duration'] as num).toDouble(),
  );

  String toCsvRow() {
    final ts =
        '${timestamp.year}-'
        '${timestamp.month.toString().padLeft(2, '0')}-'
        '${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    return '$ts,$type,$level,${duration.toStringAsFixed(1)}';
  }
}

// ==========================================
// LOG SERVICE
// ==========================================

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  static const String _storageKey = 'snooze_lost_logs';
  final List<DrowsinessLog> _logs = [];
  bool _loaded = false;

  // โหลด log จาก LocalStorage
  Future<void> loadLogs() async {
    if (_loaded) return;
    try {
      final raw = web.window.localStorage.getItem(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(raw);
        _logs.clear();
        _logs.addAll(jsonList.map((j) => DrowsinessLog.fromJson(j)));
      }
      _loaded = true;
      debugPrint('Loaded ${_logs.length} logs from LocalStorage');
    } catch (e) {
      debugPrint('Load logs error: $e');
    }
  }

  // Save log ใหม่
  Future<void> addLog({
    required String type,
    required String level,
    required double duration,
  }) async {
    final log = DrowsinessLog(
      timestamp: DateTime.now(),
      type: type,
      level: level,
      duration: duration,
    );
    _logs.add(log);
    await _saveLogs();
    debugPrint('Log added: ${log.toCsvRow()}');
  }

  // Save ทั้งหมดลง LocalStorage
  Future<void> _saveLogs() async {
    try {
      final jsonStr = jsonEncode(_logs.map((l) => l.toJson()).toList());
      web.window.localStorage.setItem(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('Save logs error: $e');
    }
  }

  // ดึง log ทั้งหมด
  List<DrowsinessLog> get logs => List.unmodifiable(_logs);

  // นับจำนวน
  int get totalEyeClosed => _logs.where((l) => l.type == 'eye-closed').length;
  int get totalYawn => _logs.where((l) => l.type == 'yawn').length;
  int get totalWarning => _logs.where((l) => l.level == 'warning').length;
  int get totalDanger => _logs.where((l) => l.level == 'danger').length;

  // Export เป็น CSV
  void exportCsv() {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Snooze Lost - Drowsiness Log');
      buffer.writeln('Export Date: ${DateTime.now()}');
      buffer.writeln('');
      buffer.writeln('Timestamp,Type,Level,Duration(s)');
      for (final log in _logs) {
        buffer.writeln(log.toCsvRow());
      }
      buffer.writeln('');
      buffer.writeln('Summary');
      buffer.writeln('Total Eye-Closed,$totalEyeClosed');
      buffer.writeln('Total Yawn,$totalYawn');
      buffer.writeln('Total Warning,$totalWarning');
      buffer.writeln('Total Danger,$totalDanger');

      final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
      final blob = web.Blob(
        [bytes.buffer.toJS].toJS,
        web.BlobPropertyBag(type: 'text/csv'),
      );
      final url = web.URL.createObjectURL(blob);
      final filename =
          'snooze_lost_log_${DateTime.now().millisecondsSinceEpoch}.csv';

      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..setAttribute('download', filename)
        ..click();

      web.URL.revokeObjectURL(url);
      debugPrint('CSV exported: $filename');
    } catch (e) {
      debugPrint('Export CSV error: $e');
    }
  }

  // ล้าง log ทั้งหมด
  Future<void> clearLogs() async {
    _logs.clear();
    web.window.localStorage.removeItem(_storageKey);
    debugPrint('Logs cleared');
  }
}