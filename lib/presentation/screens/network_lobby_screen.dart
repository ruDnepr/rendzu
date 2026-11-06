import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendzu/core/theme/app_theme.dart';
import 'package:rendzu/domain/models/game_config.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/domain/network/network_message.dart';
import 'package:rendzu/domain/network/network_service.dart';
import 'package:rendzu/presentation/providers/core_providers.dart';
import 'package:rendzu/presentation/providers/game_provider.dart';
import 'package:rendzu/presentation/providers/network_provider.dart';

/// Экран лобби хоста: показывает код подключения, позволяет выбрать правила и
/// размер доски, назначить цвета, готовность. При готовности обеих сторон —
/// старт игры.
class NetworkLobbyScreen extends ConsumerStatefulWidget {
  const NetworkLobbyScreen({super.key});

  @override
  ConsumerState<NetworkLobbyScreen> createState() => _NetworkLobbyScreenState();
}

class _NetworkLobbyScreenState extends ConsumerState<NetworkLobbyScreen> {
  Ruleset _ruleset = Ruleset.gomoku;
  BoardSize _boardSize = BoardSize.small9;
  bool _hostReady = false;
  bool _clientReady = false;
  String _clientName = '';
  bool _hostIsBlack = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = ref.read(settingsServiceProvider);
      final name = settings?.playerName ?? 'Хост';
      await ref.read(networkServiceProvider.notifier).becomeHost(name);
      // слушаем входящие сообщения
      _listenMessages();
    });
  }

  void _listenMessages() {
    final net = ref.read(networkServiceProvider.notifier);
    net.messages.listen((m) {
      if (!mounted) return;
      switch (m.type) {
        case MessageType.hello:
          setState(() => _clientName = m.stringName ?? 'Гость');
          _broadcastLobby();
          break;
        case MessageType.undoResponse:
          break;
        case MessageType.ping:
          net.send(NetworkMessage.pong());
          break;
        default:
          break;
      }
    });
  }

  void _broadcastLobby() {
    final net = ref.read(networkServiceProvider.notifier);
    final name = ref.read(settingsServiceProvider)?.playerName ?? 'Хост';
    final cfg = GameConfig(
      ruleset: _ruleset,
      boardSize: _boardSize,
      mode: GameMode.networkHost,
      humanColor: _hostIsBlack ? StoneColor.black : StoneColor.white,
      hostPlayerName: name,
      clientPlayerName: _clientName,
    );
    net.send(NetworkMessage.lobby(
      hostName: name,
      clientName: _clientName,
      config: cfg,
      hostReady: _hostReady,
      clientReady: _clientReady,
    ));
  }

  void _start() {
    if (!_hostReady || !_clientReady) return;
    final net = ref.read(networkServiceProvider.notifier);
    net.setMyColor(_hostIsBlack ? StoneColor.black : StoneColor.white);
    final name = ref.read(settingsServiceProvider)?.playerName ?? 'Хост';
    final cfg = GameConfig(
      ruleset: _ruleset,
      boardSize: _boardSize,
      mode: GameMode.networkHost,
      humanColor: _hostIsBlack ? StoneColor.black : StoneColor.white,
      hostPlayerName: name,
      clientPlayerName: _clientName,
    );
    net.send(NetworkMessage.gameConfig(cfg));
    ref.read(gameConfigProvider.notifier).state = cfg;
    Navigator.of(context).pushReplacementNamed('/game');
  }

  @override
  Widget build(BuildContext context) {
    final netState = ref.watch(networkServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Создать игру')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppColors.sunflower.withOpacity(0.18),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Код подключения',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      netState.connectCode.isEmpty
                          ? '••••••'
                          : _formatCode(netState.connectCode),
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        color: AppColors.coralDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      netState.status == NetworkStatus.waiting
                          ? 'Ждём друга в одной Wi-Fi сети…'
                          : netState.status == NetworkStatus.connected
                              ? 'Друг подключился! 🎉'
                              : 'Запуск сервера…',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Правила и доска', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            _PickerRow(
              label: 'Набор правил',
              value: _ruleset.russianName,
              onPrev: () => setState(() {
                _ruleset = _ruleset == Ruleset.gomoku
                    ? Ruleset.renju
                    : Ruleset.gomoku;
                _broadcastLobby();
              }),
              onNext: () => setState(() {
                _ruleset = _ruleset == Ruleset.gomoku
                    ? Ruleset.renju
                    : Ruleset.gomoku;
                _broadcastLobby();
              }),
            ),
            _PickerRow(
              label: 'Размер доски',
              value: _boardSize.russianName,
              onPrev: () => setState(() {
                _boardSize = _boardSize == BoardSize.small9
                    ? BoardSize.standard15
                    : BoardSize.small9;
                _broadcastLobby();
              }),
              onNext: () => setState(() {
                _boardSize = _boardSize == BoardSize.small9
                    ? BoardSize.standard15
                    : BoardSize.small9;
                _broadcastLobby();
              }),
            ),
            _PickerRow(
              label: 'Твой цвет',
              value: _hostIsBlack ? 'Чёрные (ходишь первым)' : 'Белые',
              onPrev: () => setState(() {
                _hostIsBlack = !_hostIsBlack;
                _broadcastLobby();
              }),
              onNext: () => setState(() {
                _hostIsBlack = !_hostIsBlack;
                _broadcastLobby();
              }),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(_hostReady ? Icons.check_circle : Icons.circle_outlined,
                  color: _hostReady ? AppColors.grass : AppColors.textLight, size: 32),
              title: const Text('Ты готов'),
              onTap: () {
                setState(() => _hostReady = !_hostReady);
                _broadcastLobby();
              },
            ),
            ListTile(
              leading: Icon(
                  _clientReady ? Icons.check_circle : Icons.circle_outlined,
                  color: _clientReady ? AppColors.grass : AppColors.textLight,
                  size: 32),
              title: Text('${_clientName.isEmpty ? "Гость" : _clientName} готов'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Начать игру'),
              onPressed: (_hostReady && _clientReady)
                  ? _start
                  : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Выйти'),
              onPressed: () async {
                await ref.read(networkServiceProvider.notifier).disposeService();
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatCode(String code) {
    final buf = StringBuffer();
    for (var i = 0; i < code.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write(' ');
      buf.write(code[i]);
    }
    return buf.toString();
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.value,
    required this.onPrev,
    required this.onNext,
  });
  final String label;
  final String value;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Baloo2', fontWeight: FontWeight.w700)),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}
