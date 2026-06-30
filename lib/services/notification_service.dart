import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _sirenPlayer = AudioPlayer();
  String? _cachedBeepPath;
  String? _cachedSirenPath;

  Future<void> playCheckInSound() async {
    try {
      final path = _cachedBeepPath ??= await _generateBeepFile();
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.play(DeviceFileSource(path));
    } catch (_) {}
  }

  Future<void> startSiren() async {
    try {
      final path = _cachedSirenPath ??= await _generateSirenFile();
      await _sirenPlayer.stop();
      await _sirenPlayer.setVolume(1.0);
      await _sirenPlayer.setReleaseMode(ReleaseMode.loop);
      await _sirenPlayer.play(DeviceFileSource(path));
    } catch (_) {}
  }

  Future<void> stopSiren() async {
    try {
      await _sirenPlayer.stop();
      await _sirenPlayer.setReleaseMode(ReleaseMode.release);
    } catch (_) {}
  }

  Future<String> _generateBeepFile() async {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/water_tasks_checkin.wav');
    if (await file.exists()) await file.delete();
    await file.writeAsBytes(_generateBeepWav());
    return file.path;
  }

  Future<String> _generateSirenFile() async {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/water_tasks_siren.wav');
    if (await file.exists()) await file.delete();
    await file.writeAsBytes(_generateSirenWav());
    return file.path;
  }

  Uint8List _generateBeepWav() {
    const sampleRate = 44100;
    const beepDuration = 0.35;
    const gapDuration = 0.12;
    const beepCount = 2;
    const totalDuration = (beepDuration + gapDuration) * beepCount - gapDuration;
    const freq = 180.0;
    final numSamples = (sampleRate * totalDuration).toInt();
    final samples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final beepIndex = (t / (beepDuration + gapDuration)).floor();
      final posInBeep = t - beepIndex * (beepDuration + gapDuration);
      if (beepIndex < beepCount && posInBeep < beepDuration) {
        final envelope = pow(sin(pi * posInBeep / beepDuration), 2).toDouble();
        final attack = posInBeep < 0.02 ? posInBeep / 0.02 : 1.0;
        final sine = sin(t * freq * 2 * pi);
        final square = sine >= 0 ? 1.0 : -1.0;
        final signal = sine * 0.3 + square * 0.7;
        final clipped = signal.clamp(-1.0, 1.0);
        final distorted = clipped * 0.7 + clipped.sign * 0.3;
        samples[i] = (32767 * 0.95 * envelope * attack * distorted).round();
      } else {
        samples[i] = 0;
      }
    }

    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);

    buffer.setUint8(0, 0x52);
    buffer.setUint8(1, 0x49);
    buffer.setUint8(2, 0x46);
    buffer.setUint8(3, 0x46);
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    buffer.setUint8(8, 0x57);
    buffer.setUint8(9, 0x41);
    buffer.setUint8(10, 0x56);
    buffer.setUint8(11, 0x45);

    buffer.setUint8(12, 0x66);
    buffer.setUint8(13, 0x6D);
    buffer.setUint8(14, 0x74);
    buffer.setUint8(15, 0x20);
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);

    buffer.setUint8(36, 0x64);
    buffer.setUint8(37, 0x61);
    buffer.setUint8(38, 0x74);
    buffer.setUint8(39, 0x61);
    buffer.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < numSamples; i++) {
      buffer.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  Uint8List _generateSirenWav() {
    const sampleRate = 44100;
    const duration = 4.0;
    final numSamples = (sampleRate * duration).toInt();
    final samples = Int16List(numSamples);

    const freq = 180.0;
    const subFreq = 90.0;
    double phase = 0.0;
    double subPhase = 0.0;
    for (int i = 0; i < numSamples; i++) {
      phase += freq / sampleRate;
      subPhase += subFreq / sampleRate;

      final envelope = i < sampleRate ? i / sampleRate : 1.0;
      final sub = subPhase % 1.0 < 0.5 ? 1.0 : -1.0;
      final pulse = phase % 1.0 < 0.4 ? 1.0 : -1.0;
      final raw = pulse * 0.65 + sub * 0.35;
      final saturated = (raw * 2.5).clamp(-1.0, 1.0);
      samples[i] = (32767 * 0.85 * envelope * saturated).round();
    }

    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);

    buffer.setUint8(0, 0x52);
    buffer.setUint8(1, 0x49);
    buffer.setUint8(2, 0x46);
    buffer.setUint8(3, 0x46);
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    buffer.setUint8(8, 0x57);
    buffer.setUint8(9, 0x41);
    buffer.setUint8(10, 0x56);
    buffer.setUint8(11, 0x45);

    buffer.setUint8(12, 0x66);
    buffer.setUint8(13, 0x6D);
    buffer.setUint8(14, 0x74);
    buffer.setUint8(15, 0x20);
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);

    buffer.setUint8(36, 0x64);
    buffer.setUint8(37, 0x61);
    buffer.setUint8(38, 0x74);
    buffer.setUint8(39, 0x61);
    buffer.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < numSamples; i++) {
      buffer.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}
