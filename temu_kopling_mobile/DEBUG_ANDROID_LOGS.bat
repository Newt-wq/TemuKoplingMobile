@echo off
echo ========================================
echo  ANDROID LOGCAT - MAP DEBUGGING
echo ========================================
echo.
echo Filtering logs for: flutter, mapbox, tile errors
echo Press Ctrl+C to stop
echo.
echo ========================================
echo.

adb logcat | findstr /i "flutter mapbox tile TileLayer ERROR"
