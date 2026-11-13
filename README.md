# 🎨 Creative OS

> **Sovereign Mobile Operating System for Creative Entrepreneurs, Filmmakers, Photographers & Independent Studios**
> Designed & Architected by **Brian Etole**

[![Build Creative OS APK](https://github.com/Acious7/Creative-OS/actions/workflows/build-apk.yml/badge.svg)](https://github.com/Acious7/Creative-OS/actions/workflows/build-apk.yml)
[![Release](https://img.shields.io/github/v/release/Acious7/Creative-OS?color=F59E0B&label=Download%20APK)](https://github.com/Acious7/Creative-OS/releases)

---

## 📲 Download the App

Download the latest verified Android release APK directly:
👉 **[Download Creative OS APK](https://github.com/Acious7/Creative-OS/releases/latest)**

---

## ⚡ Core Superpowers

### 🎬 1. Production Slate & Call Sheets
- **The Set:** Manage commercial shoots, documentary projects, and video productions.
- **Dynamic Call Sheets & Gear Manifests:** 1-tap call-sheet generation, crew availability WhatsApp blasts, and client delivery handover portals.

### 💳 2. 3D Digital Business Card & NFC Beam
- **Interactive 3D Perspective Tilt:** Gyroscope-responsive card with metallic sheen and Maasai bead geometries.
- **Physical NFC Encoding & vCard QR:** Instant beam to any smartphone without app install.
- **10-per-A4 Vector Print PDF:** Generate print-ready vector sheets with 3mm bleed and cut marks.

### 📍 3. Location-First Network Rolodex
- **Venue & Meeting Memory:** Organized by physical shoot locations, cafes, and creative festivals.
- **On-Device OCR Business Card Scanner:** Pinch-to-zoom card scanner with ML text extraction.
- **Smart Follow-Ups:** 1-tap WhatsApp thank-you drafts and instant client conversion.

### 📑 4. Branded Financial & Legal Engine
- **5 Essential Documents:** Quotations, Invoices, Receipts, Rate Cards, and Service Contracts.
- **Dynamic Numbering Sequence:** Fully customizable patterns (`{PREFIX}-{NUM}`, `{BRAND}-{YEAR}-{COUNT}`) with 1-tap in-line sequence editor.
- **Sequential 1-Tap Conversions:** Quotation ➔ Invoice ➔ Receipt with settlement tracking.

### 🧘 5. The Sanctuary & Dual Soundscapes
- **6 Focus & Rest Portals:** Stillness, The Forge (Pomodoro), Creative Vault, Reflections, Digital Sabbath, and Gratitude.
- **Dual Ambient Audio:** Rain on Zinc Roof and Acacia Winds with synchronized breathing rhythm.

### 🐕 6. Studio Watchdogs & Visual Recipe Builder
- **Autonomous Local Watchdogs:** Monitoring overdue debtors, KRA VAT/WHT tax escrow reserves, and weekly rolling encrypted backups.
- **Visual Custom Recipe Builder:** Build automated studio triggers and threshold alerts.

### 🎓 7. Studio Academy & Interactive Tour
- **12 Comprehensive Chapters:** Covering every module, gesture, and sovereign workflow.
- **Visual Interactive Walkthrough:** Guided onboarding with tactile haptic feedback.

---

## 👨‍💻 Creator & Architect

**Brian Etole**  
*Director, Cinematographer & Creative Technologist*  
- **Website:** [https://brianetole.com](https://brianetole.com)  
- **Email:** hello@brianetole.com  
- **WhatsApp:** +254 718 013 579  
- **Location:** Nairobi, Kenya  

---

## 🛠️ Tech Stack

- **Framework:** Flutter 3.2+ / Dart
- **State Management:** Riverpod 2.5
- **Local Database:** Drift (SQLite with WAL mode)
- **Local ML / Speech:** On-Device Whisper & Google ML Kit OCR
- **Audio:** Native Flutter Sound / Just Audio ambient synthesizers
- **CI/CD:** GitHub Actions (Automated release packaging)

---

## 🚀 Building from Source

```bash
git clone https://github.com/Acious7/Creative-OS.git
cd Creative-OS
flutter pub get
flutter build apk --release --target-platform android-arm64
```
