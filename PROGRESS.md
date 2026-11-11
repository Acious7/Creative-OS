# Etole — Simplification, Rebranding & Redesign Progress

> **Environment**: Flutter executable is strictly located at `C:\tools\flutter\bin\flutter.bat`. Do NOT search for Flutter in other paths.

## Project Overview
Transforming the app into **Etole** — an ultra-clean, offline-first personal creative business suite for Brian Etole (Nairobi-based hybrid filmmaker and photographer).

- **Application ID:** `com.brianetole.etole` (Brand-new, separate standalone app)
- **App Display Name:** `Etole`
- **Signing Key:** Reusing existing release key at `android/app/bizdoc-release-key.jks` (alias `bizdoc`, credentials in `android/key.properties`).
- **Database Strategy:** **Clean Slate (Schema Version 1)** — Fresh `etole_db` database containing ONLY the 15 clean tables Etole needs. No migrations or legacy data preserved.
- **Architecture:** 100% offline-first, Riverpod, Material 3, Dark Cinematic design system from `brianetole.com`

---

## Email Integration Status & Remaining Work

### Done:
1. **Google OAuth & Gmail API**: Direct RFC 822 MIME dispatch with `gmail.send` scope, secure storage tokens, and automatic token refresh.
2. **Branded Email Builder**: Table-based email generator matching `brianetole.com` dark cinematic tokens (`#0a0c0d`, `#ff6a1f`, `#f3ead9`), personal signature ("Brian Etole · Hybrid Filmmaker · Photographer"), and social footer.
3. **Chosen Design Integrated**: Option 2 (The Editorial Gallery) enhanced with dark letterhead/footer and ember accent line set as default theme.
4. **Editable Templates Infrastructure**: `EmailTemplate` and `EmailTemplateRepository` with persistent storage for all 7 types (`quotation`, `invoice`, `receipt`, `rateCard`, `contract`, `intro`, `test`).
5. **Recovery Build Check**: Verified with `dart analyze lib/features/email`: **0 errors, 0 warnings**.
6. **Step 2 — Email Templates Finalized**: Default subjects, messages, and placeholders (`{first_name}`, `{document_number}`, `{amount}`, `{due_date}`, `{project}`) finalized for all 7 types. Editable in Settings → Email, personal sign-off "Brian Etole · Hybrid Filmmaker · Photographer", and brianetole.com footer.
7. **Step 3 — New Send Screen Complete**: Upgraded `SendDocumentEmailSheet` featuring To recipient input + contact picker sheet from SQLite clients/leads, multiple recipients parsing, CC/BCC expandable under "More", 7-template chooser chips with auto-resolved placeholders, PDF attachment chip with tap-to-preview dialog, live branded HTML preview toggle, ember "SEND WITH GMAIL" button, success confirmation toast, and activity logging on both document and client contact records.
8. **Step 4 — Inline CID Branding & Settings Cleanup Complete**: Embedded logo and all 7 social icons directly into every outgoing email as inline CID attachments (`assets/email/`, < 6 KB total). Formatted MIME output with standard RFC 2387 `multipart/related`. Verified 100% test pass (5/5) in `test/unit/email_branding_test.dart`.
9. **Step 5 — Honest Connection Status & Resilient Google Sign-In Complete**:
   - **Honest Connection Status**: Settings → Gmail now tests actual token validity on startup via `getConnectionStatus()`. Only shows "Connected" (green) when a working permission exists. If expired, shows "Reconnect needed" (amber) with a prominent "Reconnect" button.
   - **Silent Auto-Refresh + Interactive Fallback**: Before sending (both in Settings "Send Test Email" and document sheet), the app silently refreshes the token. If the session expired, it automatically prompts the Google sign-in sheet on the spot instead of failing with an error.
   - **Update & Reinstall Survival**: Configured `FlutterSecureStorage` with `AndroidOptions(encryptedSharedPreferences: true, resetOnError: true)`. Added Google Play Services session recovery fallback so identity and tokens survive updates and reinstalls.
   - **Testing Mode Notice**: Added clear on-screen notice explaining the 7-day token expiration policy in Google Cloud OAuth Testing mode and how 1-tap reconnect works.
