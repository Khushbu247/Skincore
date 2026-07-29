# SkinCore — Flutter Frontend

This is the frontend only (Phase 2–3 scaffold): theming, routing, and all main
screens (onboarding, login, home dashboard, skin scan flow, questionnaire,
recommendations, chatbot, progress tracker, settings). Screens use realistic
sample data locally — wiring to the FastAPI backend happens where marked
`TODO(Phase N)`.

## 1. Prerequisites

- Flutter SDK 3.22+ installed (`flutter --version` to check)
- Android Studio (for Android) and/or Xcode (for iOS, Mac only)
- A phone with **USB debugging enabled**:
  - Android: Settings → About phone → tap "Build number" 7x → Developer
    options → enable "USB debugging" → plug in via USB → accept the
    "Allow USB debugging?" prompt on the phone.
  - iOS: connect via USB, open Xcode once and trust the computer on the
    phone when prompted, then trust the device in Xcode's Devices window.

## 2. Turn this `lib/` + `pubspec.yaml` into a runnable project

This zip contains the Dart source only. Scaffold the platform folders first:

```bash
flutter create --org com.skincore --project-name skincore .
```

Run this **inside the `mobile/` folder** (where `pubspec.yaml` already is) —
it will generate `android/`, `ios/`, `web/` etc. around the existing `lib/`
and `pubspec.yaml` without overwriting them.

## 3. Install dependencies

```bash
flutter pub get
```

## 4. Connect Firebase (required — auth/scan/chat read `FirebaseAuth.instance`)

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Select/create a Firebase project, enable **Authentication → Email/Password**
and **Google Sign-In** in the Firebase console. This generates
`lib/firebase_options.dart` automatically — don't write it by hand.

## 5. Run on your USB-connected phone

```bash
flutter devices        # confirm your phone shows up
flutter run             # builds + installs + launches, with hot reload
```

Press `r` in the terminal for hot reload after editing a file, `R` for hot
restart.

## 6. What's real vs. sample data right now

| Screen | Status |
|---|---|
| Onboarding, theme, routing | Fully functional |
| Login (email/password + Google) | Fully functional (needs Firebase step above) |
| Home dashboard | UI complete, sample data (wire to `GET /recommendations`, scan history) |
| Skin scan | Real camera/gallery picker + upload UI; **analysis is simulated** (wire `POST /api/v1/scan/analyze`) |
| Questionnaire | UI complete; **submission not yet posted** to `POST /api/v1/questionnaire/submit` |
| Recommendations | UI complete, sample routine (wire to `GET /api/v1/recommendations`) |
| Chatbot | UI complete, **canned reply** (wire to `POST /api/v1/chatbot/message`) |
| Progress tracker | UI complete, sample chart data (wire to scan history) |
| Settings | Dark mode + logout fully functional |

Search the codebase for `TODO(Phase` to find every spot that needs a real API call.
