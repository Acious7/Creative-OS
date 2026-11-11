# Changelog — Etole

## [2.0.0+11] - 2026-10-18
### Phase 8 Final Polish & Delivery Release

#### 🏛️ Four Interconnected Worlds with Living Glass Shard Parallax Hub
- **The Hub (World Navigation)**: 2×2 dark frosted glass window panes ("BRIAN", "NETWORK", "DOCS", "SETTINGS") with physical-sensor gyro/touch 3D perspective tilt, unique handmade chipped corners and hairline cracks, and seamless 3D hinge swing fly-through. ZERO bottom navigation bar.
- **World 1 — Brian ("The Stage")**: Tactile 3D card tilt with specular light reflection, 5 original African-inspired vector card designs (`Ember`, `Savannah`, `Ochre Line`, `Night Market`, `Clay`), QR modes ring (Save contact, WhatsApp me, Watch reel, Custom link), 10-per-A4 PDF gang sheet generator with crop marks & bleed, and rich email signature drawer.
- **World 2 — Network**: Places/Events first grid, event details, people met, unified person profile, voice notes, ML Kit card scan verification, and 5-option fast drawer add.
- **World 3 — Docs**: Dark frosted glass window panes matching the Hub (Contacts, Recent Docs, Create New), top search bar, strictly 5 document types (`Quotation`, `Invoice`, `Receipt`, `Rate Card`, `Contract`), 1-tap sequential conversion, client directory with 30-day trash & instant undo. Zero blue/teal accents.
- **World 4 — Settings ("The Workshop")**: Calm artist's notebook design, 01-11 numbered list with large Bebas Neue numerals in Ember Orange, dedicated 84px left spacer for floating `< HUB` glass pill clearance, sub-screens for Appearance, Reminders, Security, Backup (.etole archive), and About (BE monogram, 5-tap developer gallery).

#### 💎 Polish & Compliance
- **Accent Color**: Strictly Ember Orange (`#FF6A1F`) and warm cream (`#F2EDE4`) throughout all screens; zero blue/teal elements anywhere.
- **Phone Number**: Unified phone/WhatsApp number `+254 718 013 579` across all database seeds, digital cards, signatures, and contact cards.
- **Empty States**: Delicate ink line-art aperture geometry with clean typography (no generic icon circles).
- **Navigation**: Zero bottom navigation bar remains anywhere in the app; elegant `< HUB` floating frosted glass pill provides universal back navigation.

## [2.0.0] - 2026-10-17
### Clean Slate Transformation from BizDoc to Etole

#### 🌟 Brand & Native Identity
- Changed Application ID and package namespace to `com.brianetole.etole` in `android/app/build.gradle.kts` and created new Kotlin `MainActivity.kt`.
- Set app display name to **Etole** across all launchers and manifests.
- Reused existing production release keystore (`android/app/bizdoc-release-key.jks`) with alias `bizdoc`.
- Purged all references to BizDoc and Acious Media across the entire repository.
- Mastered new bespoke app icon: "The Cinematic Aperture Monogram" with full Android adaptive icon mipmaps, monochrome layer for Android 13+, and obsidian splash screen.

#### 🗄️ Database Clean Slate (Schema Version 1)
- Initialized fresh `etole_db` SQLite database with clean Drift schema version 1.
- Purged 10 obsolete legacy tables and features (estimates, project management, multi-company accounting, legacy backup scripts).
- Preserved only the 15 clean tables Etole needs.
- Pre-filled Brian Etole's details from `brianetole.com` (`hello@brianetole.com`, `+254 700 000 000`, `Nairobi, Kenya`, `REAL STORIES. IMAGINED WORLDS.`), leaving payment fields blank for user entry.

#### 📇 Brian Tab (Digital Identity)
- Created 5 East African tribal business card designs (`Ember`, `Savannah`, `Ochre Line`, `Night Market`, `Clay`).
- Added tactile 3D drag-to-tilt with specular light sheen reflection to `BusinessCard3DFlipper`.
- Implemented QR mode switcher (vCard, WhatsApp, Showreel, Custom URL).
- Implemented NFC tag writing and reading session.
- Implemented 10-per-A4 PDF gang sheet generator with 3mm bleed, crop marks, and safe area guides.
- Implemented rich HTML and plain-text email signature generator.

#### 🤝 Network Tab (Occasions & People)
- Built unified `NetworkHubScreen` combining Occasions (Events) and People (Leads).
- Added on-device OCR business card text recognition with `google_mlkit_text_recognition`.
- Built `CardOcrVerificationScreen` with interactive image zoom and token auto-assignment.
- Added direct phonebook contact import via `flutter_contacts`.
- Added 1-tap "Convert to Client" workflow promoting networking leads to active clients.

#### 📄 Docs Tab (Essential Documents)
- Restricted document types to 5 core formats: `Quotation`, `Invoice`, `Receipt`, `Rate Card`, `Contract`.
- Implemented 1-tap sequential document conversion:
  - Quotation &rarr; Invoice &rarr; Receipt
  - Rate Card &rarr; Quotation
- Preserved dual-party contract clause builder and counter-signed camera scanner.

#### ⚙️ Settings & Polish
- Added OLED Pure Black theme mode, Cinematic Dark mode, and Warm Light mode.
- Added Reduce Motion toggle.
- Set 30-day retention policy on Trash.
- Offline backup and restore with `.etole` format.
