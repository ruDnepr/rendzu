// Условный экспорт: на нативных платформах (dart:io) — полная реализация
// хоста/клиента через shelf + WebSocket; на web — заглушка.
export 'package:rendzu/domain/network/network_service_base.dart';
export 'package:rendzu/domain/network/network_service_io.dart'
    if (dart.library.html) 'package:rendzu/domain/network/network_service_web.dart';
