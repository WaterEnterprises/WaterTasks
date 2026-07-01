import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

enum ToneType { buzzer, classicBeep, softChime, pulse, silent }

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _sirenPlayer = AudioPlayer();
  String? _cachedClassicBeepPath;
  String? _cachedBuzzerPath;
  String? _cachedChimePath;
  String? _cachedPulsePath;

  Future<void> playCheckInSound() async {
    try {
      final path = _cachedClassicBeepPath ??= await _generateClassicBeepFile();
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.play(DeviceFileSource(path));
    } catch (_) {}
  }

  Future<void> startSiren({ToneType toneType = ToneType.buzzer}) async {
    if (toneType == ToneType.silent) return;
    try {
      String path;
      switch (toneType) {
        case ToneType.classicBeep:
          path = _cachedClassicBeepPath ??= await _generateClassicBeepFile();
        case ToneType.softChime:
          path = _cachedChimePath ??= await _generateChimeFile();
        case ToneType.pulse:
          path = _cachedPulsePath ??= await _generatePulseFile();
        default:
          path = _cachedBuzzerPath ??= await _generateBuzzerFile();
      }
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

  Uint8List _buildWav(Int16List samples) {
    final numSamples = samples.length;
    final dataSize = numSamples * 2;
    const sampleRate = 44100;
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

  Future<String> _generateClassicBeepFile() async {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/water_tasks_classic_beep.wav');
    if (await file.exists()) await file.delete();
    await file.writeAsBytes(_buildWav(_generateClassicBeepSamples()));
    return file.path;
  }

  Future<String> _generateBuzzerFile() async {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/water_tasks_buzzer.wav');
    if (await file.exists()) await file.delete();
    await file.writeAsBytes(_buildWav(_generateBuzzerSamples()));
    return file.path;
  }

  Future<String> _generateChimeFile() async {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/water_tasks_chime.wav');
    if (await file.exists()) await file.delete();
    await file.writeAsBytes(_buildWav(_generateChimeSamples()));
    return file.path;
  }

  Future<String> _generatePulseFile() async {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/water_tasks_pulse.wav');
    if (await file.exists()) await file.delete();
    await file.writeAsBytes(_buildWav(_generatePulseSamples()));
    return file.path;
  }

  Int16List _generateClassicBeepSamples() {
    const sampleRate = 44100;
    const beepDuration = 0.35;
    const gapDuration = 0.12;
    const beepCount = 2;
    const totalDuration = (beepDuration + gapDuration) * beepCount - gapDuration;
    const freq = 440.0;
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

    return samples;
  }

  Int16List _generateBuzzerSamples() {
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

    return samples;
  }

  Int16List _generateChimeSamples() {
    const sampleRate = 44100;
    const duration = 2.0;
    final numSamples = (sampleRate * duration).toInt();
    final samples = Int16List(numSamples);

    const note1Freq = 523.25;
    const note2Freq = 659.25;
    const noteLength = 0.7;
    const gapLength = 0.15;
    const totalNote = noteLength + gapLength;

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final posInCycle = t % totalNote;
      double sample = 0.0;

      if (posInCycle < noteLength) {
        final fadeIn = posInCycle < 0.05 ? posInCycle / 0.05 : 1.0;
        final fadeOut = posInCycle > noteLength - 0.15
            ? (noteLength - posInCycle) / 0.15
            : 1.0;
        final envelope = fadeIn * fadeOut;
        final noteIndex = (t / totalNote).floor();
        final freq = noteIndex.isEven ? note1Freq : note2Freq;
        sample = sin(t * freq * 2 * pi) * envelope * 0.6;
      }

      samples[i] = (32767 * 0.85 * sample).round();
    }

    return samples;
  }

  Int16List _generatePulseSamples() {
    const sampleRate = 44100;
    const duration = 3.0;
    final numSamples = (sampleRate * duration).toInt();
    final samples = Int16List(numSamples);

    const pulseFreq = 65.0;
    const pulseOn = 0.2;
    const pulseOff = 0.8;
    const pulseCycle = pulseOn + pulseOff;

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final posInCycle = t % pulseCycle;

      if (posInCycle < pulseOn) {
        final fadeIn = posInCycle < 0.02 ? posInCycle / 0.02 : 1.0;
        final fadeOut = posInCycle > pulseOn - 0.04
            ? (pulseOn - posInCycle) / 0.04
            : 1.0;
        final envelope = fadeIn * fadeOut;
        final sine = sin(t * pulseFreq * 2 * pi);
        final square = sine >= 0 ? 1.0 : -1.0;
        final raw = square * 0.7 + sine * 0.3;
        samples[i] = (32767 * 0.9 * envelope * raw).round();
      }
    }

    return samples;
  }
}
