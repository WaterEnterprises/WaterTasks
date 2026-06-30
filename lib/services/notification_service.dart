import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AudioPlayer _player = AudioPlayer();
  String? _cachedBeepPath;

  Future<void> playCheckInSound() async {
    try {
      final path = _cachedBeepPath ??= await _generateBeepFile();
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.play(DeviceFileSource(path));
    } catch (_) {}
  }

  Future<String> _generateBeepFile() async {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/water_tasks_checkin.wav');
    if (await file.exists()) return file.path;
    await file.writeAsBytes(_generateBeepWav());
    return file.path;
  }

  Uint8List _generateBeepWav() {
    const sampleRate = 44100;
    const beepDuration = 0.2;
    const gapDuration = 0.15;
    const beepCount = 3;
    const totalDuration = (beepDuration + gapDuration) * beepCount - gapDuration;
    const freq1 = 440.0;
    const freq2 = 880.0;
    final numSamples = (sampleRate * totalDuration).toInt();
    final samples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final beepIndex = (t / (beepDuration + gapDuration)).floor();
      final posInBeep = t - beepIndex * (beepDuration + gapDuration);
      if (beepIndex < beepCount && posInBeep < beepDuration) {
        final envelope = pow(sin(pi * posInBeep / beepDuration), 2).toDouble();
        final value1 = sin(t * freq1 * 2 * pi);
        final value2 = sin(t * freq2 * 2 * pi);
        final mixed = (value1 + value2 * 0.7) / 1.7;
        samples[i] = (32767 * 0.8 * envelope * mixed).round();
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
}
