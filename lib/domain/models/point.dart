/// Точка на доске — координаты пересечения линий.
/// (0,0) — левый верхний угол. x — колонка, y — строка.
class Point implements Comparable<Point> {
  const Point(this.x, this.y);

  final int x;
  final int y;

  /// Соседняя точка в направлении [dir] (dx, dy).
  Point step(Direction dir) => Point(x + dir.dx, y + dir.dy);

  /// Все 8 соседних точек.
  Iterable<Point> neighbors() sync* {
    for (final dir in Direction.all) {
      yield step(dir);
    }
  }

  bool inBounds(int size) => x >= 0 && y >= 0 && x < size && y < size;

  @override
  int compareTo(Point other) {
    final r = y.compareTo(other.y);
    return r != 0 ? r : x.compareTo(other.x);
  }

  @override
  bool operator ==(Object other) =>
      other is Point && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}

/// Направление на доске. Каждое направление покрывает одну из 4 линий:
/// горизонталь, вертикаль, диагональ ↘, диагональ ↗.
class Direction {
  const Direction(this.dx, this.dy);

  final int dx;
  final int dy;

  /// 4 оси (по одному направлению из каждой пары).
  static const List<Direction> axes = [
    Direction(1, 0), // горизонталь →
    Direction(0, 1), // вертикаль ↓
    Direction(1, 1), // диагональ ↘
    Direction(1, -1), // диагональ ↗
  ];

  /// Все 8 направлений.
  static final List<Direction> all = [
    ...axes,
    ...axes.map((d) => Direction(-d.dx, -d.dy)),
  ];

  /// Противоположное направление.
  Direction get opposite => Direction(-dx, -dy);

  @override
  String toString() => 'dir($dx,$dy)';
}

/// Цвет камня.
enum StoneColor { black, white }

extension StoneColorX on StoneColor {
  StoneColor get opponent =>
      this == StoneColor.black ? StoneColor.white : StoneColor.black;

  String get russianName =>
      this == StoneColor.black ? 'Чёрные' : 'Белые';
}

/// Игрок: цвет и тип (человек / компьютер).
enum PlayerType { human, computer }

class Player {
  const Player({required this.color, required this.type, this.name = ''});

  final StoneColor color;
  final PlayerType type;
  final String name;

  Player copyWith({String? name, PlayerType? type}) => Player(
        color: color,
        type: type ?? this.type,
        name: name ?? this.name,
      );

  @override
  String toString() => '$name ($color, $type)';
}

/// Результат анализа хода.
enum MoveOutcome { normal, win, forbidden, draw }
