import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendzu/domain/ai/renju_ai.dart';
import 'package:rendzu/domain/models/game_config.dart';
import 'package:rendzu/domain/models/game_state.dart';
import 'package:rendzu/domain/models/move.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/domain/network/network_message.dart';
import 'package:rendzu/domain/rules/game_rules.dart';
import 'package:rendzu/presentation/providers/core_providers.dart';
import 'package:rendzu/presentation/providers/network_provider.dart';

/// Текущая конфигурация партии (выбирается на экране настройки игры).
final gameConfigProvider = StateProvider<GameConfig?>((ref) => null);

/// Контроллер игры: держит [GameState], обрабатывает ходы, ИИ, звук и сеть.
class GameController extends StateNotifier<GameState?> {
  GameController(this._ref) : super(null);

  final Ref _ref;
  StreamSubscription<NetworkMessage>? _netSub;

  /// Начать новую партию с конфигурацией [config].
  void startGame(GameConfig config) {
    _ref.read(gameConfigProvider.notifier).state = config;
    final rules = rulesFor(config.ruleset);
    var state = GameState(
      config: config.copyWith(
        soundEnabled: _resolveSound(config),
      ),
      rules: rules,
    );
    super.state = state;
    // подписка на сетевые сообщения
    if (config.mode.isNetwork) {
      _subscribeNetwork();
    } else {
      _netSub?.cancel();
      _netSub = null;
      // если первый ход компьютера — он ходит чёрными
      state = _maybeAiMove(state);
      super.state = state;
    }
  }

  void _subscribeNetwork() {
    _netSub?.cancel();
    final net = _ref.read(networkServiceProvider.notifier);
    _netSub = net.messages.listen(_onNetworkMessage);
  }

  void _onNetworkMessage(NetworkMessage m) {
    final s = state;
    if (s == null) return;
    switch (m.type) {
      case MessageType.move:
        final move = m.asMove;
        if (move == null) return;
        // применяем ход удалённого игрока локально
        final result = s.makeMove(move.point);
        if (result.outcome == MoveOutcome.win) {
          _ref.read(audioServiceProvider).playWin();
        } else if (result.outcome == MoveOutcome.normal) {
          _ref.read(audioServiceProvider).playPlace();
        }
        super.state = result.state;
        break;
      case MessageType.forbiddenWarning:
        // хост отклонил наш ход — покажем предупреждение
        super.state = s.copyWith(warning: m.payload['reason'] as String?);
        _ref.read(audioServiceProvider).playForbidden();
        break;
      case MessageType.win:
        // удалённая сторона объявила победу (синхронизация)
        break;
      case MessageType.resign:
        if (!s.gameOver) {
          super.state = s.resign();
          _ref.read(audioServiceProvider).playWin();
        }
        break;
      case MessageType.undoRequest:
        // ответим согласием в офлайн-стиле (упрощённо — принимаем)
        _ref.read(networkServiceProvider.notifier)
            .send(NetworkMessage.undoResponse(accept: true));
        final ns = s.undo();
        if (ns != null) super.state = ns;
        break;
      case MessageType.undoResponse:
        final accept = (m.payload['accept'] as bool?) ?? false;
        if (accept) {
          final ns = s.undo();
          if (ns != null) super.state = ns;
        }
        break;
      case MessageType.ping:
        _ref.read(networkServiceProvider.notifier).send(NetworkMessage.pong());
        break;
      default:
        break;
    }
  }

  bool _resolveSound(GameConfig config) {
    final settings = _ref.read(settingsServiceProvider);
    return settings?.soundEnabled ?? config.soundEnabled;
  }

