import 'package:rendzu/domain/models/point.dart';

/// Набор правил: гомоку (свободное пять в ряд) или рэндзю (с запрещёнными
/// ходами для чёрных).
enum Ruleset { gomoku, renju }

extension RulesetX on Ruleset {
  String get russianName =>
      this == Ruleset.gomoku ? 'Гомоку' : 'Рэндзю';

  String get russianDescription => switch (this) {
        Ruleset.gomoku => 'Свободное пять в ряд — без запрещённых ходов',
        Ruleset.renju =>
          'Рэндзю — у чёрных есть запрещённые ходы (двойное три, двойное четыре, оверлайн)',
      };
}

/// Размер доски.
enum BoardSize { small9, standard15 }

extension BoardSizeX on BoardSize {
  int get dimension => switch (this) {
        BoardSize.small9 => 9,
        BoardSize.standard15 => 15,
      };

  String get russianName => '$dimension×$dimension';

  static BoardSize fromDimension(int d) =>
      d == 9 ? BoardSize.small9 : BoardSize.standard15;
}

/// Режим игры.
enum GameMode {
  localTwoPlayers, // два игрока на одном устройстве
  vsComputer, // против компьютера
  networkHost, // сетевая игра, мы — хост
  networkClient, // сетевая игра, мы — клиент
}

extension GameModeX on GameMode {
  bool get isNetwork =>
      this == GameMode.networkHost || this == GameMode.networkClient;
  bool get isOffline => !isNetwork;
}

/// Уровень сложности ИИ.
enum Difficulty { easy, medium, hard }

extension DifficultyX on Difficulty {
  String get russianName => switch (this) {
        Difficulty.easy => 'Лёгкий',
        Difficulty.medium => 'Средний',
        Difficulty.hard => 'Сложный',
      };

  String get russianDescription => switch (this) {
        Difficulty.easy => 'ИИ видит только ближайшие угрозы — можно выиграть',
        Difficulty.medium => 'ИИ оценивает паттерны и блокирует атаки',
        Difficulty.hard => 'ИИ просчитывает глубоко и не делает запрещённых ходов',
      };
}

/// Конфигурация партии: правила, размер доски, режим, уровень ИИ, подсказки.
class GameConfig {
  const GameConfig({
    required this.ruleset,
    required this.boardSize,
    required this.mode,
    this.difficulty = Difficulty.easy,
    this.hintsEnabled = true,
    this.patternHighlightEnabled = true,
    this.soundEnabled = true,
    this.humanColor = StoneColor.black,
    this.hostPlayerName = '',
    this.clientPlayerName = '',
  });

  final Ruleset ruleset;
  final BoardSize boardSize;
  final GameMode mode;
  final Difficulty difficulty;
  final bool hintsEnabled;
  final bool patternHighlightEnabled;
  final bool soundEnabled;
  final StoneColor humanColor;
  final String hostPlayerName;
  final String clientPlayerName;

  int get boardDimension => boardSize.dimension;

  GameConfig copyWith({
    Ruleset? ruleset,
    BoardSize? boardSize,
    GameMode? mode,
    Difficulty? difficulty,
    bool? hintsEnabled,
    bool? patternHighlightEnabled,
    bool? soundEnabled,
    StoneColor? humanColor,
    String? hostPlayerName,
    String? clientPlayerName,
  }) =>
      GameConfig(
        ruleset: ruleset ?? this.ruleset,
        boardSize: boardSize ?? this.boardSize,
        mode: mode ?? this.mode,
        difficulty: difficulty ?? this.difficulty,
        hintsEnabled: hintsEnabled ?? this.hintsEnabled,
        patternHighlightEnabled:
            patternHighlightEnabled ?? this.patternHighlightEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        humanColor: humanColor ?? this.humanColor,
        hostPlayerName: hostPlayerName ?? this.hostPlayerName,
        clientPlayerName: clientPlayerName ?? this.clientPlayerName,
      );

  Map<String, dynamic> toJson() => {
        'ruleset': ruleset.name,
        'mode': mode.name,
        'boardSize': boardSize.dimension,
        'difficulty': difficulty.name,
        'hintsEnabled': hintsEnabled,
        'patternHighlightEnabled': patternHighlightEnabled,
        'soundEnabled': soundEnabled,
        'humanColor': humanColor.name,
        'hostPlayerName': hostPlayerName,
        'clientPlayerName': clientPlayerName,
      };

  static GameConfig fromJson(Map<String, dynamic> json) => GameConfig(
        ruleset: Ruleset.values.byName(json['ruleset'] as String),
        boardSize:
            BoardSizeX.fromDimension((json['boardSize'] as num).toInt()),
        mode: GameMode.values.byName((json['mode'] as String?) ?? 'networkHost'),
        difficulty: Difficulty.values.byName(
            (json['difficulty'] as String?) ?? 'easy'),
        hintsEnabled: (json['hintsEnabled'] as bool?) ?? true,
        patternHighlightEnabled:
            (json['patternHighlightEnabled'] as bool?) ?? true,
        soundEnabled: (json['soundEnabled'] as bool?) ?? true,
        humanColor: StoneColor.values.byName(json['humanColor'] as String),
        hostPlayerName: (json['hostPlayerName'] as String?) ?? '',
        clientPlayerName: (json['clientPlayerName'] as String?) ?? '',
      );
}
