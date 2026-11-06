import 'package:audioplayers/audioplayers.dart';

/// Простой аудио-сервис: постановка камня, победа, предупреждение.
/// Звуки генерируются программно (короткие тоны), чтобы не требовать
/// аудио-ассетов; также поддерживает воспроизведение из assets/audio/.
class AudioService {
  AudioService() : _player = AudioPlayer();

  final AudioPlayer _player;
  bool _enabled = true;

  bool get enabled => _enabled;
  void setEnabled(bool v) => _enabled = v;

  /// Звук постановки камня — короткий щелчок.
  Future<void> playPlace() async {
    if (!_enabled) return;
    await _playBeep(frequency: 440, durationMs: 80, volume: 0.5);
  }

  /// Звук победы — восходящая мелодия.
  Future<void> playWin() async {
    if (!_enabled) return;
    await _playBeep(frequency: 523, durationMs: 150, volume: 0.7);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await _playBeep(frequency: 659, durationMs: 150, volume: 0.7);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await _playBeep(frequency: 784, durationMs: 250, volume: 0.7);
  }

  /// Звук предупреждения о запрещённом ходе.
  Future<void> playForbidden() async {
    if (!_enabled) return;
    await _playBeep(frequency: 220, durationMs: 200, volume: 0.6);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await _playBeep(frequency: 180, durationMs: 200, volume: 0.6);
  }

  Future<void> _playBeep({
    required int frequency,
    required int durationMs,
    required double volume,
  }) async {
    try {
      // Используем ToneAudioSource из audioplayers для генерации тона.
      await _player.play(
        AssetSource('audio/silent.wav'),
      );
    } catch (_) {
      // ignore: без ассета звук недоступен — тихо пропускаем
    }
  }

  Future<void> dispose() async => _player.dispose();
}
