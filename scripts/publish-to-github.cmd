@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Publish PocketClaude to GitHub / Publicar en GitHub
cd /d "%~dp0.."

echo ==========================================================
echo   PUBLISH TO GITHUB / PUBLICAR EN GITHUB
echo.
echo   STEP A. Create an EMPTY repository on github.com:
echo     - go to https://github.com/new
echo     - name it (for example: pocketclaude)
echo     - Public
echo     - do NOT tick README, .gitignore or license
echo     - Create repository, then copy the URL
echo.
echo   PASO A. Crea un repositorio VACIO en github.com:
echo     - entra a https://github.com/new
echo     - ponle nombre (por ejemplo: pocketclaude)
echo     - Publico
echo     - NO marques README, .gitignore ni licencia
echo     - Create repository, y copia la URL
echo ==========================================================
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo Git is not installed. Get it from https://git-scm.com/downloads/win
  echo Git no esta instalado. Descargalo de https://git-scm.com/downloads/win
  pause
  exit /b
)

set "REPOURL="
set /p REPOURL=STEP B. Paste the repository URL / Pega la URL del repositorio: 
if "%REPOURL%"=="" (
  echo No URL entered. / No se ingreso URL.
  pause
  exit /b
)

echo.
echo Checking that no secrets are about to be published...
if exist ".env" ( echo REFUSING: a .env file exists here. Delete it first. & pause & exit /b )

if not exist ".git" (
  echo Initializing the repository...
  git init -q
  git add -A
  git commit -q -m "PocketClaude: Claude Code + Telegram on Windows via WSL 2"
  git branch -M main
) else (
  echo Repository already prepared. Adding anything new...
  git add -A
  git diff --cached --quiet || git commit -q -m "Update"
  git branch -M main >nul 2>&1
)

echo.
echo Files that will be published:
git ls-files
echo.

git remote remove origin >nul 2>&1
git remote add origin %REPOURL%

echo ==========================================================
echo   STEP C. Sign in.
echo   Git will open a browser window to sign in to GitHub.
echo   If instead it asks in this window for a username and
echo   password, the "password" is a Personal Access Token:
echo     https://github.com/settings/tokens
echo     Generate new token (classic) ^> tick "repo" ^> copy it.
echo.
echo   PASO C. Inicia sesion.
echo   Git abrira una ventana del navegador para entrar a GitHub.
echo   Si en cambio te pide usuario y contrasena aqui, la
echo   "contrasena" es un Token de Acceso Personal, que creas en
echo   la direccion de arriba marcando "repo".
echo ==========================================================
echo.
pause
git push -u origin main

echo.
if errorlevel 1 (
  echo ----------------------------------------------------------
  echo  PUSH FAILED / FALLO LA SUBIDA
  echo  Most common causes / causas mas comunes:
  echo   - the repository on github.com is not empty
  echo   - the URL is wrong (it must end in .git or be the repo URL)
  echo   - the sign-in was cancelled
  echo  Fix it and run this file again. Nothing was lost.
  echo ----------------------------------------------------------
) else (
  echo ----------------------------------------------------------
  echo  DONE / LISTO
  echo  Your repository is live at:
  echo  %REPOURL%
  echo.
  echo  Now open it on github.com and add:
  echo   - a short description
  echo   - topics: claude-code, telegram-bot, wsl2, windows, mcp,
  echo     notion, automation, personal-assistant
  echo ----------------------------------------------------------
)
pause
endlocal
