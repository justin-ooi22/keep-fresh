# FreshKeep — iOS Grocery Expiry & House Inventory Tracker

**FreshKeep** is an iOS application built with **SwiftUI**, **VisionKit**, and **UserNotifications** designed for homeowners with food stored across multiple rooms, refrigerators, freezers, and pantries.

---

## 🌟 Key Features

### 1. Smart Camera Scanning
- **Barcode Lookup**: Live barcode scanning with automatic product name, brand, and category recognition via the free Open Food Facts API.
- **On-Device Date OCR**: Apple `VisionKit` text recognition detects expiration stamps on packaging (`BB DD/MM/YY`, `EXP MM/YY`, `BEST BEFORE`, etc.) and automatically parses dates.
- **Manual Quick-Add**: Fast manual entry for fresh produce, bakery goods, and deli items without barcodes.

### 2. Multi-Alarm Expiration Notifications
- Set **multiple simultaneous alarms** per item:
  - 📅 **1 week before** (planning ahead)
  - ⚠️ **3 days before**
  - ⏳ **2 days before**
  - 🚨 **On the day itself**
- **Customizable Alert Time**: Receive daily alerts at your preferred hour (e.g. 9:00 AM).
- **Location-Aware Alerts**: Notifications state the item and its room location (e.g., *"Your Whole Milk in Kitchen Fridge expires in 2 days!"*).
- **5-Second Test Alert**: Tap "Send Test Notification" in Settings to verify alerts on your device.

### 3. House Storage Zones (For Large Homes)
- Track exactly where items are stored across your house:
  - 🧊 **Kitchen Fridge**
  - ❄️ **Kitchen Freezer**
  - 🥫 **Main Pantry**
  - 📦 **Garage Freezer (Deep / Chest Freezer)**
  - 🍷 **Basement Cellar / Storage**
  - 🍾 **Beverage Cooler**
- Add custom zones with unique names, SF Symbol icons, and color accents.
- Move items between rooms with one tap.

### 4. "Eat First" Urgent Shelf
- Dashboard prioritizes food nearing expiration so you always know what to cook or eat first.
- Traffic-light status badges:
  - 🔴 **Expired**
  - 🟠 **Use Urgently (≤ 2 days)**
  - 🟡 **Expiring Soon (3–7 days)**
  - 🟢 **Fresh (> 7 days)**

### 5. Native Light & Dark Mode
- Built according to Apple's Human Interface Guidelines (HIG).
- Seamless adaptive colors, elevated card surfaces, and support for system, light, or dark themes.

---

## 🚀 How to Open and Run in Xcode

1. Transfer or sync the project folder to your **MacBook** (e.g. via iCloud Drive, AirDrop, GitHub, or OneDrive).
2. Double-click **`FreshKeep.xcodeproj`** to open it in **Xcode**.
3. In Xcode:
   - Select your target device (e.g., **iPhone 15 / 16 Simulator** or your **connected physical iPhone**).
   - If running on a physical iPhone, go to **Signing & Capabilities** and select your Apple ID under "Team".
4. Press **Cmd + R** (or click the **Play** button) to build and run!

---

## 📁 Project Architecture

```
GroceryTracker/
├── GroceryTrackerApp.swift                 # App entry point & notification permission request
├── Models/
│   ├── GroceryItem.swift                  # Item model, expiry status & countdown logic
│   ├── StorageZone.swift                  # House rooms/zones, default presets & custom zones
│   ├── NotificationReminderOption.swift   # Multi-alarm options (1w, 3d, 2d, day-of) & date offsets
│   └── ItemCategory.swift                 # Grocery categories (Dairy, Produce, Meat, Frozen, etc.)
├── Services/
│   ├── InventoryStore.swift               # Observable state store with JSON persistence & sample data
│   ├── NotificationManager.swift          # UNUserNotificationCenter wrapper, multi-alarm scheduler
│   ├── DateParserService.swift            # OCR date parser for packaging text
│   └── OpenFoodFactsService.swift         # REST API barcode lookup service
├── Theme/
│   └── AppTheme.swift                     # Semantic colors, Light/Dark mode cards, status badges
├── Views/
│   ├── ContentView.swift                  # TabView with badge indicators
│   ├── Dashboard/
│   │   ├── DashboardView.swift            # Overview metrics, Eat First carousel, house rooms
│   │   └── ExpiringItemCard.swift         # Urgent card with countdown & one-tap "Eat" action
│   ├── Scanner/
│   │   ├── LiveScannerView.swift          # VisionKit DataScannerViewController wrapper
│   │   ├── ScannerContainerView.swift     # Viewfinder reticle, mode switcher, flashlight
│   │   └── AddEditItemView.swift          # Item review, zone assignment, multi-alarm selector
│   ├── Inventory/
│   │   ├── InventoryListView.swift        # Search, status filters, zone filters, sorting
│   │   ├── ItemDetailView.swift           # Item countdown, room reassign, scheduled alarms
│   │   └── ItemRowView.swift              # List row component
│   ├── Zones/
│   │   ├── ZonesListView.swift            # House rooms grid with item counts & next expiry
│   │   ├── ZoneDetailView.swift           # Items filtered to a specific room
│   │   └── AddEditZoneView.swift          # Custom room creator
│   └── Settings/
│       └── SettingsView.swift             # Alert hour, default alarm toggles, test notification
└── Resources/
    └── Info.plist                         # NSCameraUsageDescription & iOS capabilities
```
