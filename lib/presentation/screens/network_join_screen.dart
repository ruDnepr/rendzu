import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendzu/core/theme/app_theme.dart';
import 'package:rendzu/domain/models/game_config.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/domain/network/connect_code.dart';
import 'package:rendzu/domain/network/network_message.dart';
import 'package:rendzu/presentation/providers/core_providers.dart';
import 'package:rendzu/presentation/providers/game_provider.dart';
import 'package:rendzu/presentation/providers/network_provider.dart';

/// Экран подключения клиента — наследует оформление «Шашек для Дианы».
class NetworkJoinScreen extends ConsumerStatefulWidget {
  const NetworkJoinScreen({super.key});

  @override
  ConsumerState<NetworkJoinScreen> createState() => _NetworkJoinScreenState();
}

class _NetworkJoinScreenState extends ConsumerState<NetworkJoinScreen> {
  final _codeCtrl = TextEditingController();
  final _ipCtrl = TextEditingController(text: '192.168.');
  final _portCtrl = TextEditingController(text: '47395');
  bool _connecting = false;
  String? _error;
  GameConfig? _receivedConfig;
  bool _hostReady = false;
  bool _clientReady = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _ipCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _connectByCode() async {
    final code = ConnectCode.normalize(_codeCtrl.text);
    if (code.length != 6) {
      setState(() => _error = 'Код состоит из 6 символов');
      return;
    }
    setState(() {
      _connecting = true;
      _error = null;
    });
    final name = ref.read(settingsServiceProvider)?.playerName ?? 'Гость';
    final ok = await ref
        .read(networkServiceProvider.notifier)
        .connectByCode(name, code);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _connecting = false;
        _error = 'Не удалось найти игру. Проверь код и общую Wi-Fi сеть.';
      });
      return;
    }
    _afterConnect(name);
  }

  Future<void> _connectByIp() async {
    final ip = _ipCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 0;
    if (ip.isEmpty || port == 0) {
      setState(() => _error = 'Введи IP и порт');
      return;
    }
    setState(() {
      _connecting = true;
      _error = null;
    });
    final name = ref.read(settingsServiceProvider)?.playerName ?? 'Гость';
    final ok = await ref
        .read(networkServiceProvider.notifier)
        .connectAsClient(name, ip, port);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _connecting = false;
        _error = 'Не удалось подключиться. Проверь IP и порт.';
      });
      return;
    }
    _afterConnect(name);
  }

  void _afterConnect(String name) {
    final net = ref.read(networkServiceProvider.notifier);
    net.send(NetworkMessage.hello(name: name));
    net.messages.listen((m) {
      if (!mounted) return;
      switch (m.type) {
        case MessageType.lobby:
          setState(() {
            _receivedConfig = GameConfig.fromJson(
                (m.payload['config'] as Map).cast<String, dynamic>());
            _hostReady = (m.payload['hostReady'] as bool?) ?? false;
            _clientReady = (m.payload['clientReady'] as bool?) ?? false;
          });
          break;
        case MessageType.gameConfig:
          final cfg = GameConfig.fromJson(m.payload);
          final clientCfg = cfg.copyWith(
            mode: GameMode.networkClient,
            humanColor: cfg.humanColor.opponent,
          );
          ref.read(networkServiceProvider.notifier).setMyColor(clientCfg.humanColor);
          ref.read(gameConfigProvider.notifier).state = clientCfg;
          Navigator.of(context).pushReplacementNamed('/game');
          break;
        case MessageType.ping:
          net.send(NetworkMessage.pong());
          break;
        default:
          break;
      }
    });
    setState(() => _connecting = false);
  }

  void _toggleReady() {
    setState(() => _clientReady = !_clientReady);
    final net = ref.read(networkServiceProvider.notifier);
    net.send(NetworkMessage.lobby(
      hostName: '',
      clientName: ref.read(settingsServiceProvider)?.playerName ?? 'Гость',
      config: _receivedConfig ??
          const GameConfig(
              ruleset: Ruleset.gomoku,
              boardSize: BoardSize.small9,
              mode: GameMode.networkClient),
      hostReady: _hostReady,
      clientReady: _clientReady,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final netState = ref.watch(networkServiceProvider);
    return PageFrame(
      title: 'Присоединиться',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          if (netState.isConnected && _receivedConfig != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.92),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF2EAE3)),
                boxShadow: [
                  BoxShadow(
                    color: ink.withOpacity(.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Лобби',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: ink)),
                  const SizedBox(height: 8),
                  Text('Правила: ${_receivedConfig!.ruleset.russianName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: muted)),
                  Text('Доска: ${_receivedConfig!.boardSize.russianName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: muted)),
                  Text(
                      'Твой цвет: ${_receivedConfig!.humanColor.opponent.russianName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: muted)),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: Icon(
                        _hostReady ? Icons.check_circle_rounded : Icons.circle_outlined,
                        color: _hostReady ? purple : muted),
                    title: const Text('Хост готов',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, color: ink)),
                  ),
                  ListTile(
                    leading: Icon(
                        _clientReady ? Icons.check_circle_rounded : Icons.circle_outlined,
                        color: _clientReady ? purple : muted),
                    title: const Text('Ты готов',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, color: ink)),
                    onTap: _toggleReady,
                  ),
                  const SizedBox(height: 8),
                  const Text('Жди, когда хост начнёт игру…',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: muted)),
                ],
              ),
            ),
          ] else ...[
            const Intro(
                eyebrow: 'ПО КОДУ ✦',
                title: 'Введи код',
                subtitle: 'Шесть символов от хоста — без 0/O/1/I.'),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE3D8F5)),
                ),
                hintText: 'ABCDEF',
                counterText: '',
              ),
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: ink),
            ),
            const SizedBox(height: 12),
            BigButton(
              title: 'Подключиться по коду',
              icon: Icons.link_rounded,
              onPressed: _connecting ? null : _connectByCode,
            ),
            const SizedBox(height: 20),
            const Intro(
                eyebrow: 'ДЛЯ ВЗРОСЛЫХ ✦',
                title: 'По IP:порту',
                subtitle: 'Если код не находится — введи IP и порт хоста.'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _ipCtrl,
                    decoration: InputDecoration(
                      labelText: 'IP',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFE3D8F5)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _portCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Порт',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFE3D8F5)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BigButton(
              title: 'Подключиться по IP',
              icon: Icons.wifi_rounded,
              color: const Color(0xFF6047AF),
              onPressed: _connecting ? null : _connectByIp,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(
                    color: Color(0xFFE27D60), fontWeight: FontWeight.w800)),
          ],
          if (_connecting) ...[
            const SizedBox(height: 16),
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(purple.withOpacity(.6)),
              ),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: ink,
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE3D8F5)),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Назад',
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
}