10. **Step 6 — Custom Logo in Branding, Editable 3 Socials & Cream/Ember Links Complete**:
    - **Top Logo**: Built-in logo image removed from header. Dynamically loads and attaches the custom logo uploaded in **Settings → Branding** (`Brands.logoPath`). If no logo is uploaded, displays only the styled "BRIAN ETOLE" wordmark and "REAL STORIES • IMAGINED WORLDS." tagline.
    - **Footer Socials Pruned to 3**: Kept strictly to Instagram, LinkedIn, and WhatsApp. Completely removed YouTube, TikTok, X, and Facebook.
    - **Editable in Settings → Branding**: Added dedicated fields with pre-filled defaults (`instagram.com/brianetole`, `linkedin.com/in/brianetole`, `+254 718 013 579`). Saved in persistent secure storage; leaving a field empty cleanly hides that link in outgoing emails.
    - **Reliable Email Formatting**: Replaced broken white dot icons with clean text links (`Instagram · LinkedIn · WhatsApp`) in `#f3ead9` cream separated by `#ff6a1f` ember bullets (`&bull;`), 100% immune to Gmail image blocking. WhatsApp styled in matching cream (no green).
    - **Device Installation**: Release APK successfully installed over USB debugging onto phone (`9dwonrnb7haasckj`) via streamed install (`Success`).

### Next Step:
- Tap "Send Test Email" in Settings → 05 · EMAIL on your phone to verify the outgoing email in your inbox.

---

## Roadmap & Status

| Step | Phase | Status | Details |
| :--- | :--- | :--- | :--- |
| **Step 1** | Plan & Architectural Inspection | ✅ Complete | Approved by user with clean slate directive. |
| **Step 2** | Safety, Git Baseline & Code Pruning | ✅ Complete | 11,893 lines of dead code pruned, committed (`Step 2: Prune removed features and dead code`). |
| **Step 3** | Clean Slate Database v1 & App ID Setup | ✅ Complete | Application ID set to `com.brianetole.etole`. Schema v1 initialized with fresh `etole_db`. Pre-filled Brian's details from `brianetole.com` (payment fields left blank). Legacy archive & dev backup removed. All BizDoc/Acious references purged. `flutter analyze`: 0 errors. |
| **Step 4** | Identity & Design System | ✅ Complete | `brianetole.com` dark cinematic palette (`#0a0c0d`, `#ff6a1f`, cream text), uppercase display headings, grain texture overlay, component library. |
| **Step 5** | Brian Tab (Digital Card) | ✅ Complete | 5 East African tribal designs (Ember, Savannah, Ochre Line, Night Market, Clay). Sensor sheen & tactile 3D drag tilt, front/back flip, QR switcher (vCard, WhatsApp, Showreel, Custom URL), NFC write session, 10-per-A4 PDF print with crop marks & bleed, email signature generator. |
| **Step 6** | Network Tab | ✅ Complete | `NetworkHubScreen` combining Occasions (Upcoming, Today, Past, Quick meet) and People. On-device ML Kit OCR card scanner with verification screen (name, role, org, phone, email, website), QR scan, phone contacts import, "Send intro", "Mark as client". |
| **Step 7** | Docs Tab | ✅ Complete | Strictly 5 document types (Quotation, Invoice, Receipt, Rate Card, Contract), 1-tap conversion (Quotation &rarr; Invoice &rarr; Receipt), clause contract builder with signature capture, Rate Card PDF export. |
| **Step 8** | Settings & Polish | ✅ Complete | Brian's pre-filled details, theme options (OLED Pure Black, Dark, Reduce motion), 30-day trash retention. |
| **Step 9** | App Icon, Testing & Delivery | ✅ Complete | Mastered "The Cinematic Aperture Monogram" app icon, adaptive mipmaps, monochrome layer for Android 13+, matching native splash screen. Full automated test suite passed (4/4 tests). Signed release APK assembled and signed with `bizdoc-release-key.jks` at `build/app/outputs/flutter-apk/app-release.apk` (Version `2.0.0+2`). |

## Shards & Worlds Redesign Roadmap

