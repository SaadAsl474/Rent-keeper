# RentKeeper Operational Precision — PowerShell Launcher
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "    Starting RentKeeper Operational Precision App     " -ForegroundColor Yellow
Write-Host "=======================================================" -ForegroundColor Cyan

$backendDir = Join-Path $PSScriptRoot "rentkeeper_backend"
Set-Location $backendDir

Write-Host "[1/2] Launching Dart Backend Server on http://localhost:8080..." -ForegroundColor Green
$serverJob = Start-Job -ScriptBlock {
    param($dir)
    Set-Location $dir
    dart run bin/server.dart --port=8080
} -ArgumentList $backendDir

Start-Sleep -Seconds 2

Write-Host "[2/2] Opening RentKeeper UI in browser..." -ForegroundColor Green
Start-Process "http://localhost:8080/"

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "App is live at: http://localhost:8080/" -ForegroundColor White
Write-Host "REST API docs:  http://localhost:8080/api/v1" -ForegroundColor White
Write-Host "Press Enter to stop the server..." -ForegroundColor Gray
Write-Host "=======================================================" -ForegroundColor Cyan

Read-Host
Stop-Job $serverJob | Out-Null
Remove-Job $serverJob | Out-Null
Write-Host "Server stopped." -ForegroundColor Red
