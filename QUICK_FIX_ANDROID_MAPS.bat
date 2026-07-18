@echo off
echo ========================================
echo  TEMU KOPLING - FIX ANDROID MAPS
echo ========================================
echo.

echo [1/5] Cleaning build cache...
call flutter clean
if errorlevel 1 (
    echo ERROR: Flutter clean failed!
    pause
    exit /b 1
)
echo ✓ Clean completed
echo.

echo [2/5] Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Flutter pub get failed!
    pause
    exit /b 1
)
echo ✓ Dependencies resolved
echo.

echo [3/5] Checking connected devices...
call flutter devices
echo.

echo [4/5] Building and running on Android...
echo NOTE: This will take a few minutes...
echo.
call flutter run --verbose
if errorlevel 1 (
    echo ERROR: Flutter run failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo  Build completed!
echo ========================================
pause
