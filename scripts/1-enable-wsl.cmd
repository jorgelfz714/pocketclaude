@echo off
setlocal EnableExtensions
title Step 1 - Enable WSL 2 / Habilitar WSL 2
:: Self-elevate / Auto-elevacion
net session >nul 2>&1
if not "%errorlevel%"=="0" (
  echo Requesting administrator rights... / Pidiendo permisos de administrador...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
set "LOG=%~dp0..\wsl-report.txt"
set "SYS=%TEMP%\sysinfo_wsl.txt"

echo Collecting system information (may take a minute)...
systeminfo > "%SYS%" 2>&1
echo ===== WSL REPORT - %date% %time% ===== > "%LOG%"
echo. >> "%LOG%"
echo [1] Hyper-V requirements >> "%LOG%"
findstr /i "Hyper-V hypervisor hipervisor firmware virtualiz" "%SYS%" >> "%LOG%"
echo. >> "%LOG%"
echo [2] hypervisorlaunchtype BEFORE >> "%LOG%"
bcdedit /enum {current} | findstr /i hypervisorlaunchtype >> "%LOG%"
if errorlevel 1 echo (absent = Off) >> "%LOG%"
echo. >> "%LOG%"

echo Applying fixes...
echo [3] bcdedit hypervisorlaunchtype auto >> "%LOG%"
bcdedit /set hypervisorlaunchtype auto >> "%LOG%" 2>&1
echo [4] Enabling Windows features >> "%LOG%"
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart >> "%LOG%" 2>&1
dism /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart >> "%LOG%" 2>&1
echo [5] Updating WSL from the web >> "%LOG%"
wsl --update --web-download >> "%LOG%" 2>&1
wsl --set-default-version 2 >> "%LOG%" 2>&1
echo [6] Enabling Virtual Machine Platform through wsl.exe >> "%LOG%"
wsl --install --no-distribution >> "%LOG%" 2>&1
echo. >> "%LOG%"
echo [7] hypervisorlaunchtype AFTER >> "%LOG%"
bcdedit /enum {current} | findstr /i hypervisorlaunchtype >> "%LOG%"

set "FW=unknown"
findstr /i /c:"firmware" "%SYS%" | findstr /i /c:": No" >nul 2>&1 && set "FW=NO"
findstr /i /c:"hypervisor" "%SYS%" >nul 2>&1 && set "FW=HYPERVISOR-RUNNING"
findstr /i /c:"hipervisor" "%SYS%" >nul 2>&1 && set "FW=HYPERVISOR-RUNNING"
echo [8] Firmware virtualization: %FW% >> "%LOG%"

echo.
type "%LOG%"
echo.
echo ==========================================================
if "%FW%"=="NO" (
  echo  ACTION REQUIRED: virtualization is DISABLED in your BIOS/UEFI.
  echo  Reboot, enter BIOS setup ^(HP: F10, Dell: F2, Lenovo: F1/F2,
  echo  ASUS/Acer: F2 or Del^), find "Virtualization Technology" /
  echo  "Intel VT-x" / "SVM Mode" and set it to Enabled. Save with F10.
  echo.
  echo  ACCION REQUERIDA: la virtualizacion esta DESACTIVADA en el BIOS.
  echo  Reinicia, entra al BIOS y activa "Virtualization Technology".
) else (
  echo  Fixes applied. REBOOT now, then run 2-install-ubuntu.cmd
  echo  Correcciones aplicadas. REINICIA y luego ejecuta 2-install-ubuntu.cmd
)
echo ==========================================================
echo.
pause
endlocal
