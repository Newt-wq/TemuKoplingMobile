# Fix Maps Tidak Muncul di Android

## Masalah
Maps tidak ter-render atau tidak terlihat saat aplikasi dijalankan di Android device/emulator.

## Penyebab Utama
1. **Missing INTERNET Permission** - AndroidManifest.xml tidak memiliki permission untuk mengakses internet
2. **Network Security Configuration** - Android 9+ (API 28+) membutuhkan konfigurasi tambahan untuk HTTP cleartext traffic
3. **Hardware Acceleration** - Mungkin tidak diaktifkan dengan benar
4. **Mapbox Token** - Token Mapbox di code perlu divalidasi

## Solusi yang Sudah Diterapkan

### 1. Menambahkan Internet Permissions
File `android/app/src/main/AndroidManifest.xml` sudah diupdate dengan:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

## Langkah-Langkah Perbaikan Tambahan

### 2. Pastikan Hardware Acceleration Aktif
Cek file `android/app/src/main/AndroidManifest.xml` di bagian `<activity>`:
```xml
android:hardwareAccelerated="true"
```
✅ Sudah ada di manifest Anda

### 3. Network Security Configuration (Opsional, jika masih error)
Jika Mapbox tiles tidak load, buat file `android/app/src/main/res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">api.mapbox.com</domain>
    </domain-config>
</network-security-config>
```

Kemudian tambahkan di `AndroidManifest.xml` dalam tag `<application>`:
```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

### 4. Validasi Mapbox Access Token
Token Mapbox di `lib/screens/pages/tracking_page.dart`:
```dart
urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/512/{z}/{x}/{y}?access_token=pk.eyJ1IjoicmxkeW5uIiwiYSI6ImNtajZvZTQ2djI1bXozZHNmeDBiNDZkcWYifQ.1UbeRwESrkwBdo5Jsg7gfA'
```

Pastikan token ini masih valid dengan cara:
1. Buka browser dan akses: https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/512/0/0/0?access_token=TOKEN_ANDA
2. Jika muncul gambar tile peta, token valid
3. Jika error 401, token tidak valid - buat token baru di https://account.mapbox.com/

### 5. Rebuild Aplikasi
Setelah perubahan AndroidManifest.xml, **WAJIB** rebuild aplikasi:
```bash
cd temu_kopling_mobile
flutter clean
flutter pub get
flutter run
```

### 6. Cek Logs untuk Debug
Jika masih tidak muncul, cek logs Android:
```bash
flutter run --verbose
```

Atau gunakan adb logcat:
```bash
adb logcat | findstr -i "flutter\|mapbox\|tile"
```

## Troubleshooting

### Maps Masih Blank/Putih?
1. **Cek koneksi internet** - Pastikan device/emulator terkoneksi internet
2. **Cek Mapbox token** - Validasi token masih aktif
3. **Cek console log** - Lihat error messages di Flutter console
4. **Tunggu loading** - Tiles butuh waktu untuk download pertama kali

### Error "Unable to load asset"?
- Bukan masalah maps, tapi masalah assets lain (gambar logo, dll)
- Cek `pubspec.yaml` untuk memastikan semua assets path benar

### Maps Muncul di iOS/Web tapi tidak di Android?
- Berarti masalah di Android-specific configuration
- Fokus di AndroidManifest.xml dan network security config

### Marker Muncul tapi Tiles Tidak?
- Masalah koneksi ke Mapbox API
- Cek token dan network connectivity

## Cara Test

### Langkah 1: Clean Build (WAJIB!)
```bash
cd "c:\Users\diena\Desktop\Temu Kopling\temu_kopling_mobile"
flutter clean
flutter pub get
```

### Langkah 2: Run di Android Device
```bash
# Pastikan device terkoneksi (cek dengan flutter devices)
flutter devices

# Run dengan verbose untuk lihat error
flutter run --verbose

# Atau run biasa
flutter run
```

### Langkah 3: Cek Logs Real-time
Buka terminal baru, jalankan:
```bash
# Windows PowerShell
adb logcat | Select-String -Pattern "flutter|mapbox|tile|TileLayer"

# Atau filter error saja
adb logcat *:E
```

### Langkah 4: Test di Browser (Pembanding)
```bash
# Jalankan di Edge/Chrome untuk compare
flutter run -d edge
# atau
flutter run -d chrome
```

**Jika di web (Edge) bisa tapi Android tidak:**
- ✅ Code logic benar
- ❌ Masalah di Android configuration
- Fokus ke: permissions, network config, minSdk

1. **Build dan Run**:
```bash
flutter clean
flutter pub get
flutter run
```

2. **Cek Device/Emulator**:
   - Buka aplikasi
   - Navigate ke halaman tracking
   - Maps harus muncul dalam 3-5 detik (tergantung koneksi)
   - Marker kurir (lingkaran dengan logo) harus terlihat
   - Titik biru lokasi user harus muncul

3. **Interaksi**:
   - Tap marker untuk buka detail panel
   - Pinch zoom untuk test zoom in/out
   - Pan map untuk test dragging

## Catatan Penting

- **Flutter Hot Reload tidak cukup** untuk perubahan AndroidManifest.xml
- **Wajib flutter clean + full rebuild** setelah edit manifest
- **Mapbox Token gratis** memiliki limit 50,000 requests per bulan
- **Test di device fisik** lebih akurat daripada emulator untuk GPS/maps

## Kontak & Referensi

- Flutter Map Documentation: https://docs.fleaflet.dev/
- Mapbox API: https://docs.mapbox.com/api/maps/
- Android Permissions: https://developer.android.com/guide/topics/permissions/overview
