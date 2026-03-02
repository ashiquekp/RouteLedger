# RouteLedger 🚗📍

RouteLedger is a production-ready Flutter application for tracking, saving, replaying, and exporting GPS routes.  
Built with a scalable architecture, offline-first storage, and clean state management using Riverpod.

---

## ✨ Features

### 📍 Live Route Tracking
- Real-time GPS tracking
- Segmented polyline rendering
- Smooth camera follow
- Foreground service support
- Background-safe isolate initialization

### 🗺 Route History
- Persistent local storage using Hive
- Today / Yesterday smart labels
- Map preview with auto camera bounds
- Swipe-to-delete with confirmation & UNDO

### 📊 Trip Summary
- Distance calculation (Google Directions API)
- Duration tracking
- Average speed calculation
- Post-trip summary screen

### 🎬 Route Replay
- Smooth animated marker movement
- Interpolated polyline animation
- Camera follow during replay
- Auto-center after animation

### ✏️ Route Management
- Auto-generated route names
- Rename functionality with instant UI refresh
- Riverpod-based state synchronization

### 📤 Export & Sharing
- Share trip summary as text
- JSON export
- GPX file export (GPS device compatible)
- File sharing via share_plus

### 🎨 UI & UX
- Material 3 design system
- Light & Dark theme support (ThemeMode.system)
- Shimmer loading states (custom implementation)
- Hero transitions
- Micro-interactions & animations
- Production-level visual polish

### 🏗 Architecture
- Riverpod state management
- Offline-first architecture
- Hive local persistence
- Clean separation of UI & business logic
- Async enrichment using Google Directions API
- Provider-driven refresh logic (no navigation hacks)

---

## 🛠 Tech Stack

- Flutter
- Dart
- Riverpod
- Google Maps SDK
- Google Directions API
- Hive (local storage)
- share_plus
- Foreground service integration

---

## 📦 Production Considerations

- Secured API key handling
- Ordered runtime permission handling
- GPS & notification permission flow
- Background-safe entry points
- Clean provider invalidation architecture
- Lifecycle-aware refresh logic

---

## 📸 Screenshots

(Add screenshots here)

---

## 🚀 Future Improvements

- Cloud sync (Firebase / Supabase)
- Multi-device backup
- Trip categorization
- Route analytics dashboard
- Web dashboard support

---

## 👨‍💻 Developer

Built by Ashique KP  
Flutter Developer | Clean Architecture | Production-Ready Apps

---

## 📄 License

This project is for portfolio and demonstration purposes.
