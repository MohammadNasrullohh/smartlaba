# SmartLaba

SmartLaba adalah aplikasi kasir dan manajemen bisnis berbasis Flutter dengan dukungan mobile dan web. Project ini menggabungkan public landing page, login, workspace owner di web, alur operasional kasir di mobile, laporan bisnis, dan insight AI dalam satu codebase.

Live web: [https://smartlaba-app.web.app](https://smartlaba-app.web.app)

## Fitur Utama

- Public website untuk branding, informasi produk, login, dan tombol download aplikasi.
- Workspace owner di web untuk dashboard, manajemen produk, laporan, user, dan modul bisnis.
- Aplikasi mobile untuk operasional toko dan alur kasir.
- Login dengan email/password dan dukungan Google Sign-In.
- Firebase Auth, Cloud Firestore, dan Firebase Storage sebagai backend utama.
- Modul insight bisnis seperti analisis laba, prediksi, dan business health score.

## Platform

- Android
- Web
- Windows
- macOS
- Linux
- iOS

Catatan:
Role `Owner` mendapat akses penuh ke workspace web. Role `Kasir` diarahkan untuk memakai alur operasional melalui aplikasi mobile.

## Tech Stack

- Flutter
- Dart
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Google Fonts
- URL Launcher

## Struktur Singkat

```text
lib/
  main.dart                  -> entry point dan routing utama
  public_web_home_page.dart  -> homepage/public website
  web_admin_page.dart        -> workspace owner versi web
  dashboard.dart             -> dashboard aplikasi
  penjualan_page.dart        -> transaksi penjualan
  manajemen_produk_page.dart -> manajemen produk
  manajemen_user_page.dart   -> manajemen user
  business_ai_pages.dart     -> insight dan modul AI bisnis
  laporan_export_page.dart   -> laporan dan export
```

## Routing Penting

- `/` -> public web homepage
- `/login` -> halaman login
- `/app` -> gateway aplikasi setelah autentikasi
- `/workspace` -> workspace/admin gate
- `/terms` -> syarat dan ketentuan
- `/privacy` -> kebijakan privasi

## Menjalankan Project

### Prasyarat

- Flutter stable
- Dart SDK 3.8+
- Android Studio atau device Android
- Firebase project yang aktif

### Install dependency

```bash
flutter pub get
```

### Jalankan di Android

```bash
flutter run
```

### Jalankan di web

```bash
flutter run -d chrome
```

## Build

### Build APK

```bash
flutter build apk
```

Output APK umumnya ada di:

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/flutter-apk/app-debug.apk`

### Build Web

```bash
flutter build web
```

Output web ada di:

- `build/web`

## Deploy Web

Project ini sudah dikonfigurasi untuk Firebase Hosting.

```bash
firebase deploy --only hosting --project smartlaba-app
```

Konfigurasi hosting ada di:

- `firebase.json`

## Firebase Setup

Repository ini sudah menyertakan konfigurasi Firebase untuk environment yang sedang dipakai. Jika ingin memindahkan project ke Firebase milik sendiri, update file berikut:

- `android/app/google-services.json`
- `lib/firebase_options.dart`
- `firebase.json`

Biasanya alurnya:

```bash
flutterfire configure
```

## Pengembangan

Perintah yang sering dipakai:

```bash
dart format lib
dart analyze
flutter test
```

## Catatan Repo

- Public homepage sudah dioptimalkan agar lebih web-friendly untuk user umum.
- Tombol download aplikasi di web mengambil link dari pengaturan platform.
- Workspace web owner dibuat mengikuti modul utama yang sama dengan alur aplikasi mobile.

## Lisensi

Project ini saat ini belum menyertakan lisensi publik terpisah. Tambahkan file `LICENSE` jika repo ini ingin dibuka dengan lisensi tertentu.
