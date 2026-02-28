# SOLARFIT ☀️

**SolarFit Scout** is the world’s first hardware-free, AI-powered solar validator that gives homeowners the 'Installer's Truth' in 30 seconds. It is a cross-platform app that helps homeowners instantly assess their solar potential using Google's most powerful developer and AI technologies.

---

## 🛠 Technical Architecture

The app follows a **Layered Service-Oriented Architecture**:

- **Presentation** (`screens/` + `widgets/`): Flutter + Material Design 3
- **State Management**: Provider pattern
- **Service Layer**: Isolated API clients (`solar_api_service`, `gemini_service`)
- **Utilities**: Cross-platform helpers for PDF, file system access

---

## 🚀 Google Technologies Used

| Technology | Role in App |
| :--- | :--- |
| **Flutter** | Cross-platform UI framework |
| **Gemini 2.5 Flash** | AI solar advisor & installer quote analyzer |
| **Google Solar API** | Roof insights, panel potential, production data |
| **Google Maps SDK** | Satellite map, 3D roof viewer, location search |
| **Firebase Auth** | Secure user authentication |
| **Cloud Firestore** | Cloud storage for analysis reports |
| **Firebase Storage** | Uploaded document & image hosting |

---

## 🧠 Implementation Highlights

### Google Gemini 2.5 Flash
- Generates plain-English explanations of complex solar data
- Parses uploaded installer quotes and flags pricing anomalies
- Powers the interactive solar consultation chat

### Google Solar API
- Fetches precise `buildingInsights` for any address worldwide
- Returns roof segments, max panel counts, and hourly sun data
- All metrics (savings, payback, profit) are derived from this data

### Cross-Platform PDF Export
- **Web**: Direct browser download via `dart:html` Blob + anchor click
- **Windows/Desktop**: Native "Save As" dialog via `file_picker`
- **Mobile**: Native share sheet via `share_plus`

---

## ⚙️ Challenges Overcome

### 1. Cross-Platform File Access
`path_provider.getTemporaryDirectory()` is unsupported on the web, crashing the PDF export. Solved with a **conditional import** pattern (`download_web.dart` / `download_stub.dart`) so each platform gets the right implementation.

### 2. PDF Font Unicode Support
The default Helvetica font in the `pdf` package does not support characters like `≈` and `•`. Solved by implementing a `_cleanText()` sanitizer that replaces all non-ASCII characters before generating the PDF.

### 3. API Response Null Safety
The Solar API returns deeply nested JSON with many optional fields. Solved using Dart's null-aware operators (`?.`, `??`) and defensive defaults across the `SolarApiService`.



