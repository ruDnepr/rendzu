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

/// Экран подключения клиента: ввод кода или IP:порт, ожидание старта от хоста.
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
    final ok = await ref.read(networkServiceProvider.notifier).connectByCode(name, code);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _connecting = false;
        _error = 'Не удалось найти игру. Проверь код и что вы в одной Wi-Fi сети.';
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
    final ok =
        await ref.read(networkServiceProvider.notifier).connectAsClient(name, ip, port);
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
          // клиент играет за противоположный цвет от humanColor хоста
          final clientCfg = cfg.copyWith(
            mode: GameMode.networkClient,
            humanColor: cfg.humanColor.opponent,
          );
          ref.read(networkServiceProvider.notifier)
              .setMyColor(clientCfg.humanColor);
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
    // уведомим хост (через lobby-сообщение локально не отправим, т.к. хост
    // инициатор lobby; клиент шлёт готовность через chat-пинг)
    final net = ref.read(networkServiceProvider.notifier);
    net.send(NetworkMessage.lobby(
      hostName: '',
      clientName: ref.read(settingsServiceProvider)?.playerName ?? 'Гость',
      config: _receivedConfig ?? const GameConfig(ruleset: Ruleset.gomoku, boardSize: BoardSize.small9, mode: GameMode.networkClient),
      hostReady: _hostReady,
      clientReady: _clientReady,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final netState = ref.watch(networkServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Присоединиться')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (netState.isConnected && _receivedConfig != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Лобби',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text('Правила: ${_receivedConfig!.ruleset.russianName}'),
                      Text('Доска: ${_receivedConfig!.boardSize.russianName}'),
                      Text('Твой цвет: ${_receivedConfig!.humanColor.opponent.russianName}'),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: Icon(_hostReady ? Icons.check_circle : Icons.circle_outlined,
                            color: _hostReady ? AppColors.grass : AppColors.textLight),
                        title: const Text('Хост готов'),
                      ),
                      ListTile(
                        leading: Icon(_clientReady ? Icons.check_circle : Icons.circle_outlined,
                            color: _clientReady ? AppColors.grass : AppColors.textLight),
                        title: const Text('Ты готов'),
                        onTap: _toggleReady,
                      ),
                      const SizedBox(height: 8),
                      const Text('Жди, когда хост начнёт игру…',
                          style: TextStyle(color: AppColors.textMid)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('По коду',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'ABCDEF',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'Baloo2',
                            fontSize: 24,
                            letterSpacing: 4),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.link),
                        label: const Text('Подключиться по коду'),
                        onPressed: _connecting ? null : _connectByCode,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('По IP:порту (для взрослых)',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _ipCtrl,
                              decoration: const InputDecoration(
                                labelText: 'IP',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _portCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Порт',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sky),
                        icon: const Icon(Icons.wifi),
                        label: const Text('Подключиться по IP'),
                        onPressed: _connecting ? null : _connectByIp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.coralDark)),
            ],
            if (_connecting) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Назад'),
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
}
