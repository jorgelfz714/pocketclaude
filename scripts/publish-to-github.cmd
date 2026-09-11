@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Publish PocketClaude to GitHub / Publicar en GitHub
cd /d "%~dp0.."

echo ==========================================================
echo   PUBLISH TO GITHUB / PUBLICAR EN GITHUB
echo.
echo   Before running this, create an EMPTY repository on
echo   github.com (no README, no .gitignore, no license) and
echo   copy its URL.
echo.
echo   Antes de ejecutar esto, crea un repositorio VACIO en
echo   github.com (sin README, sin .gitignore, sin licencia) y
echo   copia su URL.
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
set /p REPOURL=Repository URL (https://github.com/user/repo.git): 
if "%REPOURL%"=="" (
  echo No URL entered. / No se ingreso URL.
  pause
  exit /b
)

echo.
echo Checking that no secrets are about to be committed...
if exist ".env" ( echo REFUSING: a .env file exists here. Delete it first. & pause & exit /b )
dir /s /b *.env >nul 2>&1 && ( echo REFUSING: .env files found. Delete them first. & pause & exit /b )

echo.
git init
git add -A
git status --short
echo.
echo Review the list above. Nothing with a token should be there.
echo Revisa la lista de arriba. No debe aparecer nada con un token.
echo.
pause

git commit -m "PocketClaude: Claude Code + Telegram on Windows via WSL 2"
git branch -M main
git remote remove origin >nul 2>&1
git remote add origin %REPOURL%

echo.
echo Pushing. Git will ask for your GitHub username and a Personal Access
echo Token (not your password). Create one at:
echo   https://github.com/settings/tokens  ^> Generate new token (classic)
echo   ^> tick "repo" ^> copy the token and paste it as the password.
echo.
echo Subiendo. Git pedira tu usuario de GitHub y un Token de Acceso Personal
echo (no tu contrasena). Crealo en la misma direccion, marca "repo", copia el
echo token y pegalo donde pida la contrasena.
echo.
git push -u origin main

echo.
if errorlevel 1 (
  echo Push failed. Check the URL and your token, then run this again.
  echo Fallo la subida. Revisa la URL y tu token, y vuelve a ejecutarlo.
) else (
  echo Done. Your repository is live at %REPOURL%
  echo Listo. Tu repositorio esta publicado en %REPOURL%
  echo.
  echo Now open it on github.com and add a short description and topics:
  echo   claude-code, telegram-bot, wsl2, windows, mcp, notion, automation
)
pause
endlocal
