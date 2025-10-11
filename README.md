# 🗺️ BOCK Map App – Frontend

This is the **main branch** for the Flutter frontend of the BOCK Map App, which displays maps and directions using data from OpenStreetMap.  
It serves as the stable branch that consolidates the **web**, **iOS**, and **Android** branches.

---

## 🌍 Overview
The app allows users to:

- View maps from OpenStreetMap
- Search for locations
- Get directions and route planning
- Save favorite locations
- Explore nearby points of interest
- Support for **Web**, **iOS**, and **Android** platforms

---

## 🌐 Branch Overview
| Branch   | Platform | Description |
|----------|---------|-------------|
| `main`   | All     | Stable release with tested features |
| `build-web`    | Web     | Flutter Web build |
| `build-ios`    | iOS     | Flutter iOS build |
| `build-android`| Android | Flutter Android build |

---

## 🧩 Tech Stack
- **Framework:** Flutter (Dart)  
- **Map Provider:** OpenStreetMap Data (Our custom API)  
- **Backend Connection:** REST APIs (Node.js / Express)  
- **Storage:** Shared Preferences  

---

## 🧱 Folder Structure
```
lib/
├── HomePage/
├── Profile/
├── SignupOrLogin/
└── main.dart
```

# ⚙️ Setup Instructions

## 1. Clone the repository
```
git clone https://github.com/<username>/<repo-name>.git
cd frontend
```

## 2. Install dependencies
```
flutter pub get
```

## 3. Run the app

### Web
```
flutter run -d chrome
```

### Android
```
flutter run -d android
```

### iOS
```
flutter run -d ios
```

## 5. Build for production

### Web
```
flutter build web
```
### Android
```
flutter build apk --release
```
### iOS
```
flutter build ios --release
```
