import 'package:flutter_test/flutter_test.dart';
import 'package:rendzu/domain/models/game_config.dart';
import 'package:rendzu/domain/models/move.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/domain/network/connect_code.dart';
import 'package:rendzu/domain/network/network_message.dart';

void main() {
  group('ConnectCode', () {
    test('генерирует код из 6 символов', () {
      final code = ConnectCode.generate();
      expect(code.length, 6);
    });

    test('не содержит похожих символов (0/O/1/I/l)', () {
      for (var i = 0; i < 50; i++) {
        final code = ConnectCode.generate();
        expect(code.contains('0'), isFalse);
        expect(code.contains('O'), isFalse);
        expect(code.contains('1'), isFalse);
        expect(code.contains('I'), isFalse);
        expect(code.contains('l'), isFalse);
      }
    });

    test('isValid работает', () {
      expect(ConnectCode.isValid('ABCDEF'), isTrue);
      expect(ConnectCode.isValid('ABCDE'), isFalse);
      expect(ConnectCode.isValid('ABCDEF1'), isFalse);
    });

    test('normalize приводит к верхнему регистру и фильтрует', () {
      expect(ConnectCode.normalize('abc-def'), 'ABCDEF');
      expect(ConnectCode.normalize(' a b c d e f '), 'ABCDEF');
    });
  });

  group('NetworkMessage — сериализация', () {
    test('hello → JSON → hello', () {
      final m = NetworkMessage.hello(name: 'Диана');
      final s = NetworkMessage.encode(m);
      final m2 = NetworkMessage.decode(s);
      expect(m2, isNotNull);
      expect(m2!.type, MessageType.hello);
      expect(m2.stringName, 'Диана');
    });

    test('move → JSON → move', () {
      final m = NetworkMessage.move(const Move(
          point: Point(3, 4), color: StoneColor.black, number: 7));
      final s = NetworkMessage.encode(m);
      final m2 = NetworkMessage.decode(s);
      expect(m2, isNotNull);
      expect(m2!.type, MessageType.move);
      final move = m2.asMove;
      expect(move, isNotNull);
      expect(move!.point, const Point(3, 4));
      expect(move.color, StoneColor.black);
      expect(move.number, 7);
    });

    test('lobby с конфигом — round-trip', () {
      final cfg = GameConfig(
        ruleset: Ruleset.renju,
        boardSize: BoardSize.standard15,
        mode: GameMode.networkHost,
        difficulty: Difficulty.hard,
        hintsEnabled: false,
        humanColor: StoneColor.white,
        hostPlayerName: 'Хост',
        clientPlayerName: 'Гость',
      );
      final m = NetworkMessage.lobby(
        hostName: 'Хост',
        clientName: 'Гость',
        config: cfg,
        hostReady: true,
        clientReady: false,
      );
      final m2 = NetworkMessage.decode(NetworkMessage.encode(m));
      expect(m2, isNotNull);
      final cfg2 = GameConfig.fromJson(
          (m2!.payload['config'] as Map).cast<String, dynamic>());
      expect(cfg2.ruleset, Ruleset.renju);
      expect(cfg2.boardSize, BoardSize.standard15);
      expect(cfg2.difficulty, Difficulty.hard);
      expect(cfg2.hintsEnabled, isFalse);
      expect(cfg2.humanColor, StoneColor.white);
      expect(cfg2.hostPlayerName, 'Хост');
    });

    test('gameConfig — round-trip', () {
      final cfg = GameConfig(
        ruleset: Ruleset.gomoku,
        boardSize: BoardSize.small9,
        mode: GameMode.networkHost,
        humanColor: StoneColor.black,
      );
      final m = NetworkMessage.gameConfig(cfg);
      final m2 = NetworkMessage.decode(NetworkMessage.encode(m));
      expect(m2, isNotNull);
      expect(m2!.type, MessageType.gameConfig);
      final cfg2 = GameConfig.fromJson(m2.payload);
      expect(cfg2.ruleset, Ruleset.gomoku);
      expect(cfg2.boardSize, BoardSize.small9);
    });

    test('forbiddenWarning — round-trip', () {
      final m = NetworkMessage.forbiddenWarning(reason: 'Двойное три!');
      final m2 = NetworkMessage.decode(NetworkMessage.encode(m));
      expect(m2, isNotNull);
      expect(m2!.type, MessageType.forbiddenWarning);
      expect(m2.payload['reason'], 'Двойное три!');
    });

    test('undoRequest / undoResponse', () {
      final req = NetworkMessage.undoRequest();
      final req2 = NetworkMessage.decode(NetworkMessage.encode(req));
      expect(req2!.type, MessageType.undoRequest);

      final resp = NetworkMessage.undoResponse(accept: true);
      final resp2 = NetworkMessage.decode(NetworkMessage.encode(resp));
      expect(resp2!.type, MessageType.undoResponse);
      expect(resp2.payload['accept'], isTrue);
    });

    test('ping / pong', () {
      expect(NetworkMessage.decode(NetworkMessage.encode(NetworkMessage.ping()))!.type,
          MessageType.ping);
      expect(NetworkMessage.decode(NetworkMessage.encode(NetworkMessage.pong()))!.type,
          MessageType.pong);
    });

    test('невалидный JSON → null', () {
      expect(NetworkMessage.decode('not json'), isNull);
      expect(NetworkMessage.decode('{"type":"unknown","payload":{}}'), isNull);
    });
  });
}
