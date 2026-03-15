import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clingfy/app/infrastructure/logging/logger_service.dart';
import 'package:clingfy/core/bridges/native_bridge.dart';

class WorkspaceSettingsController extends ChangeNotifier {
  WorkspaceSettingsController({required NativeBridge nativeBridge})
    : _nativeBridge = nativeBridge;

  static const String logFileNotFoundErrorCode = 'LOG_FILE_NOT_FOUND';
  static const String logFileUnavailableErrorCode = 'LOG_FILE_UNAVAILABLE';

  final NativeBridge _nativeBridge;
  static const String _prefSaveFolderPath = 'saveFolderPath';
  static const String _prefWarnBeforeClosingUnexportedRecording =
      'warnBeforeClosingUnexportedRecording';
  static const String _prefShowPreRecordingActionBar =
      'showPreRecordingActionBar';

  bool _openFolderAfterStop = false;
  bool _openFolderAfterExport = true;
  bool _warnBeforeClosingUnexportedRecording = true;
  bool _showPreRecordingActionBar = true;
  String? _saveFolderPath;
  bool _didAutoOpenSaveFolderThisSession = false;

  bool get openFolderAfterStop => _openFolderAfterStop;
  bool get openFolderAfterExport => _openFolderAfterExport;
  bool get warnBeforeClosingUnexportedRecording =>
      _warnBeforeClosingUnexportedRecording;
  bool get showPreRecordingActionBar => _showPreRecordingActionBar;
  String? get saveFolderPath => _saveFolderPath;

  Future<void> loadPreferences(SharedPreferences prefs) async {
    _openFolderAfterStop = prefs.getBool('openFolderAfterStop') ?? false;
    _openFolderAfterExport = prefs.getBool('openFolderAfterExport') ?? true;
    _warnBeforeClosingUnexportedRecording =
        prefs.getBool(_prefWarnBeforeClosingUnexportedRecording) ?? true;
    _showPreRecordingActionBar =
        prefs.getBool(_prefShowPreRecordingActionBar) ?? true;
    _saveFolderPath = prefs.getString(_prefSaveFolderPath);
    if (_saveFolderPath == null || _saveFolderPath!.isEmpty) {
      await _loadSaveFolder(prefs);
    }
    notifyListeners();
  }

  Future<void> _cacheSaveFolderPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.isEmpty) {
      await prefs.remove(_prefSaveFolderPath);
    } else {
      await prefs.setString(_prefSaveFolderPath, path);
    }
  }

  Future<void> _loadSaveFolder(SharedPreferences prefs) async {
    try {
      final path = await _nativeBridge.invokeMethod<String>('getSaveFolder');
      _saveFolderPath = path;
      if (path == null || path.isEmpty) {
        await prefs.remove(_prefSaveFolderPath);
      } else {
        await prefs.setString(_prefSaveFolderPath, path);
      }
    } catch (e, st) {
      Log.e('Settings', 'Error loading save folder', e, st);
    }
  }

  Future<void> updateOpenFolderAfterStop(bool value) async {
    if (value == _openFolderAfterStop) return;
    _openFolderAfterStop = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setBool('openFolderAfterStop', value);
    } catch (e, st) {
      Log.e(
        'Settings',
        'Failed to persist open folder after stop setting',
        e,
        st,
      );
    }
  }

  Future<void> updateOpenFolderAfterExport(bool value) async {
    if (value == _openFolderAfterExport) return;
    _openFolderAfterExport = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setBool('openFolderAfterExport', value);
    } catch (e, st) {
      Log.e(
        'Settings',
        'Failed to persist open folder after export setting',
        e,
        st,
      );
    }
  }

  Future<void> updateWarnBeforeClosingUnexportedRecording(bool value) async {
    if (value == _warnBeforeClosingUnexportedRecording) return;
    _warnBeforeClosingUnexportedRecording = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setBool(_prefWarnBeforeClosingUnexportedRecording, value);
    } catch (e, st) {
      Log.e('Settings', 'Failed to persist close warning preference', e, st);
    }
  }

  Future<void> updateShowPreRecordingActionBar(bool value) async {
    if (value == _showPreRecordingActionBar) return;
    _showPreRecordingActionBar = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setBool(_prefShowPreRecordingActionBar, value);
    } catch (e, st) {
      Log.e('Settings', 'Failed to persist action bar preference', e, st);
    }

    try {
      await _nativeBridge.setPreRecordingBarEnabled(value);
    } catch (e, st) {
      Log.e('Settings', 'Failed to update native action bar preference', e, st);
    }
  }

  Future<String?> chooseSaveFolderPath() async {
    try {
      final path = await _nativeBridge.invokeMethod<String>('chooseSaveFolder');
      if (path != null) {
        _saveFolderPath = path;
        await _cacheSaveFolderPath(path);
        notifyListeners();
      }
      return path;
    } catch (e, st) {
      Log.e('Settings', 'Error choosing save folder', e, st);
      return null;
    }
  }

  Future<void> chooseSaveFolder() async {
    await chooseSaveFolderPath();
  }

  Future<void> resetSaveFolder() async {
    try {
      final path = await _nativeBridge.invokeMethod<String>('resetSaveFolder');
      _saveFolderPath = path;
      await _cacheSaveFolderPath(path);
      notifyListeners();
    } catch (e, st) {
      Log.e('Settings', 'Error resetting save folder', e, st);
    }
  }

  Future<bool> _openSaveFolderNative() async {
    try {
      await _nativeBridge.invokeMethod<void>('openSaveFolder');
      return true;
    } catch (e, st) {
      Log.e('Settings', 'Error opening save folder', e, st);
      return false;
    }
  }

  Future<bool> openSaveFolderOncePerSession() async {
    if (_didAutoOpenSaveFolderThisSession) {
      return false;
    }

    final didOpen = await _openSaveFolderNative();
    if (didOpen) {
      _didAutoOpenSaveFolderThisSession = true;
    }
    return didOpen;
  }

  Future<void> openSaveFolder() async {
    await _openSaveFolderNative();
  }

  Future<void> revealFile(String path) async {
    try {
      await _nativeBridge.invokeMethod<void>('revealFile', {'path': path});
    } catch (e, st) {
      Log.e('Settings', 'Error revealing file', e, st);
    }
  }

  Future<String?> getTodayLogFilePath() async {
    try {
      return await _nativeBridge.invokeMethod<String>('getTodayLogFilePath');
    } catch (e) {
      Log.w('Settings', 'Error getting today log path: $e');
      return null;
    }
  }

  Future<void> revealTodayLogFile() async {
    try {
      await _nativeBridge.invokeMethod<void>('revealTodayLogFile');
    } on PlatformException catch (e) {
      throw StateError(e.message ?? logFileNotFoundErrorCode);
    } catch (e, st) {
      Log.e('Settings', 'Error revealing today log file', e, st);
      rethrow;
    }
  }

  Future<void> revealLogsFolder() async {
    try {
      await _nativeBridge.invokeMethod<void>('revealLogsFolder');
    } catch (e, st) {
      Log.e('Settings', 'Error revealing logs folder', e, st);
    }
  }

  Future<void> copyTodayLogFilePathToClipboard() async {
    final path = await getTodayLogFilePath();
    if (path != null) {
      await Clipboard.setData(ClipboardData(text: path));
    } else {
      throw StateError(logFileUnavailableErrorCode);
    }
  }
}
