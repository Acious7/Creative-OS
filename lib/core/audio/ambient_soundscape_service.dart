import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SoundscapeType {
  off('Silent Sanctuary', 'None'),
  savannahFire('Savannah Embers', 'Campfire warmth & night crackle'),
  riftValleyRain('Rift Valley Rain', 'Gentle rain on canopy'),
  kalimbaMeditation('Kalimba & Chimes', 'Harmonic acoustic resonance'),
  binauralAlpha('Alpha Flow (432Hz)', '10Hz binaural pulse for deep focus'),
  rainAndFire('Rain & Campfire', 'Dual-mix of canopy rain & crackling fire');

  final String title;
  final String subtitle;

  const SoundscapeType(this.title, this.subtitle);
}

class AmbientSoundscapeState {
  final SoundscapeType activeType;
  final bool isPlaying;
  final double volume;

  const AmbientSoundscapeState({
    this.activeType = SoundscapeType.off,
    this.isPlaying = false,
    this.volume = 0.5,
  });

  AmbientSoundscapeState copyWith({
    SoundscapeType? activeType,
    bool? isPlaying,
    double? volume,
  }) {
    return AmbientSoundscapeState(
      activeType: activeType ?? this.activeType,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
    );
  }
}

class AmbientSoundscapeNotifier extends StateNotifier<AmbientSoundscapeState> {
  AudioPlayer? _player;
  final Map<SoundscapeType, Uint8List> _audioCache = {};

  AmbientSoundscapeNotifier() : super(const AmbientSoundscapeState());

  Future<void> _initPlayer() async {
    if (_player == null) {
      _player = AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.setVolume(state.volume);
    }
  }

