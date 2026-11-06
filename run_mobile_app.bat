@echo off
setlocal
title RentKeeper Mobile App Launcher
echo ========================================================
echo     RentKeeper Mobile App - Zero Backend Required
echo ========================================================
echo.

:: 1. Configure environment paths
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "ANDROID_HOME=C:\Users\MCS\AppData\Local\Android\Sdk"
set "ANDROID_SDK_ROOT=C:\Users\MCS\AppData\Local\Android\Sdk"
set "PATH=D:\Applications\flutter\bin;%JAVA_HOME%\bin;C:\Users\MCS\AppData\Local\Android\Sdk\platform-tools;C:\Users\MCS\AppData\Local\Android\Sdk\cmdline-tools\latest\bin;%PATH%"

cd /d "%~dp0rentkeeper_app"

echo [1/3] Checking dependencies...
call flutter pub get

echo.
echo [2/3] Detecting available devices...
call flutter devices

echo.
echo ========================================================
echo  Choose how to launch the RentKeeper Mobile App:
echo ========================================================
echo   [1] Run on connected Android Phone / Emulator (flutter run)
echo   [2] Run Mobile Preview in Chrome (flutter run -d chrome)
echo   [3] Run on Windows Desktop (flutter run -d windows)
echo   [4] Build Android APK to install on your phone
echo ========================================================
set /p choice="Enter option (1-4, default 1): "

if "%choice%"=="2" (
    echo Launching Mobile App in Chrome...
    call flutter run -d chrome
) else if "%choice%"=="3" (
    echo Launching on Windows Desktop...
    call flutter run -d windows
) else if "%choice%"=="4" (
    echo Building Android APK...
    call flutter build apk --debug
    if %errorlevel% equ 0 (
        echo.
        echo APK Created at: %~dp0rentkeeper_app\build\app\outputs\flutter-apk\app-debug.apk
        explorer /select,"%~dp0rentkeeper_app\build\app\outputs\flutter-apk\app-debug.apk"
    )
) else (
    echo Launching on default connected device...
    call flutter run
)

pause
