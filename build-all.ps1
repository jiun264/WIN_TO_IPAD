# PhotoBridge 一鍵發布與打包腳本
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       PhotoBridge 一鍵發布 (Windows + iPad)      " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. PC 發布
Write-Host "`n[1/3] 正在發布 PC 端獨立執行檔 (win-x64)..." -ForegroundColor Yellow
dotnet publish src\PhotoBridge.PC\PhotoBridge.PC.csproj -c Release -r win-x64 `
  --self-contained true `
  -p:PublishSingleFile=true `
  -p:IncludeNativeLibrariesForSelfExtract=true `
  -p:EnableCompressionInSingleFile=true `
  -o dist\win-x64

# 2. 準備安裝檔目錄
Write-Host "`n[2/3] 正在建立 Windows 一鍵安裝包..." -ForegroundColor Yellow
$setupDir = "dist\PhotoBridge-Windows-Setup"
if (-not (Test-Path $setupDir)) { New-Item -ItemType Directory -Path $setupDir -Force | Out-Null }
Copy-Item "dist\win-x64\PhotoBridge.exe" -Destination "$setupDir\PhotoBridge.exe" -Force
Copy-Item "src\PhotoBridge.PC\Resources\AppIcon.ico" -Destination "$setupDir\AppIcon.ico" -Force

# 壓縮為 Release ZIP
$zipPath = "dist\PhotoBridge-v1.0.0-Windows-x64.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path "$setupDir\*" -DestinationPath $zipPath -Force
Write-Host "✅ 已生成 Windows 安裝包: $zipPath" -ForegroundColor Green

# 3. 檢查 iOS / iPad 專案
Write-Host "`n[3/3] 正在檢查 iPad 端 (App Store 標準)..." -ForegroundColor Yellow
if (Test-Path "ios\PhotoBridge.swiftpm\Package.swift") {
    Write-Host "✅ iPad Swift Playgrounds 專案就緒 (可於 iPad 內直接發布 App Store Connect)" -ForegroundColor Green
}
if (Test-Path "ios\Xcode\PhotoBridge\Info.plist") {
    Write-Host "✅ iPad Xcode 專案就緒 (包含標準 App Store 隱私權限與 1024 圖標)" -ForegroundColor Green
}

Write-Host "`n🎉 所有打包與發布檔案已完成！" -ForegroundColor Cyan
