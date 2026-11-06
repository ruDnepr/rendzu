import 'package:rendzu/domain/models/point.dart';

/// Игровое поле фиксированного размера size×size.
/// Камни хранятся в плоском списке для скорости; null — пустая точка.
class Board {
  Board(this.size) : _cells = List<StoneColor?>.filled(size * size, null);

  Board.fromCells(this.size, List<StoneColor?> cells)
      : _cells = List<StoneColor?>.of(cells);

  final int size;
  final List<StoneColor?> _cells;

  int _blackCount = 0;
  int _whiteCount = 0;

  bool get isEmpty => _blackCount == 0 && _whiteCount == 0;
  int get stoneCount => _blackCount + _whiteCount;
  int get blackCount => _blackCount;
  int get whiteCount => _whiteCount;
  bool get isFull => stoneCount == size * size;

  int _idx(int x, int y) => y * size + x;
  int _idxPoint(Point p) => p.y * size + p.x;

  StoneColor? get(int x, int y) {
    if (x < 0 || y < 0 || x >= size || y >= size) return null;
    return _cells[_idx(x, y)];
  }

  StoneColor? at(Point p) {
    if (!p.inBounds(size)) return null;
    return _cells[_idxPoint(p)];
  }

  /// Ставит камень без проверок (низкоуровневая операция).
  void place(Point p, StoneColor color) {
    if (!p.inBounds(size)) {
      throw ArgumentError('Point $p out of board $size×$size');
    }
    final i = _idxPoint(p);
    if (_cells[i] != null) {
      throw StateError('Cell $p already occupied');
    }
    _cells[i] = color;
    if (color == StoneColor.black) {
      _blackCount++;
    } else {
      _whiteCount++;
    }
  }

  /// Снимает камень (для отмены хода).
  void remove(Point p) {
    if (!p.inBounds(size)) return;
    final i = _idxPoint(p);
    final prev = _cells[i];
    if (prev == null) return;
    _cells[i] = null;
    if (prev == StoneColor.black) {
      _blackCount--;
    } else {
      _whiteCount--;
    }
  }

  bool isOccupied(Point p) => at(p) != null;
  bool isEmptyCell(Point p) => p.inBounds(size) && at(p) == null;

  /// Список всех занятых точек.
  Iterable<Point> occupiedPoints() sync* {
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (_cells[_idx(x, y)] != null) {
          yield Point(x, y);
        }
      }
    }
  }

  /// Клон доски.
  Board copy() {
    final b = Board(size);
    for (var i = 0; i < _cells.length; i++) {
      b._cells[i] = _cells[i];
    }
    b._blackCount = _blackCount;
    b._whiteCount = _whiteCount;
    return b;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final c = _cells[_idx(x, y)];
        sb.write(c == null ? '.' : (c == StoneColor.black ? 'X' : 'O'));
      }
      sb.writeln();
    }
    return sb.toString();
  }
}
