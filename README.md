# Notes Manager

A production-ready Flutter 3.x application called **Notes Manager** using **Provider State Management**, **Firebase Authentication**, and **Cloud Firestore** following **MVVM (Model-View-ViewModel)** architecture principles.

---

## Features

### 🔐 Authentication Module
- **Splash Screen**: Dynamic logo animations; determines current auth session and redirects automatically.
- **Signup View**: Includes validation for Full Name, Email, Password, and Confirmation. Automatically creates user profiles in Firebase Auth and stores details inside the Firestore `users` collection.
- **Login View**: Validates inputs, handles authentication errors with custom SnackBar alerts, and persists user sessions.
- **Logout Action**: Signs out from Firebase, resets local provider cache, and redirects to the Login screen.

### 📝 Notes CRUD Module
- **Dashboard View**: Shows user welcome greeting, real-time total notes count, search filtering, and responsive list/grid layout.
- **Add Note View**: Elegant notepad layout with mandatory title checks.
- **Edit Note View**: Pre-populates selected note details, processes Firestore document updates, and displays validation feedback.
- **Delete Action**: Prompts confirmation modal, clears notes in Firestore, and updates UI automatically in real-time.

---

## Project Structure (MVVM)

```text
lib/
├── core/
│   ├── constants/
│   │   └── theme.dart          # AppTheme configuration (indigo-violet responsive palette)
│   ├── routes/
│   │   └── app_routes.dart     # Navigation path routing & custom page transitions
│   ├── services/
│   │   └── exceptions.dart     # Custom exception wrapper classes
│   └── widgets/
│       ├── custom_text_field.dart  # Floating input, password toggles, validation
│       ├── loading_spinner.dart    # Custom SpinKit rings
│       └── primary_button.dart     # Gradient button layout with loading states
│
├── features/
│   ├── auth/
│   │   ├── models/
│   │   │   └── user_model.dart     # UserModel mapping
│   │   ├── services/
│   │   │   └── auth_service.dart   # FirebaseAuth & Firestore users integration
│   │   ├── viewmodels/
│   │   │   └── auth_viewmodel.dart # Session ChangeNotifier provider state
│   │   └── views/
│   │       ├── login_view.dart     # Credentials verification layout
│   │       ├── signup_view.dart    # Register user account layout
│   │       └── splash_view.dart    # Auth transition gateway
│   │
│   └── notes/
│       ├── models/
│       │   └── note_model.dart     # NoteModel and Timestamp mapping
│       ├── services/
│       │   └── notes_service.dart   # Firestore CRUD & Realtime Query snapshots
│       ├── viewmodels/
│       │   └── notes_viewmodel.dart# Notes stream, count, and action bindings
│       └── views/
│           ├── add_note_view.dart  # Create new notes
│           ├── dashboard_view.dart # Search query list/grid dashboard
│           └── edit_note_view.dart # Update notes
│
├── firebase_options.dart       # SDK settings configuration file
└── main.dart                   # Dependency injection configuration & app initialization
```

---

## 🛠️ Firebase Setup Instructions

The application is prepared for Firebase integration. To bind your own Firebase project:

1. **Install Firebase CLI Tools & Login**
   Make sure Node.js is installed, then execute:
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Activate FlutterFire CLI**
   Run the command below to enable global dart dependencies:
   ```bash
   dart pub global activate flutterfire_cli
   ```

3. **Configure the Project**
   Inside the root directory (`D:\Flutter Project`), run:
   ```bash
   flutterfire configure
   ```
   Follow the prompts to select your target platforms (Android, iOS, Web, macOS, Windows) and select/create your Firebase project. This command automatically generates the correct configuration inside [lib/firebase_options.dart](file:///D:/Flutter%20Project/lib/firebase_options.dart) and sets up native files (e.g. `google-services.json`, `GoogleService-Info.plist`).

4. **Enable Firebase Products in Console**
   Go to your [Firebase Console](https://console.firebase.google.com/):
   - **Authentication**: Enable **Email/Password** sign-in method.
   - **Firestore Database**: Create database in Test mode (or adjust rules to restrict reads/writes appropriately).
     - *Note on Rules*: Ensure that users can only read and write their own documents matching their `userId`.

---

## 📦 Run Locally

1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Launch target devices (emulators, mobile, desktop):
   ```bash
   flutter devices
   ```
3. Run the application:
   ```bash
   flutter run
   ```

---

## 🚀 APK Build Instructions

To build a release Android application package (APK):

1. **Verify setup compiles correctly**
   Ensure local builds compile with no errors:
   ```bash
   flutter analyze
   ```

2. **Generate Release App Bundle / APK**
   Run the Flutter build compile tool:
   ```bash
   flutter build apk --release
   ```
   For splitting app bundles by target CPU architectures (reducing downloaded sizes):
   ```bash
   flutter build apk --split-per-abi
   ```

3. **Output Directory**
   Upon success, the APK files will be located at:
   `build/app/outputs/flutter-apk/app-release.apk`
