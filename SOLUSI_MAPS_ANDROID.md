# 🗺️ SOLUSI: Maps Tidak Muncul di Android (Tapi Muncul di Edge/Web)

## Status Masalah
- ✅ **Di Edge/Web Browser**: Maps **BISA** muncul dan render dengan baik
- ❌ **Di Android Device**: Maps **TIDAK** muncul / blank / tidak ke-render

## Diagnosis
Karena di web bisa tapi di Android tidak, berarti:
- ✅ **Code logic benar** (Flutter Map implementation sudah OK)
- ✅ **Mapbox token valid** (bisa akses tile server)
- ❌ **Android-specific configuration** yang bermasalah

---

## 🔧 Perbaikan yang Sudah Diterapkan

### 1. ✅ AndroidManifest.xml - Tambah Permissions
**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**Kenapa penting?**
- Flutter Map butuh download tiles dari Mapbox server via internet
- Tanpa permission INTERNET, tiles tidak bisa diakses

### 2. ✅ Network Security Config
**File Baru:** `android/app/src/main/res/xml/network_security_config.xml`

Memastikan koneksi HTTPS ke Mapbox API diizinkan di Android 9+

**File:** `android/app/src/main/AndroidManifest.xml`
```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    android:usesCleartextTraffic="false"
    ...>
```

### 3. ✅ MinSDK Version
**File:** `android/app/build.gradle.kts`

```kotlin
minSdk = 21  // Minimum untuk Flutter Map & Mapbox
```

Flutter Map butuh minimal Android 5.0 (API 21)

### 4. ✅ ProGuard Rules (untuk release build)
**File Baru:** `android/app/proguard-rules.pro`

Mencegah code shrinking menghapus class Flutter Map & Mapbox

### 5. ✅ Error Handling di TileLayer
**File:** `lib/screens/pages/tracking_page.dart`

Tambah error callback untuk debug:
```dart
TileLayer(
  urlTemplate: '...',
  errorTileCallback: (tile, error, stackTrace) {
    debugPrint('❌ Tile load error: $error');
  },
  tileProvider: NetworkTileProvider(),
)
```

---

## 🚀 Cara Menjalankan Fix

### Method 1: Gunakan Batch Script (TERMUDAH)
**Double-click file:** `QUICK_FIX_ANDROID_MAPS.bat`

Script akan otomatis:
1. ✅ Flutter clean
2. ✅ Flutter pub get
3. ✅ Cek devices
4. ✅ Build & run di Android

### Method 2: Manual via Terminal

```powershell
# Masuk ke folder project
cd "c:\Users\diena\Desktop\Temu Kopling\temu_kopling_mobile"

# WAJIB clean build (karena AndroidManifest berubah)
flutter clean

# Get dependencies
flutter pub get

# Cek device terkoneksi
flutter devices

# Run dengan verbose untuk lihat error details
flutter run --verbose

# Atau run biasa
flutter run
```

---

## 🔍 Debugging (Jika Masih Bermasalah)

### 1. Cek Device Terkoneksi
```bash
flutter devices
```

Harus ada device Android yang muncul. Jika tidak:
- Aktifkan USB Debugging di Android
- Atau gunakan Android Emulator

### 2. Monitor Real-time Logs
**Double-click file:** `DEBUG_ANDROID_LOGS.bat`

Atau manual:
```powershell
# Filter logs untuk map-related errors
adb logcat | findstr /i "flutter mapbox tile ERROR"
```

### 3. Test di Web dulu (Pembanding)
```bash
# Run di Edge
flutter run -d edge

# Atau Chrome
flutter run -d chrome
```

Jika di web bisa → confirm code logic OK → fokus ke Android config

### 4. Cek Error Messages Umum

**Error:** `Failed to load network image`
- ❌ Tidak ada INTERNET permission
- ✅ Sudah diperbaiki di AndroidManifest.xml

**Error:** `Unable to resolve host api.mapbox.com`
- ❌ Device tidak ada koneksi internet
- ✅ Cek WiFi/data mobile device

**Error:** `401 Unauthorized`
- ❌ Mapbox token expired/invalid
- ✅ Validasi token di browser

**Blank/White map tanpa error**
- ❌ Tiles butuh waktu download
- ✅ Tunggu 5-10 detik, coba zoom/pan map

---

## ✅ Validasi Success

Setelah `flutter run`, cek di device:

1. **Aplikasi terbuka tanpa crash** ✅
2. **Navigate ke halaman tracking** ✅
3. **Base map tiles muncul dalam 5-10 detik** ✅
   - Jalan/streets/buildings terlihat
   - Warna abu-abu (streets-v12 style)
4. **Marker kurir muncul** ✅
   - Lingkaran putih dengan logo brand
   - Segitiga pointing ke lokasi
5. **Titik biru lokasi user muncul** ✅
   - Jika GPS permission granted
6. **Map interaktif** ✅
   - Bisa zoom in/out (pinch)
   - Bisa pan/drag
   - Tap marker untuk detail

---

## 🎯 Checklist Sebelum Testing

- [ ] Device/emulator Android API 21+ (Android 5.0+)
- [ ] USB Debugging enabled (untuk physical device)
- [ ] Device terkoneksi internet (WiFi/mobile data)
- [ ] Flutter doctor tidak ada critical errors
- [ ] Sudah jalankan `flutter clean`
- [ ] Sudah jalankan `flutter pub get`
- [ ] Build dari scratch (bukan hot reload)

---

## 📝 Catatan Penting

### ⚠️ Hot Reload TIDAK Cukup!
Perubahan di `AndroidManifest.xml` TIDAK bisa di-hot reload.
WAJIB:
```bash
flutter clean
flutter run
```

### ⚠️ Mapbox Token Limits
Token gratis Mapbox:
- 50,000 tile requests per bulan
- Cukup untuk development
- Monitor usage di: https://account.mapbox.com/

### ⚠️ Test di Physical Device
Emulator kadang lambat render maps.
Physical device lebih akurat untuk test:
- GPS location
- Network speed
- Map rendering performance

---

## 🆘 Masih Bermasalah?

### Langkah Terakhir:

1. **Uninstall app di device**
```bash
adb uninstall com.example.temu_kopling_mobile
```

2. **Clean all caches**
```bash
flutter clean
```

3. **Reinstall from scratch**
```bash
flutter pub get
flutter run
```

4. **Validasi Mapbox Token di Browser**
```
https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/512/0/0/0?access_token=pk.eyJ1IjoicmxkeW5uIiwiYSI6ImNtajZvZTQ2djI1bXozZHNmeDBiNDZkcWYifQ.1UbeRwESrkwBdo5Jsg7gfA
```

Jika gambar tile muncul = token valid
Jika error 401 = token expired, buat baru di https://account.mapbox.com/

5. **Share error logs**
Run `DEBUG_ANDROID_LOGS.bat` dan screenshot error messages

---

## 📚 Referensi

- Flutter Map Docs: https://docs.fleaflet.dev/
- Mapbox Tiles API: https://docs.mapbox.com/api/maps/
- Android Permissions: https://developer.android.com/guide/topics/permissions/overview
- Network Security Config: https://developer.android.com/training/articles/security-config

---

**Good Luck! 🚀**

Jika semua langkah di atas sudah diikuti, maps harusnya muncul di Android!
