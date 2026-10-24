@echo off
setlocal
echo ========================================================
echo     RentKeeper Operational Precision - APK Builder
echo ========================================================
echo.

:: 1. Set environment paths
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "ANDROID_HOME=C:\Users\MCS\AppData\Local\Android\Sdk"
set "ANDROID_SDK_ROOT=C:\Users\MCS\AppData\Local\Android\Sdk"
set "PATH=D:\Applications\flutter\bin;%JAVA_HOME%\bin;C:\Users\MCS\AppData\Local\Android\Sdk\platform-tools;C:\Users\MCS\AppData\Local\Android\Sdk\cmdline-tools\latest\bin;%PATH%"

echo [1/3] Environment configured:
echo   • Flutter SDK:    D:\Applications\flutter
echo   • Java (OpenJDK): %JAVA_HOME%
echo   • Android SDK:    %ANDROID_HOME%
echo.

cd /d "%~dp0rentkeeper_app"

echo [2/3] Checking Flutter dependencies...
call flutter pub get

echo.
echo [3/3] Compiling Android APK (Debug Build)...
call flutter build apk --debug

if %errorlevel% equ 0 (
    echo.
    echo ========================================================
    echo  SUCCESS: RentKeeper APK created successfully!
    echo ========================================================
    echo  Output Location:
    echo  %~dp0rentkeeper_app\build\app\outputs\flutter-apk\app-debug.apk
    echo ========================================================
    
    :: Open folder in Explorer
    explorer /select,"%~dp0rentkeeper_app\build\app\outputs\flutter-apk\app-debug.apk"
) else (
    echo.
    echo ========================================================
    echo  Build paused or encountered an error.
    echo  Ensure internet connection is active for Gradle packages.
    echo ========================================================
)

echo.
pause
