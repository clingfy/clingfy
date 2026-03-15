import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:clingfy/app/infrastructure/logging/logger_service.dart';

class FileLogSink {
  static final FileLogSink _instance = FileLogSink._internal();
  File? _logFile;
  final _writeQueue = <String>[];
  bool _isWriting = false;

  factory FileLogSink() {
    return _instance;
  }

  FileLogSink._internal();

  Future<void> init() async {
    try {
      final logsDir = await _ensureLogsDirectory();
      if (logsDir == null) {
        _logFile = null;
        return;
      }

      final fileName = _dailyLogFileName(DateTime.now());
      _logFile = File.fromUri(logsDir.uri.resolve(fileName));
      debugPrint("FileLogSink initialized: ${_logFile?.path}");
    } catch (e) {
      _logFile = null;
      debugPrint("Error initializing FileLogSink: $e");
    }
  }

  void append(LogEvent event) {
    if (_logFile == null) return;
    try {
      final jsonStr = jsonEncode(event.toJson());
      _writeQueue.add(jsonStr);
      _processQueue();
    } catch (e) {
      debugPrint("Error encoding log event: $e");
    }
  }

  Future<void> _processQueue() async {
    if (_isWriting || _writeQueue.isEmpty || _logFile == null) return;
    _isWriting = true;

    try {
      final batch = List<String>.from(_writeQueue);
      _writeQueue.clear();
      final content = '${batch.join('\n')}\n';
      await _logFile!.writeAsString(content, mode: FileMode.append);
    } catch (e) {
      debugPrint("Error writing logs to file: $e");
      // If write fails, maybe put back in queue? Avoiding for now to prevent loops.
    } finally {
      _isWriting = false;
      if (_writeQueue.isNotEmpty) {
        _processQueue();
      }
    }
  }

  Future<Directory?> _ensureLogsDirectory() async {
    try {
      final appSupport = await getApplicationSupportDirectory();
      final logsDir = Directory.fromUri(appSupport.uri.resolve('Logs/'));
      await logsDir.create(recursive: true);
      return logsDir;
    } catch (e) {
      debugPrint("Error preparing log directory: $e");
      return null;
    }
  }

  String _dailyLogFileName(DateTime now) {
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    return "logs_$dateStr.jsonl";
  }
}
