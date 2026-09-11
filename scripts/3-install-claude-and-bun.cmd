@echo off
setlocal EnableExtensions
title Step 3 - Install Claude Code and Bun / Instalar Claude Code y Bun
set "LOG=%~dp0..\install-report.txt"

echo ==========================================================
echo   This step installs Claude Code and Bun inside Ubuntu,
echo   and then does the one thing that makes the Telegram
echo   channel actually work.
echo.
echo   Ubuntu will ask for the Linux password you created in
echo   step 2. Nothing is hidden: everything prints on screen.
echo.
echo   Este paso instala Claude Code y Bun dentro de Ubuntu, y
echo   luego hace lo unico que consigue que el canal de Telegram
echo   funcione de verdad. Ubuntu te pedira la contrasena de
echo   Linux que creaste en el paso 2.
echo ==========================================================
echo.
pause

echo.
echo [1/5] Switching apt sources to HTTPS (many networks block plain HTTP)...
wsl -d Ubuntu -- bash -lc "sudo sed -i 's|http://|https://|g' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null; sudo sed -i 's|http://|https://|g' /etc/apt/sources.list 2>/dev/null; sudo apt-get update -qq; sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq unzip; echo '--- unzip:'; which unzip || echo 'unzip unavailable (that is survivable)'"

echo.
echo [2/5] Installing Claude Code (this takes a minute)...
wsl -d Ubuntu -- bash -lc "curl -fsSL https://claude.ai/install.sh | bash"

echo.
echo [3/5] Installing Bun...
wsl -d Ubuntu -- bash -lc "curl -fsSL https://bun.sh/install | bash >/dev/null 2>&1; ~/.bun/bin/bun --version >/dev/null 2>&1 && echo 'bun installed' || echo 'installer failed, trying a direct download'"
wsl -d Ubuntu -- bash -lc "~/.bun/bin/bun --version >/dev/null 2>&1 || { mkdir -p ~/.bun/bin /tmp/bunx; curl -fsSL -o /tmp/bun.zip https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip; python3 -c 'import zipfile; zipfile.ZipFile(\"/tmp/bun.zip\").extractall(\"/tmp/bunx\")'; cp /tmp/bunx/bun-linux-x64/bun ~/.bun/bin/bun; chmod +x ~/.bun/bin/bun; }; ~/.bun/bin/bun --version 2>/dev/null || echo 'still failing, trying the baseline build for older CPUs'"
wsl -d Ubuntu -- bash -lc "~/.bun/bin/bun --version >/dev/null 2>&1 || { mkdir -p ~/.bun/bin /tmp/bunb; curl -fsSL -o /tmp/bunb.zip https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64-baseline.zip; python3 -c 'import zipfile; zipfile.ZipFile(\"/tmp/bunb.zip\").extractall(\"/tmp/bunb\")'; cp /tmp/bunb/bun-linux-x64-baseline/bun ~/.bun/bin/bun; chmod +x ~/.bun/bin/bun; }; echo -n 'bun version: '; ~/.bun/bin/bun --version"

echo.
echo [4/5] THE CRITICAL STEP - putting both binaries on a system path.
echo Claude Code spawns plugin servers with a minimal PATH, so anything that
echo lives only in your home folder is invisible to it. This is the fix.
echo.
wsl -d Ubuntu -- bash -lc "sudo ln -sf \$HOME/.bun/bin/bun /usr/local/bin/bun; sudo ln -sf \$HOME/.local/bin/claude /usr/local/bin/claude; sudo chmod 755 \$HOME \$HOME/.bun \$HOME/.bun/bin \$HOME/.local \$HOME/.local/bin; grep -q '.bun/bin' ~/.bashrc || echo 'export PATH=\$HOME/.local/bin:\$HOME/.bun/bin:\$PATH' >> ~/.bashrc; grep -q '.bun/bin' ~/.profile || echo 'export PATH=\$HOME/.local/bin:\$HOME/.bun/bin:\$PATH' >> ~/.profile; echo done"

echo.
echo [5/5] Verifying the way Claude Code will see them - with an EMPTY environment:
echo.
echo ===== VERIFICATION - %date% %time% ===== > "%LOG%"
wsl -d Ubuntu -- bash -lc "env -i bash -c 'echo -n \"bun    -> \"; which bun || echo NOT-FOUND; echo -n \"claude -> \"; which claude || echo NOT-FOUND'; echo -n 'bun version: '; bun --version; claude --version" >> "%LOG%" 2>&1
type "%LOG%"

echo.
findstr /c:"NOT-FOUND" "%LOG%" >nul 2>&1
if not errorlevel 1 (
  echo ----------------------------------------------------------
  echo  SOMETHING IS MISSING. The lines above should show
  echo  /usr/local/bin/bun and /usr/local/bin/claude.
  echo  Rerun this script, or see docs/troubleshooting.md entry 7.
  echo ----------------------------------------------------------
) else (
  echo ----------------------------------------------------------
  echo  Both found on the system path. The hard part is over.
  echo  Ambos encontrados en la ruta del sistema. Lo dificil paso.
  echo.
  echo  Next / Siguiente: 4-configure-telegram.cmd
  echo ----------------------------------------------------------
)
echo.
pause
endlocal
