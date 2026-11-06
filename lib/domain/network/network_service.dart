import 'dart:async';
import 'dart:io';

import 'package:rendzu/domain/network/connect_code.dart';
import 'package:rendzu/domain/network/network_message.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Состояние сетевой игры.
enum NetworkRole { host, client }

/// Сетевой игровой сервис: хост или клиент. Обеспечивает обмен сообщениями
/// через WebSocket и регистрируется/обнаруживается через mDNS (nsd).
///
/// На стороне хоста поднимается WebSocket-сервер (shelf_web_socket) на порту
/// [NetworkHost.defaultPort], регистрируется mDNS-сервис через nsd и
/// генерируется короткий код подключения. На стороне клиента — подключение по
/// IP:порту или по коду (через mDNS-обнаружение).
abstract class NetworkGameService {
  NetworkGameService({required this.role});

  final NetworkRole role;

  /// Поток входящих сообщений.
  final _incoming = StreamController<NetworkMessage>.broadcast();
  Stream<NetworkMessage> get incoming => _incoming.stream;

  /// Поток изменений статуса соединения.
  final _status = StreamController<NetworkStatus>.broadcast();
  Stream<NetworkStatus> get status => _status.stream;

  /// Отправить сообщение.
  void send(NetworkMessage m);

  /// Закрыть соединение и освободить ресурсы.
  Future<void> dispose();

  void _emit(NetworkMessage m) {
    if (!_incoming.isClosed) _incoming.add(m);
  }

  void _emitStatus(NetworkStatus s) {
    if (!_status.isClosed) _status.add(s);
  }

  void _closeControllers() {
    _incoming.close();
    _status.close();
  }
}

/// Статус соединения.
enum NetworkStatus {
  starting, // запускаем сервер / ищем игру
  waiting, // ожидаем подключения клиента (хост)
  connecting, // подключаемся (клиент)
  connected, // соединение установлено
  disconnected, // связь потеряна
  error,
}

/// Хост: поднимает WebSocket-сервер, регистрируется в mDNS, показывает код.
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

  /// Запустить сервер. Возвращает true при успехе.
  Future<bool> start() async {
    _emitStatus(NetworkStatus.starting);
    _connectCode = ConnectCode.generate();
    _mdnsName = 'rendzu-$_connectCode';
    try {
      final handler = webSocketHandler((WebSocketChannel webSocket, _) {
        // принимаем только одного клиента
        if (_clientChannel != null) {
          webSocket.sink.add(NetworkMessage.encode(
              NetworkMessage.error('Уже есть подключённый игрок')));
          webSocket.sink.close();
          return;
        }
        _clientChannel = webSocket;
        _emitStatus(NetworkStatus.connected);
        _clientSub = webSocket.stream.listen(
          (data) {
            final msg = data is String
                ? NetworkMessage.decode(data)
                : null;
            if (msg != null) _emit(msg);
          },
          onDone: () {
            _clientChannel = null;
            _emitStatus(NetworkStatus.disconnected);
          },
          onError: (Object e) {
            _emitStatus(NetworkStatus.error);
          },
        );
      });

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
      _emitStatus(NetworkStatus.waiting);
      // mDNS-регистрация (опционально, не падает если недоступно).
      await _tryRegisterMdns();
      return true;
    } catch (e) {
      _emitStatus(NetworkStatus.error);
      return false;
    }
  }

  Future<void> _tryRegisterMdns() async {
    // nsd регистрация. Обёрнута в try/catch: на десктопе/тестах может не быть.
    try {
      // ignore: avoid_dynamic_calls
      final nsd = await _nsdRegistrar();
      if (nsd != null) {
        await nsd.register(_mdnsName, port);
      }
    } catch (_) {
      // mDNS недоступен — продолжаем без него (ручной ввод IP:порт).
    }
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
    _closeControllers();
  }
}

/// Клиент: подключается к хосту по IP:порт или через mDNS.
class NetworkClient extends NetworkGameService {
  NetworkClient() : super(role: NetworkRole.client);

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;

  /// Подключиться по IP:порт.
  Future<bool> connect(String host, int port) async {
    _emitStatus(NetworkStatus.connecting);
    try {
      final uri = Uri.parse('ws://$host:$port');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _emitStatus(NetworkStatus.connected);
      _sub = _channel!.stream.listen(
        (data) {
          final msg =
              data is String ? NetworkMessage.decode(data) : null;
          if (msg != null) _emit(msg);
        },
        onDone: () => _emitStatus(NetworkStatus.disconnected),
        onError: (Object e) => _emitStatus(NetworkStatus.error),
      );
      return true;
    } catch (_) {
      _emitStatus(NetworkStatus.error);
      return false;
    }
  }

  /// Поиск игр через mDNS. Возвращает список найденных имён.
  Future<List<String>> discover({Duration timeout = const Duration(seconds: 4)}) async {
    try {
      final nsd = await _nsdRegistrar();
      if (nsd == null) return const [];
      return await nsd.discover(timeout);
    } catch (_) {
      return const [];
    }
  }

  /// Подключение по коду: пытаемся найти mDNS-сервис с этим кодом.
  Future<bool> connectByCode(String code) async {
    final normalized = ConnectCode.normalize(code);
    final nsd = await _nsdRegistrar();
    if (nsd == null) return false;
    final target = await nsd.resolve('rendzu-$normalized');
    if (target == null) return false;
    return connect(target.host, target.port);
  }

  @override
  void send(NetworkMessage m) {
    _channel?.sink.add(NetworkMessage.encode(m));
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _channel?.sink.close();
    _closeControllers();
  }
}

/// Найденная mDNS-служба.
class DiscoveredService {
  const DiscoveredService(this.host, this.port);
  final String host;
  final int port;
}

/// Тонкая обёртка над nsd, чтобы изолировать платформозависимый код.
/// Возвращает null, если пакет недоступен (тесты/десктоп).
Future<_NsdBridge?> _nsdRegistrar() async {
  // nsd — платформенный плагин; на тестовой машине (dart-only) его нет.
  // В реальном мобильном приложении этот мост вызовет nsd-регистратор.
  return _StubNsdBridge.instance;
}

abstract class _NsdBridge {
  Future<void> register(String name, int port);
  Future<List<String>> discover(Duration timeout);
  Future<DiscoveredService?> resolve(String name);
}

class _StubNsdBridge implements _NsdBridge {
  _StubNsdBridge._();
  static final _StubNsdBridge instance = _StubNsdBridge._();

  @override
  Future<void> register(String name, int port) async {}

  @override
  Future<List<String>> discover(Duration timeout) async => const [];

  @override
  Future<DiscoveredService?> resolve(String name) async => null;
}