| Phase | Description | Status | Gate Details |
| :--- | :--- | :--- | :--- |
| **Phase 1** | Design System, Fonts, Palette, Components & Gallery | ✅ Approved | Approved by user. Offline fonts, obsidian/ember palette, no-box layout, glass pills, design gallery. |
| **Phase 2** | Artwork Generation with Gemini | ⚠️ In Progress (Queued for Quota Reset) | Swappable asset architecture in place (`assets/hub/hub_back.webp`, `hub_mid.webp`, `hub_front.webp`). Will retry Gemini when 5h quota resets or user drops artwork in `assets/hub/`. |
| **Phase 3** | The Hub (Living Parallax & 2x2 Window Navigation) | ✅ Approved | Approved by user on phone. Large 2x2 window panes, 3D perspective tilt, handmade broken-glass chips and hairline cracks, 3D hinge swing fly-through, and zero bottom nav bar. |
| **Phase 4** | World 1 — Brian: "The Stage" | ✅ Approved | Approved by user on phone. The Stage, 5 vector tribal designs, 3D tilt, QR modes ring, swipe navigation, black+ember Night Market, email signature drawer. |
| **Phase 5** | World 2 — Network (Places/Events & People Met) | ✅ Approved | Approved by user on phone. Simple and human places/events grid, inside event detail, people met there, unified person profile, voice notes, card scans, 5-option fast drawer add. |
| **Phase 6** | World 3 — Docs (Dark Glass Panes: Contacts, Recent Docs, Create New) | ✅ Approved | Approved by user on phone. Dark glass windows (Contacts, Recent Docs, Create New), top search bar, zero blue, fixed HUB clearance, quiet status stamps, 5-document types split editor, services sheet, client directory with Trash & Undo. |
| **Phase 7** | World 4 — Settings: "The Workshop" | ✅ Approved | Calm artist's notebook design, 01-11 numbered list with large ember numerals and hairline dividers, 84px left spacer `< HUB` clearance, clean dedicated sub-screens (`06 · Appearance`, `07 · Reminders`, `09 · Backup`, `11 · About`), restyled ink line-art empty states, loading indicator, sound & haptics. Tested and approved by user. |
| **Phase 8** | Full Test, Polish & Delivery | ✅ Complete | Full regression verified across all 4 worlds. Phone number strictly `+254 718 013 579`. Zero bottom navigation bar. Single accent Ember Orange (`#FF6A1F`). Signed release APK v2.0.0+11 assembled and installed on physical phone. Full journey video recorded. |

---

## Log of Key Actions
- **2026-10-26**: **BRANDED EMAIL REDESIGN (brianetole.com) & DESIGN PREVIEWS**:
  - Studied live `brianetole.com` design tokens: ink `#0a0c0d`, panel `#0f1213`, cream `#f3ead9`, ember accent `#ff6a1f`, muted `#a79f90`, font hierarchy, footer links, and social accounts.
  - Generated hosted icon assets in `assets/email/`: `logo.png`, `instagram.png`, `youtube.png`, `tiktok.png`, `linkedin.png`, `x.png`, `facebook.png`, `whatsapp.png`.
  - Built `BrandedEmailBuilder` supporting table-based email layouts, inline CSS, web-safe typography fallbacks, dark-mode compatibility, plain-text MIME alternative, and two design archetypes:
    - **Option 1 (The Dark Cinema Slate)**: Near-black header band `#0a0c0d`, BE monogram & tagline, 2px ember line, ivory message body, dark slate document summary card with amount due & M-Pesa/bank payment channels, signature as "Brian Etole · Hybrid Filmmaker · Photographer", and full brianetole.com dark footer with links and social icons.
    - **Option 2 (The Editorial Gallery)**: Warm cream letterhead, editorial typography, rate card summary table, and clean minimalist slate footer.
  - Added sample PDF generators for Invoice (`BE-INV-2026-004.pdf`) and Rate Card (`BE-RC-2026-RateCard.pdf`).
  - Added 1-tap live preview trigger controls in `GoogleEmailSettingsScreen`.
  - Compiled release APK, deployed to phone, and dispatched BOTH design options directly to `hello@brianetole.com`.
  - **GATE**: Paused to wait for user to inspect both emails live in Gmail and choose their preferred design before generating all templates and the new Send screen.

