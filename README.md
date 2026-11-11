# 🎨 Creative OS

> **Mobile Operating System for Creative Entrepreneurs, Filmmakers, Photographers & Independent Producers**

[![Build Creative OS APK](https://github.com/Acious7/Creative-OS/actions/workflows/build-apk.yml/badge.svg)](https://github.com/Acious7/Creative-OS/actions/workflows/build-apk.yml)
[![Release](https://img.shields.io/github/v/release/Acious7/Creative-OS?color=F59E0B&label=Download%20APK)](https://github.com/Acious7/Creative-OS/releases)

---

## 📲 Download the App

You can download and install the latest Android release APK directly:
👉 **[Download Creative OS APK](https://github.com/Acious7/Creative-OS/releases/latest)**

---

## ⚡ Core Capabilities

### 📍 1. Location-First Network Hub
- **Venue & Meeting Memory:** Everything is organized by the physical locations and events where you meet people (cafés, co-working spaces, shoot locations, studio lots).
- **Real Location Picker:** OpenStreetMap Photon autocomplete search, venue categories, 1-tap GPS geolocation, and 1-tap Google Maps navigation.
- **Two-Tier Notes:** Meeting recap for the entire session + personal notes for each contact.
- **Tasks & Reminders:** Assign tasks to locations or people with exact Android system alarm notifications.
- **Smart Follow-Up Actions:** 1-tap WhatsApp thank-you drafts, digital business card sharing, and instant quote generation.
- **Upcoming Meetups & Archive:** Schedule future meetups that auto-rollover to active places; searchable archive for past encounters.

### 💼 2. Freelance CRM & Sales Pipeline
- **Deal Stages:** Visual pipeline (*Inquiry ➔ Pitched ➔ Negotiation ➔ Won ➔ Lost*).
- **Live Revenue Tally:** Real-time revenue calculation in KES across pipeline stages.
- **1-Tap Quote Builder:** Convert any lead or deal into an official branded quotation with one tap.
- **VIP Rolodex:** Quick filter by VIPs, direct clients, and agencies with 1-tap Call and WhatsApp actions.
- **Follow-Up Radar:** High-priority deal reminders and promise tracking.

### 📑 3. Branded Documents Engine
- Professional Quotations, Invoices, Contracts, Receipts, and Rate Cards.
- Client PDF rendering, sharing, and print formatting.

### 💳 4. Digital Business Card
- 3D interactive business card flipper.
- Instant presentation via QR code, NFC, and vCard (.vcf) export.

### 🔒 5. Privacy & Offline-First
- 100% offline local SQLite database powered by Drift.
- Zero server dependency, zero subscription lock-in.

---

## 🛠️ Tech Stack

- **Framework:** Flutter 3.2+ / Dart
- **State Management:** Riverpod 2.5
- **Local Database:** Drift (SQLite)
- **CI/CD:** GitHub Actions (Automated release packaging)

---

## 🚀 Building from Source

```bash
git clone https://github.com/Acious7/Creative-OS.git
cd Creative-OS
flutter pub get
flutter build apk --release --target-platform android-arm64
```
