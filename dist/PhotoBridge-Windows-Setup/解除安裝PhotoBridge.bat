@echo off
chcp 65001 >nul
echo 正在解除安裝 PhotoBridge...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$appDir = Join-Path $env:LOCALAPPDATA 'Programs\PhotoBridge';" ^
  "$deskLnk = Join-Path ([System.Environment]::GetFolderPath('Desktop')) 'PhotoBridge.lnk';" ^
  "$startLnk = Join-Path ([System.Environment]::GetFolderPath('Programs')) 'PhotoBridge.lnk';" ^
  "if (Test-Path $deskLnk) { Remove-Item $deskLnk -Force; };" ^
  "if (Test-Path $startLnk) { Remove-Item $startLnk -Force; };" ^
  "if (Test-Path $appDir) { Remove-Item $appDir -Recurse -Force; };" ^
  "$uninstReg = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\PhotoBridge';" ^
  "if (Test-Path $uninstReg) { Remove-Item $uninstReg -Recurse -Force; };" ^
  "Write-Host '✅ 已順利移除 PhotoBridge 及相關捷徑。' -ForegroundColor Green"

echo 解除安裝完成。
pause
