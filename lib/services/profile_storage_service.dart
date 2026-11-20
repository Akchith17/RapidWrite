import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/evaluation_result.dart';
import '../models/practice_settings.dart';
import 'aesthetic/stage3_reference_profile.dart';

// Proper Flutter conditional import — avoids dart:html on non-web platforms
import 'storage_web.dart' if (dart.library.io) 'storage_io.dart';

/// Service managing persistent storage of personal handwriting reference profiles
/// and historical evaluation session records across browser reloads and app restarts.
class ProfileStorageService {
  static final ProfileStorageService _instance = ProfileStorageService._internal();
  factory ProfileStorageService() => _instance;
  ProfileStorageService._internal();

  static const String _profileKey  = 'rapidwrite_personal_profile_v1';
  static const String _historyKey  = 'rapidwrite_session_history_v1';
  static const String _settingsKey = 'rapidwrite_practice_settings_v1';
  static const String _themeKey    = 'rapidwrite_theme_preference_v1';

  PersonalHandwritingProfile? _cachedProfile;
  PersonalHandwritingProfile? get cachedProfile => _cachedProfile;
  bool get hasProfile => _cachedProfile != null;

  PracticeSettings? _cachedSettings;
  PracticeSettings get cachedSettings => _cachedSettings ?? PracticeSettings.defaultSettings();

  /// Initializes and loads the stored profile into memory cache.
  Future<void> initialize() async {
    _cachedProfile = await loadProfile();
    _cachedSettings = await loadSettings();
  }

  /// Loads stored user practice settings or returns default settings
  Future<PracticeSettings> loadSettings() async {
    try {
      String? jsonStr;
      if (kIsWeb) {
        jsonStr = localStorageGet(_settingsKey);
      } else {
        final file = await _getSettingsFile();
        if (await file.exists()) {
          jsonStr = await file.readAsString();
        }
      }

      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          _cachedSettings = PracticeSettings.fromJson(decoded);
          return _cachedSettings!;
        }
      }
    } catch (e) {
      debugPrint('[ProfileStorage] Load settings error: $e');
    }
    _cachedSettings = PracticeSettings.defaultSettings();
    return _cachedSettings!;
  }

  /// Persists user practice settings
  Future<void> saveSettings(PracticeSettings settings) async {
    _cachedSettings = settings;
    try {
      final jsonStr = jsonEncode(settings.toJson());
      if (kIsWeb) {
        localStorageSet(_settingsKey, jsonStr);
      } else {
        final file = await _getSettingsFile();
        await file.writeAsString(jsonStr, flush: true);
      }
      debugPrint('[ProfileStorage] Saved practice settings successfully.');
    } catch (e) {
      debugPrint('[ProfileStorage] Save settings error: $e');
    }
  }

  /// Saves theme preference ('dark' or 'light')
  Future<void> saveThemeMode(String mode) async {
    try {
      if (kIsWeb) {
        localStorageSet(_themeKey, mode);
      }
    } catch (e) {
      debugPrint('[ProfileStorage] Save theme error: $e');
    }
  }

  /// Loads theme preference
  Future<String?> loadThemeMode() async {
    try {
      if (kIsWeb) {
        return localStorageGet(_themeKey);
      }
    } catch (e) {
      debugPrint('[ProfileStorage] Load theme error: $e');
    }
    return null;
  }

  /// Loads the stored personal handwriting reference profile.
  Future<PersonalHandwritingProfile?> loadProfile() async {
    try {
      String? jsonStr;

      if (kIsWeb) {
        jsonStr = localStorageGet(_profileKey);
      } else {
        final file = await _getProfileFile();
        if (await file.exists()) {
          jsonStr = await file.readAsString();
        }
      }

      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          _cachedProfile = PersonalHandwritingProfile.fromJson(decoded);
          return _cachedProfile;
        }
      }
    } catch (e) {
      debugPrint('[ProfileStorage] Load profile error: $e');
    }
    return null;
  }

  /// Persists a new or updated personal handwriting profile.
  Future<void> saveProfile(PersonalHandwritingProfile profile) async {
    _cachedProfile = profile;
    try {
      final jsonStr = jsonEncode(profile.toJson());

      if (kIsWeb) {
        localStorageSet(_profileKey, jsonStr);
      } else {
        final file = await _getProfileFile();
        await file.writeAsString(jsonStr, flush: true);
      }
      debugPrint('[ProfileStorage] Saved personal reference profile successfully.');
    } catch (e) {
      debugPrint('[ProfileStorage] Save profile error: $e');
    }
  }

  /// Clears stored reference profile for recalibration.
  Future<void> clearProfile() async {
    _cachedProfile = null;
    try {
      if (kIsWeb) {
        localStorageRemove(_profileKey);
      } else {
        final file = await _getProfileFile();
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('[ProfileStorage] Clear profile error: $e');
    }
  }

  /// Saves an evaluation session record to session history.
  Future<void> recordSession(EvaluationResult result) async {
    try {
      final history = await loadHistory();
      final sessionMap = result.toJson();

      // Prepend newest session (keep last 50 sessions)
      history.insert(0, sessionMap);
      if (history.length > 50) history.removeRange(50, history.length);

      final jsonStr = jsonEncode(history);

      if (kIsWeb) {
        localStorageSet(_historyKey, jsonStr);
      } else {
        final file = await _getHistoryFile();
        await file.writeAsString(jsonStr, flush: true);
      }
    } catch (e) {
      debugPrint('[ProfileStorage] Record session error: $e');
    }
  }

  /// Retrieves the list of historical evaluation sessions.
  Future<List<Map<String, dynamic>>> loadHistory() async {
    try {
      String? jsonStr;
      if (kIsWeb) {
        jsonStr = localStorageGet(_historyKey);
      } else {
        final file = await _getHistoryFile();
        if (await file.exists()) {
          jsonStr = await file.readAsString();
        }
      }

      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('[ProfileStorage] Load history error: $e');
    }
    return [];
  }

  Future<File> _getProfileFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/rapidwrite_profile.json');
  }

  Future<File> _getHistoryFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/rapidwrite_history.json');
  }

  Future<File> _getSettingsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/rapidwrite_settings.json');
  }
}
