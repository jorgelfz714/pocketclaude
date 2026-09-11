@echo off
setlocal EnableExtensions
title PocketClaude - diagnostics / diagnostico
set "LOG=%~dp0..\diagnostics.txt"
echo ===== DIAGNOSTICS - %date% %time% ===== > "%LOG%"
echo Run this WHILE the bot window is open, in a separate window.
echo Ejecuta esto MIENTRAS la ventana del bot esta abierta, en otra ventana.
echo.
wsl -d Ubuntu -- bash -lc "echo '[1] bun with an empty environment - must print a path'; env -i bash -c 'which bun && bun --version' || echo BUN-NOT-ON-SYSTEM-PATH; echo; echo '[2] channel server process - must exist while the bot runs'; pgrep -af 'server.ts' | grep -v pgrep || echo NO-CHANNEL-SERVER; echo; echo '[3] messages waiting at Telegram'; T=\$(cut -d= -f2- ~/.claude/channels/telegram/.env 2>/dev/null | tr -d '\r\n '); curl -s --max-time 15 https://api.telegram.org/bot\$T/getWebhookInfo; echo; echo '[4] who is allowed to talk to the bot'; cat ~/.claude/channels/telegram/access.json 2>/dev/null || echo 'no access.json yet'; echo; echo '[5] last channel connection log'; D=\$(ls -d ~/.cache/claude-cli-nodejs/*/mcp-logs-plugin-telegram-telegram 2>/dev/null | head -1); F=\$(ls -t \$D 2>/dev/null | head -1); echo \"file: \$D/\$F\"; tail -c 2000 \$D/\$F 2>/dev/null" >> "%LOG%" 2>&1
type "%LOG%"
echo.
echo ----------------------------------------------------------
echo  HOW TO READ THIS / COMO LEER ESTO
echo  [1] BUN-NOT-ON-SYSTEM-PATH  -^> rerun 3-install-claude-and-bun.cmd
echo  [2] NO-CHANNEL-SERVER + log says ENOENT bun -^> same fix
echo  [2] NO-CHANNEL-SERVER + log says SIGINT     -^> your Claude window closed
echo  [3] pending_update_count high and nothing else running
echo      -^> the bot is fine, nobody is listening
echo  [4] your Telegram id must appear in allowFrom
echo ----------------------------------------------------------
echo.
echo Saved to diagnostics.txt / Guardado en diagnostics.txt
pause
endlocal
