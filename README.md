# Flutter OCR Document Scanner

A production-ready, offline-first Flutter application designed to scan documents, run OCR text recognition, auto-classify document types, parse structured data fields, and synchronize metadata (keeping images local for privacy and storage savings) to Cloud Firestore.

The project follows **Clean Architecture** principles and uses **Provider State Management**, **Firebase Authentication**, **Cloud Firestore**, and **Google ML Kit Text Recognition**.

---

## Key Features

### 🔐 Authentication Module
- **Splash Screen**: Evaluates the authentication session and redirects automatically.
- **Login & Signup Views**: Validates inputs, handles auth errors, and registers user profiles in Firebase Authentication and Firestore `users` collection.
- **Logout Action**: Clears local cached states and redirects to the Login screen.

### 📸 OCR Scanner Module
- **Camera & Gallery Sources**: Prompts runtime permissions gracefully using `permission_handler` and picks images using `image_picker`.
- **Image Cropping**: Refines scanning boundaries with interactive cropping grids via `image_cropper`.
- **Image Compression**: Reduces on-device storage footprint using `flutter_image_compress`.
- **Offline OCR**: Instantly extracts raw text from document captures offline using `google_mlkit_text_recognition`.

### 🏷️ Intelligent Document Classification
- **Scoring Engine**: Evaluates OCR text in real time using a weighted keyword and regular expression scoring engine.
- **Classifications Supported**: Auto-detects Invoices, Receipts, PAN Cards, Aadhaar Cards, Passports, Driving Licenses, Business Cards, Resumes, Utility Bills, and Bank Statements.

### 📊 Structured Data Extraction (Regex Parsers)
- Automatically parses and populates document-specific data fields:
  - **Invoice**: Invoice Number, Date, GSTIN, Vendor, Total, Tax, Customer
  - **Receipt**: Store, Date, Total, Items
  - **PAN**: Name, Father Name, DOB, PAN Number
  - **Aadhaar**: Name, DOB, Gender, Address, Aadhaar Number
  - **Passport**: Passport Number, Nationality, Expiry Date
  - **Driving License**: DL Number, Expiry, DOB
  - **Business Card**: Name, Email, Phone, Company, Website
  - **Resume**: Name, Email, Phone, Skills, Education, Experience
  - **Utility Bill**: Consumer Number, Bill Date, Amount, Due Date
  - **Bank Statement**: Account Number, Closing Balance, Statement Period

### 📝 Dynamic Document Editor
- Select/override the auto-detected Document Type.
- View and copy the raw OCR text via a collapsible expansion panel.
- Live-edit extracted keys and values, delete keys, and add or rename custom fields dynamically without key-collision typing bugs.

### 🔄 Offline-First Synchronization
- **Disk Cache**: Saves scanned documents immediately to disk as JSON files alongside cropped JPEG images.
- **Auto-Sync**: Listens to connection changes via `connectivity_plus`. Unsynced documents (`isSynced == false`) automatically sync metadata to Firestore once internet connectivity resumes.
- **Privacy & Storage Optimization**: Document images remain stored **strictly local** on the device, uploading only text metadata to Cloud Firestore.

---

## Project Structure

```text
lib/
├── core/
│   ├── routes/
│   │   └── app_routes.dart     # Routing mapping (Splash, Auth, Dashboard, Scan, Edit)
│   ├── theme/
│   │   ├── app_theme.dart      # Material 3 light/dark responsive theme
│   │   └── responsive.dart     # Responsive layout constraints helper
│   └── services/
│       └── exceptions.dart     # Custom exception wrapper classes
│
├── features/
│   ├── auth/
│   │   ├── models/
│   │   │   └── user_model.dart # User credentials data model
│   │   ├── services/
│   │   │   └── auth_service.dart # FirebaseAuth and profile Firestore helper
│   │   ├── viewmodels/
│   │   │   └── auth_viewmodel.dart # Auth session state ChangeNotifier
│   │   └── views/
│   │       ├── login_view.dart
│   │       ├── signup_view.dart
│   │       └── splash_view.dart
│   │
│   ├── documents/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── document_model.dart # Scanned document schema
│   │   │   │   └── document_type.dart  # Supported category enums
│   │   │   ├── repository/
│   │   │   │   └── document_repository.dart # Sync coordinator
│   │   │   └── services/
│   │   │       ├── local_document_service.dart # On-device JSON/JPEG caching
│   │   │       └── firestore_service.dart      # Firestore client wrapper
│   │   ├── provider/
│   │   │   ├── document_provider.dart # Search, filter, and sort state
│   │   │   └── sync_provider.dart     # Connectivity listener and background uploads
│   │   └── screens/
│   │       ├── dashboard_view.dart    # Searchable list dashboard
│   │       └── edit_document_view.dart # Custom field editor
│   │
│   └── ocr/
│       ├── provider/
│       │   └── ocr_provider.dart      # Image picker, crop/compress pipeline
│       ├── screens/
│       │   └── ocr_capture_view.dart  # Image capture selection screen
│       └── services/
│           ├── ocr_service.dart       # Offline Google ML Kit OCR service
│           ├── document_classifier.dart # Scoring engine
│           └── parsers/
│               ├── base_parser.dart   # Pattern matcher helpers
│               ├── invoice_parser.dart
│               ├── receipt_parser.dart
│               ├── pan_parser.dart
│               ├── aadhaar_parser.dart
│               ├── passport_parser.dart
│               ├── driving_license_parser.dart
│               ├── business_card_parser.dart
│               ├── resume_parser.dart
│               ├── utility_bill_parser.dart
│               └── bank_statement_parser.dart
│
└── main.dart                          # App initialization & provider bindings
```

---

## 🛠️ Firebase Setup Instructions

To bind the app to your Firebase project:

1. **Install Firebase CLI Tools & Login**:
   Ensure Node.js is installed, then run:
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Activate FlutterFire CLI**:
   Run:
   ```bash
   dart pub global activate flutterfire_cli
   ```

3. **Configure the Project**:
   From the root project directory, run:
   ```bash
   flutterfire configure
   ```
   Select your Firebase project and select platforms (Android, iOS). This automatically generates `lib/firebase_options.dart`, `google-services.json`, and `GoogleService-Info.plist`.

4. **Enable Firebase Products in Console**:
   Go to your [Firebase Console](https://console.firebase.google.com/):
   - **Authentication**: Enable the **Email/Password** sign-in method.
   - **Firestore Database**: Create your database.
     - *Deploy Rules*: Apply `firestore.rules` located in the project root to restrict user data access to document owners only.

---

## 📦 Run Locally

1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Verify static analysis:
   ```bash
   flutter analyze
   ```
3. Run unit tests:
   ```bash
   flutter test
   ```
4. Run the application:
   ```bash
   flutter run
   ```

---

## 🚀 APK Build Instructions

To compile a release Android APK:
```bash
flutter build apk --release
```

*Note: For Windows builds, if you encounter Kotlin daemon incremental cache file-locks, compilation in-process is enabled by default via `org.gradle.jvmargs` in `android/gradle.properties`.*
