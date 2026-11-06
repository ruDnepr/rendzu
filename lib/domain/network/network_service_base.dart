import 'dart:async';

import 'package:rendzu/domain/network/network_message.dart';

/// Состояние сетевой игры.
enum NetworkRole { host, client }

/// Статус соединения.
enum NetworkStatus {
  starting, // запускаем сервер / ищем игру
  waiting, // ожидаем подключения клиента (хост)
  connecting, // подключаемся (клиент)
  connected, // соединение установлено
  disconnected, // связь потеряна
  error,
}

/// Найденная mDNS-служба.
class DiscoveredService {
  const DiscoveredService(this.host, this.port);
  final String host;
  final int port;
}

/// Базовый абстрактный сетевой сервис: хост или клиент.
///
/// Конкретные реализации — [NetworkHost] и [NetworkClient], доступны через
/// условный экспорт (dart:io — нативная реализация, web — заглушка).
abstract class NetworkGameService {
  NetworkGameService({required this.role});

  final NetworkRole role;

  final _incoming = StreamController<NetworkMessage>.broadcast();
  Stream<NetworkMessage> get incoming => _incoming.stream;

  final _status = StreamController<NetworkStatus>.broadcast();
  Stream<NetworkStatus> get status => _status.stream;

  void send(NetworkMessage m);
  Future<void> dispose();

  void emit(NetworkMessage m) {
    if (!_incoming.isClosed) _incoming.add(m);
  }

  void emitStatus(NetworkStatus s) {
    if (!_status.isClosed) _status.add(s);
  }

  void closeControllers() {
    _incoming.close();
    _status.close();
  }
}
