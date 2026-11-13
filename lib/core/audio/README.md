# Ambient Audio Module (`lib/core/audio/`)

> [!NOTE]
> This module provides procedural audio synthesis and ambient soundscape playback for Etole Studio. It generates 16-bit PCM WAV audio loops dynamically in Dart memory without requiring external audio asset files or network bandwidth.

---

## 🎛️ Architecture

```
lib/core/audio/
├── ambient_soundscape_service.dart   # Procedural WAV generation & Riverpod state management
└── README.md                         # Architecture and DSP algorithms documentation
```

---

## 🎵 Procedural Synthesis Algorithms

Each soundscape generates a seamless 5-second 22,050 Hz 16-bit mono PCM buffer with boundary windowing:

1. **`savannahFire` (Campfire Embers & Night Warmth):**
   * Uses low-pass filtered white noise ($y_i = 0.94 y_{i-1} + 0.06 x_i$) to simulate the low rumble of an outdoor wood fire.
   * Injects sparse high-frequency impulse pops at a probability threshold ($p < 0.0018$) to simulate crackling wood embers.
2. **`riftValleyRain` (Tropical Canopy Rain):**
   * Implements a 3-pole pink-noise IIR filter approximation over uniform pseudo-random noise to mimic raindrops drumming on glass and foliage.
3. **`kalimbaMeditation` (Harmonic Acoustic Resonance):**
   * Synthesizes a pentatonic chord (A3: 220Hz, C4: 261.63Hz, E4: 329.63Hz, G4: 392Hz, B4: 493.88Hz).
   * Applies slow undulating low-frequency modulation (LFO at 0.3 Hz) for a meditative Tibetan bowl / Kalimba shimmer.

---

## 🚀 Usage

```dart
// Watch active soundscape state
final soundscape = ref.watch(ambientSoundscapeProvider);

// Play a soundscape
ref.read(ambientSoundscapeProvider.notifier).setSoundscape(SoundscapeType.savannahFire);

// Toggle play/pause
ref.read(ambientSoundscapeProvider.notifier).togglePlayPause();

// Set volume (0.0 to 1.0)
ref.read(ambientSoundscapeProvider.notifier).setVolume(0.7);
```
