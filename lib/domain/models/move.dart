import 'package:rendzu/domain/models/point.dart';

/// Один ход игры: игрок ставит камень [color] в точку [point].
class Move {
  const Move({required this.point, required this.color, this.number = 0});

  final Point point;
  final StoneColor color;
  final int number;

  Move copyWith({int? number}) =>
      Move(point: point, color: color, number: number ?? this.number);

  Map<String, dynamic> toJson() => {
        'point': {'x': point.x, 'y': point.y},
        'color': color.name,
        'number': number,
      };

  static Move fromJson(Map<String, dynamic> json) {
    final p = json['point'] as Map<String, dynamic>;
    return Move(
      point: Point(p['x'] as int, p['y'] as int),
      color: StoneColor.values.byName(json['color'] as String),
      number: (json['number'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() => '#$number $color→$point';
}
