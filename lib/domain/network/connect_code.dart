import 'dart:math';

/// Генерация короткого кода подключения (6 символов) без похожих знаков:
/// без `0/O`, `1/I/l`. Используется для удобного ввода на детском экране.
class ConnectCode {
  ConnectCode._();

  static const _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static String generate([int length = 6]) {
    final rnd = Random();
    final sb = StringBuffer();
    for (var i = 0; i < length; i++) {
      sb.write(_alphabet[rnd.nextInt(_alphabet.length)]);
    }
    return sb.toString();
  }

  /// Проверка валидности введённого кода.
  static bool isValid(String code) {
    if (code.length != 6) return false;
    for (final c in code.split('')) {
      if (!_alphabet.contains(c)) return false;
    }
    return true;
  }

  /// Нормализация введённого кода (верхний регистр).
  static String normalize(String code) {
    return code.toUpperCase().replaceAll(RegExp(r'[^A-Z2-9]'), '');
  }
}
