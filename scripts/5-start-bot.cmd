@echo off
setlocal EnableExtensions
title POCKETCLAUDE - keep this window open / deja esta ventana abierta
echo ==========================================================
echo   POCKETCLAUDE - Telegram bot
echo.
echo   TWO THINGS THAT DECIDE WHETHER THIS WORKS:
echo.
echo   1) If Claude asks "Is this a project you created or one
echo      you trust?" do NOT just press Enter. The highlighted
echo      option is "No, exit" and it closes everything.
echo      Press the DOWN ARROW to select "Yes, I trust this
echo      folder", then Enter.
echo.
echo   2) KEEP THIS WINDOW OPEN while you use the bot. Closing
echo      it shuts the bot down.
echo.
echo   ---
echo.
echo   DOS COSAS QUE DECIDEN SI ESTO FUNCIONA:
echo.
echo   1) Si Claude pregunta "Is this a project you created or
echo      one you trust?" NO pulses Enter de una vez: la opcion
echo      marcada es "No, exit" y cierra todo. Pulsa la FLECHA
echo      ABAJO para elegir "Yes, I trust this folder" y Enter.
echo.
echo   2) DEJA ESTA VENTANA ABIERTA mientras uses el bot.
echo      Si la cierras, el bot se apaga.
echo.
echo   FIRST TIME / PRIMERA VEZ: message your bot on Telegram.
echo   It replies with a 6-character pairing code. Type here:
echo     /telegram:access pair THAT-CODE
echo     /telegram:access policy allowlist
echo.
echo   To stop the bot / Para apagarlo: type /exit
echo ==========================================================
echo.
pause
wsl -d Ubuntu -- bash -lc "cd ~ && claude --channels plugin:telegram@claude-plugins-official"
echo.
echo Bot stopped. / El bot se apago.
pause
endlocal