  Future<void> setSoundscape(SoundscapeType type) async {
    if (type == SoundscapeType.off) {
      await stop();
      state = state.copyWith(activeType: SoundscapeType.off, isPlaying: false);
      return;
    }

    try {
      await _initPlayer();
      Uint8List? bytes = _audioCache[type];
      if (bytes == null) {
        bytes = _generateWavForType(type);
        _audioCache[type] = bytes;
      }

      await _player!.stop();
      await _player!.play(BytesSource(bytes));
      await _player!.setVolume(state.volume);

      state = state.copyWith(activeType: type, isPlaying: true);
    } catch (_) {
      // Graceful fallback
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<void> togglePlayPause() async {
    if (state.activeType == SoundscapeType.off) {
      await setSoundscape(SoundscapeType.savannahFire);
      return;
    }

    if (state.isPlaying) {
      await _player?.pause();
      state = state.copyWith(isPlaying: false);
    } else {
      await _player?.resume();
      state = state.copyWith(isPlaying: true);
    }
  }

  Future<void> setVolume(double vol) async {
    final clamped = vol.clamp(0.0, 1.0);
    state = state.copyWith(volume: clamped);
    await _player?.setVolume(clamped);
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
    state = state.copyWith(isPlaying: false, activeType: SoundscapeType.off);
  }

  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  static Uint8List _generateWavForType(SoundscapeType type) {
    const sampleRate = 22050;
    const durationSeconds = 5; // 5-second seamless procedural loop
    const totalSamples = sampleRate * durationSeconds;
    final samples = Int16List(totalSamples);
    final rng = Random(42);

    switch (type) {
      case SoundscapeType.savannahFire:
        // Warm low rumble + random ember crackles & pops
        double filterState = 0.0;
        for (int i = 0; i < totalSamples; i++) {
          final whiteNoise = (rng.nextDouble() * 2.0 - 1.0);
          // Low-pass filter for cozy ambient campfire roar
          filterState = filterState * 0.94 + whiteNoise * 0.06;

          // Occasional sharp crackle pop
          double pop = 0.0;
          if (rng.nextDouble() < 0.0018) {
            pop = (rng.nextDouble() * 2.0 - 1.0) * 0.45;
          }

          final mixed = (filterState * 0.4 + pop).clamp(-1.0, 1.0);
          samples[i] = (mixed * 32767).toInt();
        }
        break;

      case SoundscapeType.riftValleyRain:
        // Gentle pink-noise filtered rain with subtle soft drops
        double b0 = 0, b1 = 0, b2 = 0;
        for (int i = 0; i < totalSamples; i++) {
          final white = rng.nextDouble() * 2.0 - 1.0;
          b0 = 0.99765 * b0 + white * 0.0990460;
          b1 = 0.96300 * b1 + white * 0.1600000;
          b2 = 0.57000 * b2 + white * 0.5600000;
          final pink = (b0 + b1 + b2) * 0.08;
          final val = pink.clamp(-1.0, 1.0);
          samples[i] = (val * 32767).toInt();
        }
        break;

      case SoundscapeType.kalimbaMeditation:
        // Soft meditative pentatonic chime chord (A3, C4, E4, G4, B4)
        final freqs = [220.0, 261.63, 329.63, 392.0, 493.88];
        for (int i = 0; i < totalSamples; i++) {
          final t = i / sampleRate;
          double sample = 0.0;
          for (int f = 0; f < freqs.length; f++) {
            final freq = freqs[f];
            // Slow undulating modulation (LFO)
            final tremolo = 0.6 + 0.4 * sin(2 * pi * 0.3 * t + f);
            sample += sin(2 * pi * freq * t) * 0.12 * tremolo;
          }
          final val = sample.clamp(-1.0, 1.0);
          samples[i] = (val * 32767).toInt();
        }
        break;

      case SoundscapeType.binauralAlpha:
        // 432 Hz healing tone with subtle 10 Hz Alpha beat pulsation
        for (int i = 0; i < totalSamples; i++) {
          final t = i / sampleRate;
          final carrier = sin(2 * pi * 432.0 * t);
          final beat = 0.5 + 0.5 * sin(2 * pi * 10.0 * t); // 10Hz Alpha pulse
          final subDrone = sin(2 * pi * 108.0 * t) * 0.25; // Warm sub-octave
          final sample = (carrier * 0.18 * beat + subDrone).clamp(-1.0, 1.0);
          samples[i] = (sample * 32767).toInt();
        }
        break;

      case SoundscapeType.rainAndFire:
        // Dual-mix: 60% tropical canopy rain + 40% crackling campfire embers
        double filterState = 0.0;
        double b0 = 0, b1 = 0, b2 = 0;
        for (int i = 0; i < totalSamples; i++) {
          final whiteFire = rng.nextDouble() * 2.0 - 1.0;
          filterState = filterState * 0.94 + whiteFire * 0.06;
          double pop = 0.0;
          if (rng.nextDouble() < 0.0016) {
            pop = (rng.nextDouble() * 2.0 - 1.0) * 0.40;
          }
          final fire = filterState * 0.35 + pop;

          final whiteRain = rng.nextDouble() * 2.0 - 1.0;
          b0 = 0.99765 * b0 + whiteRain * 0.0990460;
          b1 = 0.96300 * b1 + whiteRain * 0.1600000;
          b2 = 0.57000 * b2 + whiteRain * 0.5600000;
          final rain = (b0 + b1 + b2) * 0.07;

          final blended = (rain * 0.60 + fire * 0.40).clamp(-1.0, 1.0);
          samples[i] = (blended * 32767).toInt();
        }
        break;

      case SoundscapeType.off:
        break;
    }

    // Apply fade-in and fade-out at loop boundaries for click-free seamless looping
    const fadeSamples = 1000;
    for (int i = 0; i < fadeSamples; i++) {
      final factor = i / fadeSamples;
      samples[i] = (samples[i] * factor).toInt();
      final endIdx = totalSamples - 1 - i;
      samples[endIdx] = (samples[endIdx] * factor).toInt();
    }

    // Build complete WAV binary
    final wavBytes = ByteData(44 + totalSamples * 2);
    // "RIFF"
    wavBytes.setUint8(0, 0x52);
    wavBytes.setUint8(1, 0x49);
    wavBytes.setUint8(2, 0x46);
    wavBytes.setUint8(3, 0x46);
    wavBytes.setUint32(4, 36 + totalSamples * 2, Endian.little);
    // "WAVE"
    wavBytes.setUint8(8, 0x57);
    wavBytes.setUint8(9, 0x41);
    wavBytes.setUint8(10, 0x56);
    wavBytes.setUint8(11, 0x45);
    // "fmt "
    wavBytes.setUint8(12, 0x66);
    wavBytes.setUint8(13, 0x6D);
    wavBytes.setUint8(14, 0x74);
    wavBytes.setUint8(15, 0x20);
    wavBytes.setUint32(16, 16, Endian.little);
    wavBytes.setUint16(20, 1, Endian.little); // PCM
    wavBytes.setUint16(22, 1, Endian.little); // Mono
    wavBytes.setUint32(24, sampleRate, Endian.little);
    wavBytes.setUint32(28, sampleRate * 2, Endian.little);
    wavBytes.setUint16(32, 2, Endian.little);
    wavBytes.setUint16(34, 16, Endian.little);
    // "data"
    wavBytes.setUint8(36, 0x64);
    wavBytes.setUint8(37, 0x61);
    wavBytes.setUint8(38, 0x74);
    wavBytes.setUint8(39, 0x61);
    wavBytes.setUint32(40, totalSamples * 2, Endian.little);

    for (int i = 0; i < totalSamples; i++) {
      wavBytes.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return wavBytes.buffer.asUint8List();
  }
}

final ambientSoundscapeProvider =
    StateNotifierProvider<AmbientSoundscapeNotifier, AmbientSoundscapeState>(
      (ref) => AmbientSoundscapeNotifier(),
    );
