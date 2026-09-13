# ConnectCall

A 1-to-1 audio/video calling app built with Flutter - Flutter Development Intern assignment.

## Description

ConnectCall lets registered users see who else is on the app, place real audio/video calls with an incoming-call Accept/Decline screen, and review their call history (completed / missed / rejected). Auth and data live in Firebase; calling is powered by the ZEGOCLOUD Flutter UIKit prebuilt widgets (no raw WebRTC).

## Feature list

1. Splash screen that checks `FirebaseAuth.instance.currentUser` and routes to Login or Home.
2. Login (email/password) and Register (name, email, password, confirm password). Register writes `users/{uid}` = `{name, email, online: true, createdAt}`.
3. Home/Contacts: live `users` collection list of every other registered user - avatar placeholder, name, online/offline dot, per-row audio-call and video-call buttons.
4. Real 1-to-1 calls via ZEGOCLOUD prebuilt call widget + invitation service: the receiver gets a real incoming-call screen with Accept/Decline; both sides get mute, speaker toggle (audio) / camera on-off + camera switch (video), and end-call.
5. Call history written on call end to `callHistory/{uid}/records` = `{otherUserName, type: audio|video, timestamp, durationSeconds, status: completed|missed|rejected}`, listed newest-first with a missed-call indicator.
6. Profile screen: name/email/online status, edit-profile action, logout button.
7. Permissions via `permission_handler` (mic for audio, mic+camera for video) with a simple denial dialog.
8. All Firebase/Firestore calls wrapped in try/catch with SnackBar feedback.
9. Loading and empty states on contacts ("No contacts yet") and history ("No calls yet").

## Flutter version used

- Flutter **3.47.2** (stable) - Dart **3.13.2**

## Packages (resolved versions)

| Package | Version |
|---|---|
| provider | 6.1.5+1 |
| firebase_core | 3.15.2 |
| firebase_auth | 5.7.0 |
| cloud_firestore | 5.6.12 |
| zego_uikit | 2.29.2 |
| zego_uikit_prebuilt_call | 4.24.4 |
| zego_uikit_signaling_plugin | 2.8.21 |
| permission_handler | 12.0.3 |
| cupertino_icons | 1.0.9 |

## Architecture

- `lib/core/` — `constants.dart` (collection names, routes, Zego AppID/AppSign), `theme.dart`.
- `lib/models/` — `AppUser` (mirrors `users/{uid}`), `CallRecord` (mirrors `callHistory/{uid}/records`).
- `lib/services/` — `AuthService` (Firebase Auth + user-doc writes), `UserService` (users stream/presence/profile), `CallHistoryService` (history log + stream), `ZegoService` (owns `ZegoUIKitPrebuiltCallInvitationService`: init/uninit, permission gating, history logging from call/invitation events).
- `lib/providers/` — `AuthProvider`, a `ChangeNotifier` wrapping `AuthService` (the app's single Provider).
- `lib/screens/` + `lib/widgets/` — splash / auth / home (bottom nav: Home, Contacts, Calls, Profile) / contacts / history / profile, plus `UserTile` (row with the two Zego invite buttons) and `CommonButton`.
- Call flow: login (or cold-start auth listener) → `ZegoService.init(uid, name)` → `ZegoSendCallInvitationButton` sends the invite → receiver's invitation service shows Accept/Decline → `onCallEnd` logs `completed` for both sides; decline/timeout callbacks log `rejected`/`missed`.

## Backend and calling SDK

- **Backend: Firebase** (Auth email/password + Cloud Firestore) — one line: it covers auth, user directory, presence, and history with zero custom server code, per the assignment constraints.
- **Calling SDK: ZEGOCLOUD Flutter UIKit (`zego_uikit_prebuilt_call` + `zego_uikit_signaling_plugin`)** — one line: its prebuilt call widget + invitation service deliver real calls with incoming-call UI and in-call controls without writing raw WebRTC/signaling.

## Setup instructions

### Firebase project
1. Create a project at https://console.firebase.google.com.
2. Enable **Authentication → Email/Password**.
3. Create a **Cloud Firestore** database (test mode is fine for this assignment).
4. Add an Android app with package name `com.example.connect_call`; download `google-services.json` into `android/app/`.
5. Install the CLI and configure (overwrites `lib/firebase_options.dart` with real keys):
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

### ZEGOCLOUD AppID / AppSign
1. Create an account/project at https://console.zegocloud.com (Voice/Video Call type, AppSign auth mode).
2. Paste the values into `lib/core/constants.dart`:
   ```dart
   static const int zegoAppID = 1234567890;
   static const String zegoAppSign = 'your appsign';
   ```

### Run / build
```
flutter pub get
flutter run            # needs 2 devices/emulators with 2 accounts to test calls
flutter build apk --release   # output: build/app/outputs/flutter-apk/app-release.apk
```

Firestore rules note: test-mode rules (allow read/write when authenticated) are sufficient for this assignment.

## Known limitations (out of scope, not built)

- Add-contact-by-phone-number or device contact sync.
- Dark mode.
- Push notifications / background/killed-state call notifications.
- Group calling.
- Screen sharing.
- Network quality indicator.
- Offline caching (Hive) or any custom backend beyond Firebase.

## AI disclosure

AI tools (Claude, via Muse Spark) were used in development.

## Demo
<img width="720" height="1600" alt="WhatsApp Image 2026-09-13 at 9 09 04 PM" src="https://github.com/user-attachments/assets/29b908cf-3eab-4dd9-9d9a-41bea06d188e" />
<img width="1080" height="2400" alt="WhatsApp Image 2026-09-13 at 9 09 03 PM" src="https://github.com/user-attachments/assets/90fd3049-e787-43c0-a6ff-c4cff853b291" />
<img width="720" height="1600" alt="WhatsApp Image 2026-09-13 at 9 09 03  1" src="https://github.com/user-attachments/assets/13f0e461-4d9d-4cb0-82a7-1cace5380d50" />
<img width="746" height="1600" alt="WhatsApp Image 2026-09-13 at 9 02 20 PM" src="https://github.com/user-attachments/assets/6a6aeb1d-e12c-4c83-844d-cf9f59403d10" />

## APK Link
https://github.com/Vineetagrawal2005/Connect_Call/releases/tag/v1.0.0

#
