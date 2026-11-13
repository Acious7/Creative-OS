# Calendar Sync & Radar Module (`lib/core/calendar/`)

> [!NOTE]
> This module manages two-tier calendar integration for Etole Studio: zero-permission Android Intents (Tier A) and direct device calendar provider synchronization with schedule conflict detection (Tier B & C).

---

## 📅 Architectural Layers

```
lib/core/calendar/
├── calendar_models.dart         # DeviceCalendar and DeviceCalendarEvent data structures
├── calendar_intent_service.dart # Zero-permission Intent launcher via CalendarContract
├── calendar_sync_service.dart   # Direct SQLite provider sync & secure storage event memory mapping
└── README.md                    # Module documentation & permission flow
```

---

## ⚙️ How It Works

### Tier A: Zero-Permission Calendar Intent (`CalendarIntentService`)
* Uses native Android Intent with `CalendarContract.Events.CONTENT_URI`.
* Pre-populates title, start/end timestamps, location string, person notes, and an automatic 30-minute notification alarm.
* Operates with **zero permissions required**, delegating directly to Google Calendar or Samsung Calendar.

### Tier B: Direct Calendar Provider Sync (`CalendarSyncService`)
* Requires `READ_CALENDAR` and `WRITE_CALENDAR` permissions (configured in `CalendarSettingsScreen`).
* Silently queries local calendars (`getCalendars`).
* Maps internal reminder tasks to device `eventId` using `FlutterSecureStorage` (`cal_event_map_<id>`).
* Editing or deleting an in-app reminder or meetup automatically modifies or removes the entry in the phone's native calendar.
* Automatically falls back to Tier A if permissions are denied.

### Tier C: 7-Day Schedule Radar Strip (`calendar_seven_day_radar_strip.dart`)
* Read-only horizontal pill bar mounted on the Network Upcoming Meetups tab.
* Highlights booked vs free hours over the next 7 days to prevent double-booking.
* Tap on any day reveals a bottom sheet breakdown of events.
