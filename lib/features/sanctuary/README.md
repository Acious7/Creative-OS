# Sanctuary Module (`lib/features/sanctuary/`)

> [!NOTE]
> The Sanctuary is Etole Studio's dedicated personal life, creativity, and deep solitude dimension. It operates 100% on-device, adheres to strict digital sovereignty principles, and requires zero paid APIs.

---

## 🏛️ Architectural Overview

```
lib/features/sanctuary/
├── domain/
│   ├── sanctuary_models.dart         # Models for Secret Spots, Scrapbook, Journal, and Inner Circle
│   └── sanctuary_storage_service.dart# Non-destructive local JSON/AES encrypted storage & archive export/import
└── presentation/
    └── screens/
        ├── sanctuary_hub_screen.dart     # Master portal unifying all 5 dimensions + On This Day card
        ├── monk_mode_screen.dart         # Fullscreen solitary focus mode with breathing sphere & soundscapes
        ├── creative_scrapbook_screen.dart# Gesture sketchpad, thought napkin & camera swatch extractor
        ├── personal_atlas_screen.dart    # OpenStreetMap visualizer combining meetups & secret spots
        ├── secret_spots_screen.dart      # Curated personal hideouts (cafes, viewpoints, acoustic lounges)
        ├── inner_circle_screen.dart      # Meaningful friendship cadence & warmth meter
        └── black_box_journal_screen.dart # Biometrically encrypted private diary (zero telemetry)
```

---

## 🌟 Core Pillars

### 1. Monk Mode (`monk_mode_screen.dart`)
* **Breathing Sphere:** Animated organic ember sphere pulsing on a 4-second inhale/exhale cycle.
* **Presets:** 15m, 25m (Pomodoro), 45m (Sprint), and Open Flow.
* **Focus Thought Card:** A single input field asking: *"What is the single thing that matters right now?"*
* **Soundscape Integration:** Directly bound to `ambientSoundscapeProvider` for instant playback.

### 2. Creative Scrapbook (`creative_scrapbook_screen.dart`)
* **Spontaneous Thought Napkin:** Quick-capture cards for poetry, thoughts, or reflections.
* **Obsidian Sketchpad:** Finger gesture drawing using `SignatureController` with multi-color ink switching on black glass.
* **Color Swatch Extractor:** Real-world camera sampling converting physical items into hex palettes with one-tap copy.

### 3. Personal Atlas & Secret Spots (`personal_atlas_screen.dart`, `secret_spots_screen.dart`)
* **Personal Atlas:** Displays all places visited for meetups (from Drift SQLite `NetworkingEvents`) alongside personal hideouts on an interactive Web Mercator map.
* **Secret Spots:** Bookmarking system with 6 mood vibes (*Quiet Cafe, Sunset Viewpoint, Acoustic Lounge, Bookstore, Studio, Late Night*), ratings, and private notes.
* **"On This Day" Serendipity:** Automatically scans for memories and spots created on the current date in previous months or years.

### 4. Inner Circle & Friendship Cadence (`inner_circle_screen.dart`)
* **Warmth Gauge:** Visual flame meter calculating `daysSinceLastContact / cadenceDays` (14, 30, 60, or 90 days).
* **Gift & Interest Diary:** Notes on shoe sizes, book wishlists, favorite coffee, and casual mentions.
* **1-Tap "Say Hello":** Opens WhatsApp or SMS with a warm personal greeting and zero business pitch.

### 5. Biometric Black Box Journal (`black_box_journal_screen.dart`)
* **Security:** Authenticates via device biometrics (`local_auth`: fingerprint/face unlock).
* **Encryption:** Encrypted on-device using a unique per-device key stored in `FlutterSecureStorage`.
* **Data Sovereignty:** One-tap export to `/storage/emulated/0/Documents/Etole/` (or app-private fallback) and one-tap restore via `importSanctuaryArchive`.
