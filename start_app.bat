@echo off
echo =======================================================
echo     Starting RentKeeper Operational Precision App     
echo =======================================================
cd /d "%~dp0rentkeeper_backend"

echo [1/2] Launching Dart Backend Server on http://localhost:8080...
start /b "" dart run bin/server.dart --port=8080

timeout /t 2 /nobreak >nul

echo [2/2] Opening RentKeeper Dashboard in your browser...
start http://localhost:8080/

echo =======================================================
echo App is live at: http://localhost:8080/
echo REST API docs:  http://localhost:8080/api/v1
echo Press Ctrl+C in this terminal to terminate the server.
echo =======================================================
pause
