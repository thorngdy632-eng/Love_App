# ភពមួយពីរនាក់ (Love App)

A private, romantic Flutter app for exactly two people. Built with Clean
Architecture, Material Design 3, Firebase (Auth, Firestore, Storage), and
Flutter Map + Geolocator — fully in Khmer, using the Kantumruy Pro font.

---

## 1. What's included

```
love_app/
├── lib/
│   ├── core/                # theme, constants (all Khmer strings live here), reusable widgets
│   ├── data/
│   │   ├── models/          # UserModel, MessageModel, NoteModel, MemoryModel, GalleryPhotoModel
│   │   └── repositories/    # Firebase Auth / Firestore / Storage / Geolocator access
│   └── presentation/
│       ├── auth/            # Login screen + AuthProvider + AuthWrapper
│       ├── main/            # Bottom nav shell + Drawer + NavController
│       ├── home/             ┐
│       ├── map/               │
│       ├── time_together/     ├─ the 5 bottom-nav tabs
│       ├── messages/          │
│       ├── profile/          ┘
│       ├── notes/           # Drawer: Notes
│       ├── memories/        # Drawer: Memories
│       ├── gallery/         # Drawer: Gallery
│       ├── settings/        # Drawer: Settings
│       └── about/           # Drawer: About
├── android/                 # Android project (Gradle, Kotlin, manifest, launcher icons)
├── ios/                     # iOS Runner essentials (Info.plist, AppDelegate.swift, Podfile)
├── firestore.rules          # Firestore security rules (only the 2 authorized emails)
├── storage.rules            # Firebase Storage security rules
└── pubspec.yaml
```

### Feature-by-feature summary

| Feature | Implementation |
|---|---|
| Login | Email **or** phone number + password, Firebase Auth, hard-restricted to the 2 authorized accounts (anyone else is rejected with a Khmer message) |
| Home | Live day-counter, next-anniversary countdown, quick-access cards |
| Map | `flutter_map` + OpenStreetMap tiles, `geolocator` live position stream, both users' markers, route line, live distance, "Directions" button opens Google Maps |
| Time Together | Live years/months/days/hours/minutes/seconds counter + countdown to next anniversary |
| Messages | Realtime Firestore chat, text + images. **Chat images are Base64-encoded and stored directly inside the Firestore message document**, exactly as specified |
| Profile | Change photo (uploaded to Firebase **Storage**), edit bio, view name/phone/email |
| Notes | Full CRUD on shared notes (Firestore) |
| Memories | Add a memory (photo → Firebase Storage + title/description/date), realtime list, delete |
| Gallery | Shared photo grid (Firebase Storage), tap to view full-screen/zoom, long-press to delete |
| Settings | Notification & dark-mode toggles (persisted with `shared_preferences`), change password (Firebase re-auth) |
| About | App description |
| Drawer | Home, Notes, Memories, Gallery, Settings, About, Logout (with confirmation) |

> Note on Firebase Storage vs Base64: the spec explicitly asks for chat
> images to be Base64-encoded into Firestore — that's implemented exactly
> as written. Profile photos, Memories, and Gallery photos use real Firebase
> Storage uploads (returning a download URL) since that's the correct,
> scalable pattern for larger/more numerous images and the spec also asks
> the app to use Firebase Storage.

---

## 2. Prerequisites

- Flutter SDK (stable channel, 3.24+) — https://docs.flutter.dev/get-started/install
- Dart 3.3+
- Android Studio (for Android SDK + emulator) and/or Xcode 15+ (for iOS, macOS only)
- A Firebase project (free Spark plan is enough to start)
- Node.js (only needed if you want to use the Firebase CLI to deploy security rules)

Check your setup:
```bash
flutter doctor
```

---

## 3. Firebase setup (step by step)

### 3.1 Create the Firebase project
1. Go to https://console.firebase.google.com → **Add project** → name it (e.g. `love-app`) → finish the wizard.

### 3.2 Register your apps
1. In the Firebase console, click the **Android icon** to add an Android app.
   - Package name: `com.example.love_app` (must exactly match `android/app/build.gradle` → `applicationId`, or change both to match your own).
   - Download the generated **`google-services.json`** and replace the placeholder at:
     `android/app/google-services.json`
2. Click the **Apple icon** to add an iOS app.
   - Bundle ID: `com.example.loveApp` (must match the iOS bundle identifier you set in Xcode).
   - Download **`GoogleService-Info.plist`** and replace the placeholder at:
     `ios/Runner/GoogleService-Info.plist`
   - In Xcode, drag this file into the `Runner` target (make sure "Copy items if needed" is checked).

### 3.3 Generate `firebase_options.dart` (recommended, easiest)
Instead of manually editing `lib/firebase_options.dart`, use the FlutterFire CLI to generate it correctly for all platforms in one go:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
Follow the prompts, select your Firebase project, and select Android + iOS. This overwrites `lib/firebase_options.dart` with real values and can also (re)download the two config files above.