- **2026-10-26**: **GOOGLE SIGN-IN & GMAIL SEND INTEGRATION**:
  - Replaced legacy SMTP configuration with **"Sign in with Google"** OAuth flow.
  - Configured OAuth 2.0 client on Google Cloud project `Etole` (`com.brianetole.etole`) with production release key SHA-1 fingerprint (`0C:E8:16:C2:5F:93:D7:1B:CD:40:85:39:CB:9B:25:C6:1D:06:A8:AD`).
  - Restricted scope strictly to `https://www.googleapis.com/auth/gmail.send` (no inbox reading or personal data access).
  - Implemented secure token management in `google_auth_service.dart` using `FlutterSecureStorage` with silent sign-in and automatic OAuth token refresh.
  - Implemented RFC 822 MIME message formatting and direct Gmail API dispatch (`GmailSendService.sendEmail`) via `https://gmail.googleapis.com/upload/gmail/v1/users/me/messages/send?uploadType=media`.
  - Added new `GoogleEmailSettingsScreen` under `SettingsScreen` (Item `05 · EMAIL`) showing connected user profile picture, name, email (`hello@brianetole.com`), green connected status badge, "Send Test Email" action, and "Sign Out" flow.
  - Upgraded `SendDocumentEmailSheet` to automatically format the quotation/invoice PDF attachment, append professional email signature, send via Gmail API, and log the send action to document activity logs.
  - Implemented seamless fallback: if offline, session expired, or not signed in, offers "Sign in again" or "Open in Gmail / Email App" with the PDF pre-attached.
  - Completely purged legacy `SmtpSettingsScreen` from the application.
  - Verified compilation and built signed production release APK `build\app\outputs\flutter-apk\app-release.apk` (105.1 MB).
  - Streamed install succeeded to physical phone (`9dwonrnb7haasckj`) via USB debugging.

- **2026-10-18**: **PHASE 7 COMPLETE (World 4 — Settings: "The Workshop")**:
  - Implemented calm, minimal artist's notebook layout over dark obsidian background.
  - **Fixed `< HUB` Clearance**: Added dedicated 84px left spacer on the header row so the floating `< HUB` glass pill never collides with the page title.
  - **01-11 Numbered List**: Large Bebas Neue numerals in Ember Orange (`01` through `11`) with title, subtitle, right chevron, and hairline dividers.
  - Built dedicated clean sub-screens:
    - **`06 · APPEARANCE`**: Cinematic Dark / OLED Pitch Black / Warm Light mode switcher, Reduce motion toggle, Subtle ambient sound toggle (off by default), Startup launch target (Hub vs Digital Card).
    - **`07 · REMINDERS`**: Occasion lead days notice (1 day before default), morning alert delivery time (09:00 AM default), overdue document warning toggle.
    - **`09 · BACKUP`**: 100% offline-first storage architecture notice, export `.etole` backup archive and share sheet, SQLite database specifications (15 tables in `etole_db`).
    - **`11 · ABOUT`**: BE monogram mark, Etole suite manifesto, version `2.0.0+10` (5 taps unlocks Design System Gallery with feedback), Brian Etole contact channels (`+254 718 013 579`, `hello@brianetole.com`, `brianetole.com`, Nairobi, Kenya).
  - **Premium Details**: Restyled `EmptyStateWidget` to use delicate ink line-art aperture geometry (no big icon circles) and clean typography.
  - Rebuilt and signed release APK: `build\app\outputs\flutter-apk\app-release.apk` (Version `2.0.0+10`, 105.0 MB).
  - Streamed install succeeded to physical phone (`9dwonrnb7haasckj`).
  - Captured real device proof artifacts: `01_workshop_home.png` through `06_about_screen.png` and `workshop_walkthrough.mp4`.

