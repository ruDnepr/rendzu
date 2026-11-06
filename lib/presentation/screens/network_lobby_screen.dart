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

/// Экран лобби хоста — наследует оформление «Шашек для Дианы».
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
    return PageFrame(
      title: 'Создать игру',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: yellow.withOpacity(.18),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                const Text('Код подключения',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: muted)),
                const SizedBox(height: 8),
                Text(
                  netState.connectCode.isEmpty
                      ? '••••••'
                      : _formatCode(netState.connectCode),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  netState.status == NetworkStatus.waiting
                      ? 'Ждём друга в одной Wi-Fi сети…'
                      : netState.status == NetworkStatus.connected
                          ? 'Друг подключился! 🎉'
                          : 'Запуск сервера…',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                  })),
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
                  })),
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
                  })),
          const SizedBox(height: 12),
          ListTile(
            leading: Icon(
                _hostReady ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: _hostReady ? purple : muted,
                size: 30),
            title: const Text('Ты готов',
                style: TextStyle(fontWeight: FontWeight.w900, color: ink)),
            onTap: () {
              setState(() => _hostReady = !_hostReady);
              _broadcastLobby();
            },
          ),
          ListTile(
            leading: Icon(
                _clientReady ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: _clientReady ? purple : muted,
                size: 30),
            title: Text(
                '${_clientName.isEmpty ? "Гость" : _clientName} готов',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: ink)),
          ),
          const SizedBox(height: 16),
          BigButton(
            title: 'Начать игру',
            icon: Icons.play_arrow_rounded,
            onPressed: (_hostReady && _clientReady) ? _start : null,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: ink,
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE3D8F5)),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Выйти',
                style: TextStyle(fontWeight: FontWeight.w900)),
            onPressed: () async {
              await ref.read(networkServiceProvider.notifier).disposeService();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ],
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
            child: Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w900, color: ink)),
          ),
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Text(value,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w900, color: deepPurple)),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}
