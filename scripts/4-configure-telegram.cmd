@echo off
setlocal EnableExtensions
title Step 4 - Configure Telegram / Configurar Telegram
set "LOG=%~dp0..\telegram-report.txt"
echo ===== TELEGRAM - %date% %time% ===== > "%LOG%"

echo ==========================================================
echo  BEFORE YOU CONTINUE / ANTES DE CONTINUAR
echo.
echo  1. Open Telegram and search for @BotFather
echo  2. Send /newbot
echo  3. Give it a display name (e.g. My Assistant)
echo  4. Give it a username ending in "bot" (e.g. my_assistant_bot)
echo  5. Copy the token it gives you: 123456789:AAH...
echo.
echo  Never share that token. It is the password to your bot.
echo  Nunca compartas ese token. Es la contrasena de tu bot.
echo ==========================================================
echo.

echo [1/3] Sign in to Claude Code.
echo A Claude Code session will open. Choose your Claude account and finish
echo the login in the browser. When you see the prompt, type /exit and Enter.
echo.
echo Se abrira Claude Code. Elige tu cuenta de Claude y completa el inicio de
echo sesion en el navegador. Cuando veas el prompt, escribe /exit y Enter.
echo.
pause
wsl -d Ubuntu -- bash -lc "cd ~ && claude"

echo.
echo [2/3] Installing the Telegram channel plugin...
wsl -d Ubuntu -- bash -lc "claude plugin marketplace add anthropics/claude-plugins-official; claude plugin install telegram@claude-plugins-official" >> "%LOG%" 2>&1
type "%LOG%"

echo.
set "TOKEN="
set /p TOKEN=Paste your bot token here and press Enter / Pega el token y Enter: 
if "%TOKEN%"=="" (
  echo No token entered. Run this script again when you have it.
  pause
  exit /b
)
wsl -d Ubuntu -- bash -lc "mkdir -p ~/.claude/channels/telegram; echo TELEGRAM_BOT_TOKEN=%TOKEN% > ~/.claude/channels/telegram/.env; chmod 600 ~/.claude/channels/telegram/.env; T=\$(cut -d= -f2- ~/.claude/channels/telegram/.env | tr -d '\r\n '); echo -n 'Telegram says: '; curl -s --max-time 15 https://api.telegram.org/bot\$T/getMe"
echo.
echo.
echo If the line above shows "ok":true and your bot name, the token is valid.
echo Si la linea de arriba muestra "ok":true y el nombre de tu bot, es valido.
echo.

echo [3/3] Optional: connect Notion so the bot can read and write your notes.
choice /c YN /m "Connect Notion now? / Conectar Notion ahora? (Y/N)"
if errorlevel 2 goto skipnotion
wsl -d Ubuntu -- bash -lc "claude mcp add --transport http notion https://mcp.notion.com/mcp --scope user" >> "%LOG%" 2>&1
echo Notion server added. You will authorize it inside Claude with /mcp later.
echo Servidor de Notion agregado. Lo autorizaras dentro de Claude con /mcp.
:skipnotion

echo.
echo Done. Next / Siguiente: 5-start-bot.cmd
pause
endlocal
