@echo off
chcp 65001 >nul
echo ========================================================
echo       正在安裝 PhotoBridge (PC to iPad 高速直傳工具)
echo ========================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$appDir = Join-Path $env:LOCALAPPDATA 'Programs\PhotoBridge';" ^
  "New-Item -ItemType Directory -Path $appDir -Force | Out-Null;" ^
  "Copy-Item -Path 'PhotoBridge.exe' -Destination $appDir -Force;" ^
  "Copy-Item -Path 'AppIcon.ico' -Destination $appDir -Force;" ^
  "$ws = New-Object -ComObject WScript.Shell;" ^
  "$deskPath = [System.Environment]::GetFolderPath('Desktop');" ^
  "$scDesk = $ws.CreateShortcut((Join-Path $deskPath 'PhotoBridge.lnk'));" ^
  "$scDesk.TargetPath = (Join-Path $appDir 'PhotoBridge.exe');" ^
  "$scDesk.IconLocation = (Join-Path $appDir 'AppIcon.ico');" ^
  "$scDesk.Description = 'PhotoBridge 高速照片區網直傳';" ^
  "$scDesk.Save();" ^
  "$progPath = [System.Environment]::GetFolderPath('Programs');" ^
  "$scStart = $ws.CreateShortcut((Join-Path $progPath 'PhotoBridge.lnk'));" ^
  "$scStart.TargetPath = (Join-Path $appDir 'PhotoBridge.exe');" ^
  "$scStart.IconLocation = (Join-Path $appDir 'AppIcon.ico');" ^
  "$scStart.Description = 'PhotoBridge 高速照片區網直傳';" ^
  "$scStart.Save();" ^
  "$uninstReg = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\PhotoBridge';" ^
  "New-Item -Path $uninstReg -Force | Out-Null;" ^
  "Set-ItemProperty -Path $uninstReg -Name 'DisplayName' -Value 'PhotoBridge (PC to iPad)';" ^
  "Set-ItemProperty -Path $uninstReg -Name 'DisplayVersion' -Value '1.0.0';" ^
  "Set-ItemProperty -Path $uninstReg -Name 'Publisher' -Value 'jiun264';" ^
  "Set-ItemProperty -Path $uninstReg -Name 'DisplayIcon' -Value (Join-Path $appDir 'AppIcon.ico');" ^
  "Set-ItemProperty -Path $uninstReg -Name 'InstallLocation' -Value $appDir;" ^
  "Write-Host '✅ 安裝完成！桌面與開始功能表已建立捷徑。' -ForegroundColor Green"

echo.
echo ========================================================
echo 安裝完成！您可以從桌面或開始功能表開啟 PhotoBridge。
echo ========================================================
pause
