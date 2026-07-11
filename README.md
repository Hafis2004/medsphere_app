# 🏥 MedSphere — Doctor Telehealth App

[![Deploy to GitHub Pages](https://github.com/Hafis2004/medsphere_app/actions/workflows/deploy.yml/badge.svg)](https://github.com/Hafis2004/medsphere_app/actions/workflows/deploy.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.38.6-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A production-style Flutter telehealth application for doctors with Firebase authentication, appointment management, video-call UI, and session notes.

## 🌐 Live Demo

**[https://hafis2004.github.io/medsphere_app/](https://hafis2004.github.io/medsphere_app/)**

---

## ✨ Features

- 🔐 Doctor & Patient login with Firebase Authentication
- 📋 Dashboard with appointment status actions
- 📹 Video consultation UI using `flutter_webrtc`
- 📝 Firestore-backed session notes with add/edit/delete
- 👤 Profile and logout support
- 🎨 Responsive Material 3 UI with light/dark theming
- 🚀 Auto-deployed to GitHub Pages via GitHub Actions

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.38.6 / Dart 3.10.7 |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Video | flutter_webrtc |
| State | flutter_riverpod |
| Routing | go_router |
| CI/CD | GitHub Actions → GitHub Pages |

---

## 📦 Packages

- `firebase_core`, `firebase_auth`, `cloud_firestore`
- `flutter_webrtc`
- `flutter_riverpod`
- `go_router`
- `permission_handler`
- `intl`, `uuid`

---

## 📁 Project Structure

```
lib/
├── core/           # Shared infrastructure (constants, theme, services, router)
├── features/       # Auth, dashboard, notes, profile, video call screens
├── models/         # Domain objects (Doctor, Patient, Appointment, SessionNote)
├── repositories/   # Data access layer
└── widgets/        # Shared UI components
```

---

## 🚀 How to Run Locally

```bash
# 1. Clone the repo
git clone https://github.com/Hafis2004/medsphere_app.git
cd medsphere_app

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run

# 4. Build for web
flutter build web --release
```

---

## 🔥 Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com/)
2. Enable **Authentication** with Email/Password
3. Enable **Firestore Database**
4. Add Android / iOS / Web apps to the project
5. Download config files:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
   - Web: `lib/firebase_options.dart` (via FlutterFire CLI)
6. Run:
   ```bash
   flutterfire configure
   ```

---

## 🔑 Demo Credentials

| Role | Email | Password |
|------|-------|----------|
| Doctor | doctor@medsphere.app | doctor123 |

---

## 🧪 Testing Features

**Video Calling:**
- Run on two devices/emulators, sign in on both
- Open dashboard and start a video call from one instance
- Demonstrates camera/mic controls and call lifecycle UI

**Notes:**
- Open the Notes tab → Add title & description → Save / Edit / Delete

---

## 🔮 Future Improvements

- [ ] Real WebRTC signaling via Firestore
- [ ] Appointment scheduling with real-time patient updates
- [ ] Push notifications
- [ ] Unit & widget test coverage

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
