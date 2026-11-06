@echo off
setlocal
echo ========================================================
echo     RentKeeper Backend Server
echo ========================================================
echo.
cd /d "%~dp0"
echo Starting Dart backend on port 8080...
echo.
dart run server.dart
pause
