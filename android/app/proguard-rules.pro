## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Mapbox & Flutter Map
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**

## WebView (jika dipake untuk map tiles)
-keep class android.webkit.** { *; }

## Network & HTTP
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

## Geolocator
-keep class com.baseflow.geolocator.** { *; }