  /// Совершить ход человека в точку [p].
  void placeStone(Point p) {
    final s = state;
    if (s == null || s.gameOver) return;
    if (!_isHumanTurn(s)) return;

    if (s.config.mode.isNetwork) {
      // Сетевой режим: хост применяет локально и рассылает; клиент отправляет
      // запрос хосту и ждёт подтверждения.
      if (s.config.mode == GameMode.networkHost) {
        final result = s.makeMove(p);
        if (result.outcome == MoveOutcome.forbidden) {
          _ref.read(audioServiceProvider).playForbidden();
          super.state = result.state;
          return;
        }
        _ref.read(audioServiceProvider).playPlace();
        super.state = result.state;
        _ref.read(networkServiceProvider.notifier)
            .send(NetworkMessage.move(Move(
          point: p,
          color: s.currentColor,
          number: s.history.length + 1,
        )));
        if (result.outcome == MoveOutcome.win) {
          _ref.read(audioServiceProvider).playWin();
        }
      } else {
        // клиент: отправляем запрос, хост валидирует и пришлёт move обратно
        _ref.read(networkServiceProvider.notifier)
            .send(NetworkMessage.move(Move(
          point: p,
          color: s.currentColor,
          number: s.history.length + 1,
        )));
      }
      return;
    }

    // Офлайн + компьютер.
    final result = s.makeMove(p);
    if (result.outcome == MoveOutcome.forbidden) {
      _ref.read(audioServiceProvider).playForbidden();
      super.state = result.state;
      return;
    }
    _ref.read(audioServiceProvider).playPlace();
    super.state = _maybeAiMove(result.state);
  }

  /// Отменить последний ход (офлайн). В сети — по согласию.
  void undo() {
    final s = state;
    if (s == null) return;
    if (s.config.mode.isNetwork) {
      // запросить отмену у соперника
      _ref.read(networkServiceProvider.notifier)
          .send(NetworkMessage.undoRequest());
      return;
    }
    if (s.gameOver) return;
    var ns = s.undo();
    if (ns == null) return;
    if (!_isHumanTurn(ns) && _isComputerTurn(ns)) {
      final ns2 = ns.undo();
      if (ns2 != null) ns = ns2;
    }
    super.state = ns;
  }

  /// Сдаться.
  void resign() {
    final s = state;
    if (s == null || s.gameOver) return;
    if (s.config.mode.isNetwork) {
      _ref.read(networkServiceProvider.notifier).send(NetworkMessage.resign());
    }
    super.state = s.resign();
    _ref.read(audioServiceProvider).playWin();
  }

  /// Очистить предупреждение.
  void clearWarning() {
    final s = state;
    if (s == null) return;
    super.state = s.copyWith();
  }

  /// Получить подсказку (точку хорошего хода).
  Point? hint() => state?.hintPoint();

  bool _isHumanTurn(GameState s) {
    final cfg = s.config;
    if (cfg.mode == GameMode.vsComputer) {
      return s.currentColor == cfg.humanColor;
    }
    if (cfg.mode.isNetwork) {
      final net = _ref.read(networkServiceProvider);
      final myColor = net.myColor;
      return myColor == null ? false : s.currentColor == myColor;
    }
    return true;
  }

  bool _isComputerTurn(GameState s) {
    final cfg = s.config;
    if (cfg.mode != GameMode.vsComputer) return false;
    return s.currentColor != cfg.humanColor;
  }

  /// Если сейчас ход компьютера — сделать ход ИИ.
  GameState _maybeAiMove(GameState s) {
    if (s.gameOver) return s;
    if (!_isComputerTurn(s)) return s;
    final cfg = s.config;
    final aiColor = s.currentColor;
    final move = RenjuAI.findBestMove(
      s.board,
      aiColor,
      cfg.difficulty,
      ruleset: cfg.ruleset,
    );
    if (move == null) return s;
    final result = s.makeMove(move);
    _ref.read(audioServiceProvider).playPlace();
    return result.state;
  }

  @override
  void dispose() {
    _netSub?.cancel();
    super.dispose();
  }
}

final gameControllerProvider =
    StateNotifierProvider<GameController, GameState?>((ref) {
  return GameController(ref);
});