### 3.4 Enable Authentication
1. Firebase Console → **Build → Authentication → Get started**.
2. Enable the **Email/Password** sign-in provider.
3. Go to the **Users** tab → **Add user** → create exactly these two accounts:

   | Email | Password |
   |---|---|
   | thorngdy@gmail.com | thorngdy@123 |
   | seavenh@gmail.com | seavenh@123 |

   (Phone-number login is handled purely in-app: typing either registered
   phone number `067267968` / `086514169` resolves to the matching email
   before calling `signInWithEmailAndPassword`, so you do **not** need to
   set up Firebase Phone Auth/SMS.)

### 3.5 Enable Cloud Firestore
1. Firebase Console → **Build → Firestore Database → Create database** → start in **production mode** → pick a region.
2. Go to the **Rules** tab and paste the contents of `firestore.rules` from this project, then **Publish**.
   (Or deploy via CLI: `firebase deploy --only firestore:rules`.)

### 3.6 Enable Firebase Storage
1. Firebase Console → **Build → Storage → Get started** → production mode.
2. Go to the **Rules** tab and paste the contents of `storage.rules`, then **Publish**.

### 3.7 (Optional but recommended) Lock things down further
Because this app is meant for exactly two specific people, the Firestore/Storage
rules already check `request.auth.token.email` against the two allowed
addresses — so even a leaked API key can't be used to read/write your data
without also having valid credentials for one of the two accounts.

---

## 4. Project setup

```bash
# 1. Unzip / clone the project, then from the project root:
cd love_app

# 2. Get packages
flutter pub get

# 3. (If you haven't already) generate firebase_options.dart
flutterfire configure

# 4. Run it
flutter run
```

### Android-only permission note
All required permissions (Internet, Location, Camera, Photos) are already
declared in `android/app/src/main/AndroidManifest.xml`. On first launch the
app will prompt the user for location and photo permissions as needed
(handled by `geolocator` and `image_picker`).

### iOS-only setup note
1. Open `ios/Runner.xcworkspace` in Xcode (after running `flutter pub get`
   at least once, and `pod install` inside `ios/` if needed).
   - If `ios/Runner.xcworkspace` doesn't exist yet because this project was
     unzipped fresh, run `flutter create .` once from the project root —
     this safely (re)generates the Xcode project files (`.xcodeproj`,
     `.xcworkspace`, storyboards, asset catalogs) without touching any of
     your Dart code. Then re-apply/keep the customized files already
     included here: `Info.plist`, `AppDelegate.swift`, `Podfile`,
     `GoogleService-Info.plist`.
2. Set your Team/Signing in Xcode (Runner target → Signing & Capabilities).
3. Info.plist already includes the Khmer permission strings for Location,
   Photo Library, and Camera.
4. Minimum iOS deployment target is **15.0** (required by current Firebase
   iOS SDKs).

---

## 5. Editing the relationship start date

Open `lib/core/constants/app_constants.dart` and change:
```dart
static final DateTime relationshipStartDate = DateTime(2022, 2, 14, 0, 0, 0);
```
to your actual anniversary date/time. This single value drives both the
Home dashboard and the Time Together tab.

---

## 6. Build instructions

### Android — release APK
```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

### Android — release App Bundle (for Play Store)
```bash
flutter build appbundle --release
# output: build/app/outputs/bundle/release/app-release.aab
```
> Before publishing, replace the debug signing config in
> `android/app/build.gradle` (`signingConfig signingConfigs.debug`) with
> your own release keystore signing config.

### iOS — release build
```bash
flutter build ios --release
# then open ios/Runner.xcworkspace in Xcode to Archive & upload to
# TestFlight / App Store Connect.
```

---

## 7. Data model (Firestore collections)

| Collection | Document ID | Purpose |
|---|---|---|
| `users` | user's email (e.g. `thorngdy@gmail.com`) | profile, bio, live location, online status |
| `chats/couple_chat_room/messages` | auto-id | chat messages (text or Base64 image) |
| `notes` | auto-id | shared notes |
| `memories` | auto-id | shared memories (photo + title + description + date) |
| `gallery` | auto-id | shared photo gallery |

> **Why email instead of Firebase Auth UID as the identity key?** Firebase
> Auth UIDs are auto-generated per-project and can't be forced to a fixed
> value from the client SDK. Since this app only ever has two fixed users,
> their email address is used as the stable identity key everywhere
> (`senderId`, `authorId`, `uploaderId`, and the `users` document ID) — this
> keeps the security rules simple and avoids any UID/lookup mismatch.

---

## 8. Troubleshooting

- **"MissingPluginException" on first run** → run `flutter clean && flutter pub get` and restart the app (not just hot-reload).
- **Login always says unauthorized** → double check the two accounts exist in Firebase Authentication with the exact emails/passwords above, and that Email/Password sign-in is enabled.
- **Map is blank / no tiles** → check internet connectivity; tiles are fetched live from `tile.openstreetmap.org`.
- **Location permission errors on Android 13+** → make sure you accepted both "While using the app" location and, if prompted, background location.
- **iOS build fails on pod install** → run `cd ios && pod repo update && pod install`.

---

Made with 💕 for exactly two people.
"# Love_App" 
