import 'package:shared_preferences/shared_preferences.dart';

/// Сервис настроек, хранит флаги в shared_preferences.
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const _kRuleset = 'ruleset';
  static const _kBoardSize = 'boardSize';
  static const _kDifficulty = 'difficulty';
  static const _kHintsEnabled = 'hintsEnabled';
  static const _kPatternHighlight = 'patternHighlight';
  static const _kSoundEnabled = 'soundEnabled';
  static const _kPlayerName = 'playerName';

  String get ruleset => _prefs.getString(_kRuleset) ?? 'gomoku';
  set ruleset(String v) => _prefs.setString(_kRuleset, v);

  String get boardSize => _prefs.getString(_kBoardSize) ?? 'small9';
  set boardSize(String v) => _prefs.setString(_kBoardSize, v);

  String get difficulty => _prefs.getString(_kDifficulty) ?? 'easy';
  set difficulty(String v) => _prefs.setString(_kDifficulty, v);

  bool get hintsEnabled => _prefs.getBool(_kHintsEnabled) ?? true;
  set hintsEnabled(bool v) => _prefs.setBool(_kHintsEnabled, v);

  bool get patternHighlight => _prefs.getBool(_kPatternHighlight) ?? true;
  set patternHighlight(bool v) => _prefs.setBool(_kPatternHighlight, v);

  bool get soundEnabled => _prefs.getBool(_kSoundEnabled) ?? true;
  set soundEnabled(bool v) => _prefs.setBool(_kSoundEnabled, v);

  String get playerName => _prefs.getString(_kPlayerName) ?? 'Диана';
  set playerName(String v) => _prefs.setString(_kPlayerName, v);
}
