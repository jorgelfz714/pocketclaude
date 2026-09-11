@echo off
setlocal EnableExtensions
title Step 2 - Install Ubuntu / Instalar Ubuntu
echo Installing Ubuntu on WSL 2. When the Ubuntu window opens it will ask you
echo to create a Linux username and password - use lowercase, no spaces, and
echo write the password down. You will need it once, for a sudo command.
echo.
echo Instalando Ubuntu en WSL 2. Cuando se abra la ventana de Ubuntu te pedira
echo crear un usuario y contrasena de Linux - en minusculas, sin espacios, y
echo anota la contrasena: la necesitaras una vez, para un comando sudo.
echo.
pause
wsl --install -d Ubuntu
echo.
wsl -l -v
echo.
echo If you see Ubuntu with VERSION 2 above, continue with 3-install-claude-and-bun.cmd
echo Si arriba ves Ubuntu con VERSION 2, continua con 3-install-claude-and-bun.cmd
echo.
echo If you got HCS_E_HYPERV_NOT_INSTALLED, virtualization is off in your BIOS.
echo Si obtuviste HCS_E_HYPERV_NOT_INSTALLED, la virtualizacion esta apagada en el BIOS.
pause
endlocal