- **2026-10-18**: **PHASE 6 COMPLETE (World 3 — Docs: Dark Glass Windows)**:
  - Replaced legacy paper stacks design with dark frosted glass window panes matching the Hub.
  - **Zero Blue Anywhere**: Purged all blue/teal icons, buttons, and chips across the application; strictly Ember Orange (`#FF6A1F`) and warm cream.
  - **Fixed `< HUB` Clearance**: Added dedicated 84px left spacer on Docs home so the floating Hub back button never collides with page headers.
  - **6.1 Docs Home**: Minimalist 3-card layout (`CONTACTS`, `RECENT DOCS`, `CREATE NEW`) with live glimpses and top search bar (number, client, item, amount).
  - **6.2 CONTACTS Window**: Alphabetical client directory, search, quick action pills (Call, WhatsApp, Email in ember), document history, "New document for this contact", and Delete to Trash with 30-day retention notice and instant Undo snackbar.
  - **6.3 RECENT DOCS Window**: Clean reverse-chronological list showing single-document amounts (no confusing sums), quiet type filter row (`ALL`, `QUOTATION`, `INVOICE`, `RECEIPT`, `RATE CARD`, `CONTRACT`), quiet status stamps (`PAID` in ember, `DRAFT`, `SENT`, `OVERDUE`, `CANCELLED`), and spring stamp conversion animations.
  - **6.4 CREATE NEW & Split Document Editor**: 5 glass window choices, live updating document preview sheet on top, scrolling form on bottom, currency switcher (`KES`, `USD`, `GBP`, `EUR`), Services library bottom sheet, 16% VAT toggle, 5% WHT toggle, deposit, signatures, attachments, and quiet autosave.
  - Rebuilt and signed release APK: `build\app\outputs\flutter-apk\app-release.apk` (Version `2.0.0+9`, 105.1 MB).
  - Streamed install succeeded to physical phone (`9dwonrnb7haasckj`).
  - Captured real device proof artifacts: `01_docs_home.png` through `10_undo_snackbar.png` and `docs_walkthrough.mp4`.
- **2026-10-18**: **PHASE 3 COMPLETE (The Hub & Shards Navigation)**:
  - Completely eliminated the old bottom navigation bar everywhere.
  - Implemented `LivingBackground` in `lib/features/hub/presentation/widgets/living_background.dart`:
    - 3-layer parallax architecture (`hub_back.webp`, `hub_mid.webp` with Screen blend, `hub_front.webp` with Screen blend) designed for zero-code replacement when final artwork is dropped in.
    - Motion sensor tilt parallax powered by `sensors_plus` with low-pass damping and touch-drag fallback.
    - Ambient time-of-day lighting (dawn amber, midday obsidian, sunset ember, night blue-black).
    - Drifting dust and glowing ember particle system.
    - Radial vignette gradient to ensure central shard readability.
    - Full "Reduce Motion" accessibility support (freezes drift and zeroes sensor shifts).
  - Implemented 4 floating broken glass shards in `ShardItem`:
    - Asymmetrical shattered polygon clipping (`ShardPolygonClipper`) in diamond layout.
    - Frosted glass blur (`sigma: 16`), 1px bright glint highlight border (`ShardBorderPainter`), and dropped soft shadow.
    - Independent floating sine wave motion per shard with unique phases.
    - Touch response: spring press scale (0.95), tilt toward touch, and light haptics (`EtoleHaptics.light()`).
    - Living glimpses: **BRIAN** (mini digital card with foil sheen & BE monogram), **NETWORK** (micro constellation with connected nodes), **DOCS** (crisp folded corner paper sheet with BE seal), **SETTINGS** (concentric engraved tribal dials).
    - Status notification dots: pulsing ember dot on `NETWORK` if occasion is scheduled today; on `DOCS` if document is overdue.
    - Connecting hairline crack fracture lines (`CrackLinesPainter`).
  - Implemented `WorldTransitionOverlay`:
    - Staggered vertical letter-by-letter reveal (`N · E · T · W · O · R · K`, etc.) with easeOutBack spring physics (< 700ms; tap to skip).
  - Implemented `WorldContainer`:
    - Wraps every world with top-left floating frosted glass shard pill ("← HUB"), top-edge swipe down exit, and predictive Android back interception returning to the Hub.
  - Added "Open App To" preference (Hub vs Digital Card) in Settings.
  - Verified 100% passing tests (`test/unit/hub_shards_test.dart` and suite: 13/13 passed).
  - Real high-DPI screenshots (`hub_dark_master.png`, `hub_light_master.png`, `hub_transition_letters.png`, `hub_world_entry.png`) and real screen recording (`hub_journey_recording.webp`) generated from running app.
