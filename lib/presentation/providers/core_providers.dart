import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendzu/core/audio/audio_service.dart';
import 'package:rendzu/core/prefs/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Глобальный аудио-сервис.
final audioServiceProvider = Provider<AudioService>((ref) {
  final s = AudioService();
  ref.onDispose(s.dispose);
  return s;
});

/// Инициализированный SharedPreferences (читается асинхронно).
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// Сервис настроек (зависит от SharedPreferences).
final settingsServiceProvider = Provider<SettingsService?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  if (prefs == null) return null;
  return SettingsService(prefs);
});
