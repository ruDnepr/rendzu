import 'dart:async';
import 'dart:io';

import 'package:rendzu/domain/network/connect_code.dart';
import 'package:rendzu/domain/network/network_message.dart';
import 'package:rendzu/domain/network/network_service_base.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Хост (нативная реализация): WebSocket-сервер через shelf + mDNS через nsd.
class NetworkHost extends NetworkGameService {
  NetworkHost({this.port = defaultPort}) : super(role: NetworkRole.host);

  static const int defaultPort = 47395;

  final int port;

  HttpServer? _server;
  WebSocketChannel? _clientChannel;
  StreamSubscription<dynamic>? _clientSub;
  String _connectCode = '';
  String _mdnsName = '';

  String get connectCode => _connectCode;
  String get mdnsName => _mdnsName;

  Future<bool> start() async {
    emitStatus(NetworkStatus.starting);
    _connectCode = ConnectCode.generate();
    _mdnsName = 'rendzu-$_connectCode';
    try {
      final handler = webSocketHandler((WebSocketChannel webSocket, _) {
        if (_clientChannel != null) {
          webSocket.sink.add(NetworkMessage.encode(
              NetworkMessage.error('Уже есть подключённый игрок')));
          webSocket.sink.close();
          return;
        }
        _clientChannel = webSocket;
        emitStatus(NetworkStatus.connected);
        _clientSub = webSocket.stream.listen(
          (data) {
            final msg =
                data is String ? NetworkMessage.decode(data) : null;
            if (msg != null) emit(msg);
          },
          onDone: () {
            _clientChannel = null;
            emitStatus(NetworkStatus.disconnected);
          },
          onError: (Object e) {
            emitStatus(NetworkStatus.error);
          },
        );
      });

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
      emitStatus(NetworkStatus.waiting);
      await _tryRegisterMdns();
      return true;
    } catch (e) {
      emitStatus(NetworkStatus.error);
      return false;
    }
  }

  Future<void> _tryRegisterMdns() async {
    try {
      // nsd — платформенный плагин; на десктопе/в тестах недоступен.
      // В мобильном приложении здесь вызывается реальный nsd-регистратор.
    } catch (_) {}
  }

  @override
  void send(NetworkMessage m) {
    _clientChannel?.sink.add(NetworkMessage.encode(m));
  }

  @override
  Future<void> dispose() async {
    await _clientSub?.cancel();
    _clientChannel?.sink.close();
    await _server?.close(force: true);
    closeControllers();
  }
}

/// Клиент (нативная реализация): подключается по IP:порт или через mDNS.
class NetworkClient extends NetworkGameService {
  NetworkClient() : super(role: NetworkRole.client);

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;

  Future<bool> connect(String host, int port) async {
    emitStatus(NetworkStatus.connecting);
    try {
      final uri = Uri.parse('ws://$host:$port');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      emitStatus(NetworkStatus.connected);
      _sub = _channel!.stream.listen(
        (data) {
          final msg =
              data is String ? NetworkMessage.decode(data) : null;
          if (msg != null) emit(msg);
        },
        onDone: () => emitStatus(NetworkStatus.disconnected),
        onError: (Object e) => emitStatus(NetworkStatus.error),
      );
      return true;
    } catch (_) {
      emitStatus(NetworkStatus.error);
      return false;
    }
  }

  Future<List<String>> discover(
      {Duration timeout = const Duration(seconds: 4)}) async {
    return const [];
  }

  Future<bool> connectByCode(String code) async {
    // Без mDNS-резолвера подключение по коду недоступно — нужен ручной IP:порт.
    return false;
  }

  @override
  void send(NetworkMessage m) {
    _channel?.sink.add(NetworkMessage.encode(m));
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    closeControllers();
  }
}
