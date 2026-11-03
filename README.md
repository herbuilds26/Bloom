# Bloom

Bloom is a Flutter starter implementation of a calm, privacy-conscious period and wellness tracker. The redesigned UI includes a local vector lily splash, five primary destinations (Home, Calendar, Add Entry, Assistant, Profile), a date-only cycle estimate, distinct logged and predicted calendar markers, mood and symptom entry controls, and neutral educational content.

## Current implementation status

- The current UI is a prototype: entries are held in memory and disappear when the app closes. Do not enter real sensitive health information until persistence and platform privacy controls have been implemented and reviewed.
- Firebase is not configured. Authentication, cloud sync, notifications, exports, app lock, and account deletion are not represented as working features.
- Android and iOS platform folders and Firebase native configuration should be generated/configured with FlutterFire on a machine with working Flutter/Dart and Firebase access.
- The calendar and cycle summary only use dates currently entered during the session. The current period-day control does not yet manage validated period episodes.
- Fertile-window and ovulation estimates are intentionally not shown. The assistant is rule-based educational content, not a chat service. Profile settings, partner connection, reminders, app lock and exports are visual placeholders.
- Prediction uses the median of valid intervals (15–90 days), requiring two intervals before history-based prediction; otherwise it uses an explicitly provided usual cycle length. It does not predict ovulation or fertility.

## Setup

1. Install a stable Flutter SDK and run `flutter pub get`.
2. Configure Android and iOS signing / minimum deployment targets as required by the selected FlutterFire plugin versions.
3. Create a Firebase project. Register the Android application ID and iOS bundle ID, then run FlutterFire CLI configuration to generate `lib/firebase_options.dart` for your project. Do not commit private service-account files.
4. Initialize Firebase in `main.dart` with the generated options; enable Email/Password in Firebase Authentication and publish `firestore.rules`.
5. Add App Check providers for release builds after configuring the corresponding Firebase console settings. App Check does not replace Firestore authorization.
6. Configure notification permission prompts and local scheduling only after the user opts into a reminder. Avoid sensitive content in notification text.

## Data and privacy

Use the authenticated UID as the root for all private records. Store local calendar dates as `YYYY-MM-DD` strings, not midnight UTC timestamps. Firestore server timestamps should be limited to audit fields. The included rules prevent cross-user access, but production rules should validate each collection's allowed field set/types and immutable fields before release. Firestore rules do not provide end-to-end encryption.

Before production, implement typed models and repository-backed persistence, offline/conflict semantics, data export and deletion, and tests against the Firebase Emulator. Never place health data in analytics or diagnostic logs. The current UI's settings text states its local prototype behavior honestly.

## Checks

Run `dart format lib test`, `flutter analyze`, and `flutter test` after package resolution. Add widget and emulator-backed integration tests before release.
