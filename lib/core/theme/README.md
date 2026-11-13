# Central Theme Engine (`lib/core/theme/`)

> [!NOTE]
> The theme engine controls all visual styling across Etole Studio: floating broken-glass window tints, tribal sketch lighting, living ambient canvas shaders, and real-time palette switching.

---

## 🎨 Theme Architecture

```
lib/core/theme/
├── studio_theme.dart          # StudioThemeId enum and StudioThemeData styling specification
├── brand_theme_provider.dart  # Riverpod StateNotifier, preference persistence & system dark sync
├── studio_theme_provider.dart # Central export bridge
└── README.md                  # Theme design guidelines and color specifications
```

---

## 🌌 The 4 Studio Themes

| Theme ID | Name | Background Tint | Accent | Aesthetic Intent |
| :--- | :--- | :--- | :--- | :--- |
| `tribalOrange` | **Tribal Orange (Default)** | Obsidian Velvety Black (`#0B0E12`) | Sunset Amber (`#FF7A00`) | Iconic look of `brianetole.com` |
| `nightWarrior` | **Night Warrior** | Deep Charcoal (`#090C0F`) | Warrior Orange (`#FF5722`) | High-contrast nocturnal intensity |
| `savannahLight`| **Savannah Light** | Warm Cream (`#F7F4EE`) | Terracotta (`#C2410C`) | Sunlight through African savannah |
| `nairobiNeon`  | **Nairobi Neon** | Midnight Navy (`#060B14`) | Electric Cyan (`#00F0FF`) | High-tech East African metropolis |

---

## 🛡️ Theme Isolation Rules
1. **Digital Business Card:** Retains its iconic orange tribal sketch styling by default, unless the user toggles *"Match card to theme"* in Settings > Appearance.
2. **Docs & Client Deliverables:** Official PDF quotations, contracts, and email dispatches are strictly brand-isolated and never alter with themes.
3. **Instant Swapping:** Theme choices apply instantaneously via Riverpod without requiring an application restart.
