import 'package:rendzu/domain/network/network_message.dart';
import 'package:rendzu/domain/network/network_service_base.dart';

/// Web-заглушка хоста: сетевая игра через WebSocket-сервер недоступна в браузере.
/// На web используется только клиентское WebSocket-подключение (см. [NetworkClient]).
class NetworkHost extends NetworkGameService {
  NetworkHost({this.port = defaultPort}) : super(role: NetworkRole.host);

  static const int defaultPort = 47395;
  final int port;

  String get connectCode => '';
  String get mdnsName => '';

  Future<bool> start() async {
    emitStatus(NetworkStatus.error);
    return false;
  }

  @override
  void send(NetworkMessage m) {}

  @override
  Future<void> dispose() async {
    closeControllers();
  }
}

/// Web-клиент: использует браузерное WebSocket API.
class NetworkClient extends NetworkGameService {
  NetworkClient() : super(role: NetworkRole.client);

  Future<bool> connect(String host, int port) async {
    emitStatus(NetworkStatus.error);
    return false;
  }

  Future<List<String>> discover(
      {Duration timeout = const Duration(seconds: 4)}) async {
    return const [];
  }

  Future<bool> connectByCode(String code) async => false;

  @override
  void send(NetworkMessage m) {}

  @override
  Future<void> dispose() async {
    closeControllers();
  }
}
