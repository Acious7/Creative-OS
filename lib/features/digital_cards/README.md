# Digital Cards & Network CRM Module (`lib/features/digital_cards/`)

> [!NOTE]
> Manages professional networking, business cards, venue discovery, contact OCR, and offline place cartography.

---

## 📱 Module Structure

```
lib/features/digital_cards/
├── domain/
│   ├── business_card_ocr_service.dart # On-device Google ML Kit text recognition & heuristic contact parser
│   ├── osm_location_service.dart      # OpenStreetMap Nominatim reverse geocoding & Photon venue search
│   ├── vcard_builder.dart             # Standard vCard generation for contact sharing
│   └── card_pdf_builder.dart          # Printable vector PDF export for digital cards
└── presentation/
    ├── screens/
    │   ├── network_hub_screen.dart       # Master network hub (Places, Deals, Rolodex, Radar)
    │   ├── card_presentation_screen.dart # Fullscreen digital card with NFC beaming & QR code
    │   ├── card_review_screen.dart       # Post-scan OCR review, deduplication, and photo storage
    │   └── location_detail_screen.dart   # Venue dossier with mini-map and Google Maps launch
    └── widgets/
        ├── osm_map_view.dart             # Interactive Web Mercator tile map with cache & offline grid
        ├── scan_business_card_sheet.dart # Card-shaped viewfinder camera overlay
        └── calendar_seven_day_radar_strip.dart # 7-day schedule conflict detection strip
```

---

## 🔍 Key Capabilities

1. **Location Auto-Pick (OpenStreetMap):**
   * Uses native GPS to acquire position.
   * Reverse-geocodes address via OpenStreetMap Nominatim and queries Photon for the 5 nearest venue names.
   * Adheres to OSM guidelines: 1 request/second rate-limiting, custom User-Agent, and client-side caching.
2. **On-Device Business Card Scanner (Google ML Kit):**
   * 100% on-device offline Latin OCR.
   * Parses Kenyan phone numbers (`+254`, `07xx`, `01xx`) and international numbers, emails, websites, job titles, and companies.
   * Reviews and prompts for duplicate resolution (*Merge* vs *Add New*).
   * Optional toggle to export directly to Android system contacts (`flutter_contacts`).
