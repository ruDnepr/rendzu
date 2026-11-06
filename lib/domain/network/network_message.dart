import 'dart:convert';

import 'package:rendzu/domain/models/game_config.dart';
import 'package:rendzu/domain/models/move.dart';
import 'package:rendzu/domain/models/point.dart';

/// Типы сообщений сетевого протокола.
enum MessageType {
  hello, // представление клиента хосту
  lobby, // состояние лобби (хост → клиент)
  gameConfig, // финальная конфигурация партии (хост → клиент)
  move, // ход
  forbiddenWarning, // отклонён запрещённый ход
  win, // победа
  undoRequest, // запрос отмены хода
  undoResponse, // ответ на запрос отмены (accept/reject)
  resign, // сдача
  ping, // проверка связи
  pong, // ответ на ping
  chat, // простое сообщение (опционально)
  error, // ошибка
}

extension MessageTypeX on MessageType {
  String get wire => name;
  static MessageType fromWire(String s) => MessageType.values.byName(s);
}

/// Сообщение сетевого протокола. Сериализуется в JSON.
class NetworkMessage {
  const NetworkMessage({required this.type, this.payload = const {}});

  final MessageType type;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'type': type.wire,
        'payload': payload,
      };

  static NetworkMessage fromJson(Map<String, dynamic> json) {
    final t = MessageTypeX.fromWire(json['type'] as String);
    final p = (json['payload'] as Map<String, dynamic>?) ?? const {};
    return NetworkMessage(type: t, payload: Map<String, dynamic>.from(p));
  }

  /// Кодирует сообщение в JSON-строку.
  static String encode(NetworkMessage m) => jsonEncode(m.toJson());

  /// Декодирует строку в сообщение или null при ошибке.
  static NetworkMessage? decode(String s) {
    try {
      final j = jsonDecode(s) as Map<String, dynamic>;
      return NetworkMessage.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  // ---- удобные конструкторы ----

  static NetworkMessage hello({required String name}) =>
      NetworkMessage(type: MessageType.hello, payload: {'name': name});

  static NetworkMessage lobby({
    required String hostName,
    required String clientName,
    required GameConfig config,
    required bool hostReady,
    required bool clientReady,
  }) =>
      NetworkMessage(
        type: MessageType.lobby,
        payload: {
          'hostName': hostName,
          'clientName': clientName,
          'config': config.toJson(),
          'hostReady': hostReady,
          'clientReady': clientReady,
        },
      );

  static NetworkMessage gameConfig(GameConfig config) =>
      NetworkMessage(type: MessageType.gameConfig, payload: config.toJson());

  static NetworkMessage move(Move m) =>
      NetworkMessage(type: MessageType.move, payload: m.toJson());

  static NetworkMessage forbiddenWarning({required String reason}) =>
      NetworkMessage(
          type: MessageType.forbiddenWarning, payload: {'reason': reason});

  static NetworkMessage win({required String winner, List<Point>? line}) =>
      NetworkMessage(
        type: MessageType.win,
        payload: {
          'winner': winner,
          'line': line?.map((p) => {'x': p.x, 'y': p.y}).toList() ?? const [],
        },
      );

  static NetworkMessage undoRequest() =>
      const NetworkMessage(type: MessageType.undoRequest);

  static NetworkMessage undoResponse({required bool accept}) =>
      NetworkMessage(
          type: MessageType.undoResponse, payload: {'accept': accept});

  static NetworkMessage resign() =>
      const NetworkMessage(type: MessageType.resign);

  static NetworkMessage ping() => const NetworkMessage(type: MessageType.ping);

  static NetworkMessage pong() => const NetworkMessage(type: MessageType.pong);

  static NetworkMessage error(String message) =>
      NetworkMessage(type: MessageType.error, payload: {'message': message});

  // ---- удобные геттеры payload ----

  String? get stringName => payload['name'] as String?;
  bool get boolReady =>
      (payload['hostReady'] as bool?) ?? (payload['accept'] as bool?) ?? false;

  Move? get asMove {
    if (type != MessageType.move) return null;
    return Move.fromJson(payload);
  }

  @override
  String toString() => 'NetworkMessage($type, $payload)';
}
