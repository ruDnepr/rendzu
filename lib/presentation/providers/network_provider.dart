import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/domain/network/network_message.dart';
import 'package:rendzu/domain/network/network_service.dart';

/// Сетевой провайдер: оборачивает [NetworkGameService] и предоставляет поток
/// сообщений и статус соединения. Также хранит «мой цвет» и имя.
class NetworkController extends StateNotifier<NetworkState> {
  NetworkController() : super(const NetworkState.initial());

  NetworkGameService? _service;
  StreamSubscription<NetworkMessage>? _msgSub;
  StreamSubscription<NetworkStatus>? _statusSub;
  final _messages = StreamController<NetworkMessage>.broadcast();
  Stream<NetworkMessage> get messages => _messages.stream;

  NetworkGameService? get service => _service;
  StoneColor? get myColor => state.myColor;
  String get myName => state.myName;

  /// Стать хостом.
  Future<void> becomeHost(String name) async {
    final host = NetworkHost();
    _service = host;
    state = NetworkState(
      role: NetworkRole.host,
      status: NetworkStatus.starting,
      connectCode: '',
      myName: name,
    );
    _msgSub = host.incoming.listen(_messages.add);
    _statusSub = host.status.listen((s) {
      state = state.copyWith(status: s, connectCode: host.connectCode);
    });
    await host.start();
    state = state.copyWith(connectCode: host.connectCode);
  }

  /// Стать клиентом и подключиться по IP:порт.
  Future<bool> connectAsClient(String name, String host, int port) async {
    final client = NetworkClient();
    _service = client;
    state = NetworkState(
      role: NetworkRole.client,
      status: NetworkStatus.connecting,
      myName: name,
    );
    _msgSub = client.incoming.listen(_messages.add);
    _statusSub = client.status
        .listen((s) => state = state.copyWith(status: s));
    return client.connect(host, port);
  }

  /// Подключиться по коду.
  Future<bool> connectByCode(String name, String code) async {
    final client = NetworkClient();
    _service = client;
    state = NetworkState(
      role: NetworkRole.client,
      status: NetworkStatus.connecting,
      myName: name,
    );
    _msgSub = client.incoming.listen(_messages.add);
    _statusSub = client.status
        .listen((s) => state = state.copyWith(status: s));
    return client.connectByCode(code);
  }

  void setMyColor(StoneColor c) => state = state.copyWith(myColor: c);

  void send(NetworkMessage m) => _service?.send(m);

  Future<void> disposeService() async {
    await _msgSub?.cancel();
    await _statusSub?.cancel();
    await _messages.close();
    await _service?.dispose();
    _service = null;
    state = const NetworkState.initial();
  }

  @override
  void dispose() {
    disposeService();
    super.dispose();
  }
}

/// Состояние сетевого режима.
class NetworkState {
  const NetworkState({
    this.role,
    required this.status,
    this.connectCode = '',
    this.myColor,
    this.myName = '',
  });

  const NetworkState.initial()
      : role = null,
        status = NetworkStatus.disconnected,
        connectCode = '',
        myColor = null,
        myName = '';

  final NetworkRole? role;
  final NetworkStatus status;
  final String connectCode;
  final StoneColor? myColor;
  final String myName;

  bool get isHost => role == NetworkRole.host;
  bool get isConnected => status == NetworkStatus.connected;

  NetworkState copyWith({
    NetworkRole? role,
    NetworkStatus? status,
    String? connectCode,
    StoneColor? myColor,
    String? myName,
  }) =>
      NetworkState(
        role: role ?? this.role,
        status: status ?? this.status,
        connectCode: connectCode ?? this.connectCode,
        myColor: myColor ?? this.myColor,
        myName: myName ?? this.myName,
      );
}

final networkServiceProvider =
    StateNotifierProvider<NetworkController, NetworkState>((ref) {
  final c = NetworkController();
  ref.onDispose(c.disposeService);
  return c;
});