- **2026-10-18**: Git checkpoint committed after system interruption (`12b82ec`).
- **2026-10-18**: **PHASE 1 APPROVED**:
  - Design gallery screen approved by user.
  - Offline fonts, `#0A0C0D` obsidian & `#FF6A1F` ember color system, no-box content styling, and component library.
  - Built comprehensive `lib/core/design_system/`:
    - `EtoleColors`: Near-black (`#0A0C0D`), cream text (`#F3EAD9`), muted text (`#A79F90`), ONE ember orange accent (`#FF6A1F`), low-opacity cream hairlines, warm off-white light mode (`#F9F7F2`).
    - `EtoleSpacing`: Strict scale (4, 8, 12, 16, 24, 32, 48, 64), 24dp screen gutters, 48dp minimum accessible tap targets.
    - `EtoleTypography`: Bold condensed uppercase display hierarchy, modern sans body, wide letterspaced labelCaps, tabular numbers.
    - `EtoleComponents`: Pill buttons (primary ember, outline, text), 1px hairlines, minimal underline inputs with ember focus, frosted glass pills, no-box list rows with leading indicators, letter-reveal titles, subtle film grain, haptic feedback triggers.
  - Built hidden Design Gallery screen (`SettingsScreen` &rarr; About &rarr; tap version 5 times) showcasing all 7 categories.
  - Unit tests verified passing (`test/unit/design_system_test.dart` and suite: 7/7 passed).
  - High-DPI real app captures generated in both Dark and Light mode (`design_gallery_dark.png`, `design_gallery_dark_components.png`, `design_gallery_dark_lists_glass.png`, `design_gallery_light.png`, `design_gallery_light_components.png`, `design_gallery_light_lists_glass.png`).

- **2026-10-17**: Project inspected. Git repository initialized. Committed baseline state `Before Etole simplification` (Commit `8a801b5`).
- **2026-10-17**: Completed Step 2 code cleanup: deleted 10 removed feature modules, refactored shell/navigation/trash/documents to 5 types, fixed all analyze errors to 0 warnings and 0 errors, committed `Step 2: Prune removed features and dead code` (Commit `04be21a`).
- **2026-10-17**: **CLEAN SLATE TRANSITION**:
  - Removed `legacy_archive_service.dart`, `tool/create_dev_backup.dart`, and backup files.
  - Switched application ID and namespace to `com.brianetole.etole` in `android/app/build.gradle.kts`.
  - Created new Android MainActivity under `android/app/src/main/kotlin/com/brianetole/etole/MainActivity.kt` and purged old package folder.
  - Built Clean Database Schema Version 1 in `app_database.dart` (`etole_db`), containing ONLY the 15 tables Etole needs.
  - Seeded initial Brian Etole data from `brianetole.com` (`hello@brianetole.com`, `+254 700 000 000`, `Nairobi, Kenya`, `REAL STORIES. IMAGINED WORLDS.`), leaving payment details blank for user entry.
  - Purged all BizDoc and Acious references from the codebase (hints, fallback strings, colors, storage keys, app title, and package name `etole`).
  - Regenerated Drift database code with `build_runner`.
- **2026-10-17**: **CORE FEATURE IMPLEMENTATION (Steps 4–8)**:
  - Created 5 East African tribal business card designs (`Ember`, `Savannah`, `Ochre Line`, `Night Market`, `Clay`).
  - Added tactile 3D drag tilt and dynamic specular light reflection to `BusinessCard3DFlipper`.
  - Implemented on-device OCR business card text recognition with `google_mlkit_text_recognition` in `BusinessCardOcrService`.
  - Built `CardOcrVerificationScreen` with interactive image zoom and token auto-assignment.
  - Built `NetworkHubScreen` uniting Occasions/Events and People/Leads with quick scan shortcuts and "Convert to Client" workflow.
  - Streamlined `document_detail_screen.dart` with 1-tap conversion (`Quotation` &rarr; `Invoice` &rarr; `Receipt`).
  - Cleaned up all analyzer warnings; verified `flutter analyze` passes cleanly.
- **2026-10-17**: **FINAL DELIVERY (Step 9)**:
  - Mastered app icon "The Cinematic Aperture Monogram" across all mipmap densities (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`), adaptive foreground, background `#0A0C0E`, and Android 13+ monochrome theming layer.
  - Regenerated `flutter_native_splash` with obsidian `#0A0C0E` branding.
  - Wrote and passed automated unit & smoke tests in `test/unit/` (4/4 passed).
  - Configured ML Kit R8 / ProGuard rules in `android/app/proguard-rules.pro`.
  - Successfully compiled and signed release APK: `build\app\outputs\flutter-apk\app-release.apk` (Version `2.0.0+2`, 105.4 MB) using production release key `android/app/bizdoc-release-key.jks`.
  - Produced `USER_GUIDE.md`, `CHANGELOG.md`, `test_report.md`, and `screens_preview.html`.
