#!/usr/bin/env bash
# PocketClaude on an always-on Linux server (Ubuntu/Debian, x86_64 or arm64).
# PocketClaude en un servidor Linux siempre encendido.
#
# Run as your normal user (not root), from an SSH session:
#   curl -fsSL https://raw.githubusercontent.com/jorgelfz714/pocketclaude/main/server/install.sh -o install.sh
#   bash install.sh
#
# Safe to run again: every step checks what is already done.
set -uo pipefail

PLUGIN="plugin:telegram@claude-plugins-official"
SESSION="pocketclaude"
ENV_FILE="$HOME/.claude/channels/telegram/.env"
RUNNER="$HOME/.pocketclaude/run.sh"
UNIT="/etc/systemd/system/pocketclaude.service"

say()   { printf '\n\033[1;36m%s\033[0m\n' "$*"; }
pause() { read -rp "   Enter para continuar / Press Enter to continue... " _; }

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this as your normal user, not root. / Ejecutalo con tu usuario normal, no como root."
  exit 1
fi
sudo -v || { echo "This user needs sudo. / Este usuario necesita sudo."; exit 1; }
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"

say "[1/7] System packages / Paquetes del sistema"
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl unzip tmux ca-certificates >/dev/null
echo "curl, unzip, tmux: ok"

# Small free-tier machines (1 GB) run out of memory without swap.
MEM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
if [ "$MEM_MB" -lt 2000 ] && ! swapon --show | grep -q .; then
  say "Only ${MEM_MB} MB of RAM: adding 2 GB of swap / Poca RAM: agregando 2 GB de swap"
  sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile >/dev/null && sudo swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
fi

say "[2/7] Claude Code"
if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL https://claude.ai/install.sh | bash
fi
claude --version || { echo "Claude Code did not install. / Claude Code no se instalo."; exit 1; }

say "[3/7] Bun"
if ! "$HOME/.bun/bin/bun" --version >/dev/null 2>&1; then
  curl -fsSL https://bun.sh/install | bash >/dev/null
fi
echo -n "bun "; "$HOME/.bun/bin/bun" --version || { echo "Bun did not install. / Bun no se instalo."; exit 1; }

# The same fix as on Windows: Claude Code starts plugin servers with a minimal
# PATH, so both binaries must be visible from /usr/local/bin.
sudo ln -sf "$HOME/.bun/bin/bun" /usr/local/bin/bun
sudo ln -sf "$HOME/.local/bin/claude" /usr/local/bin/claude
chmod 755 "$HOME" "$HOME/.bun" "$HOME/.bun/bin" 2>/dev/null
grep -q '.bun/bin' "$HOME/.bashrc" || echo 'export PATH=$HOME/.local/bin:$HOME/.bun/bin:$PATH' >> "$HOME/.bashrc"
echo -n "bun with an empty environment: "; env -i bash -c 'command -v bun' || echo NOT-FOUND

say "[4/7] Sign in to Claude / Iniciar sesion en Claude"
cat <<'EOF'
   Claude Code will open. On a server there is no browser: it prints a link.
   Open that link on your phone or PC, sign in, copy the code and paste it here.
   If it asks "Do you trust the files in this folder?", choose YES.
   When you see the prompt, type /exit and Enter.

   Se abrira Claude Code. En un servidor no hay navegador: te muestra un enlace.
   Abrelo en tu celular o PC, inicia sesion, copia el codigo y pegalo aqui.
   Si pregunta si confias en esta carpeta, elige SI (flecha abajo + Enter).
   Cuando veas el prompt, escribe /exit y Enter.
EOF
pause
(cd "$HOME" && claude)

say "[5/7] Telegram plugin / Plugin de Telegram"
claude plugin marketplace add anthropics/claude-plugins-official 2>&1 | tail -1
claude plugin install telegram@claude-plugins-official 2>&1 | tail -1

say "[6/7] Bot token / Token del bot"
KEEP=n
if [ -s "$ENV_FILE" ]; then
  read -rp "   A token is already saved. Keep it? / Ya hay un token guardado. Mantenerlo? [Y/n] " KEEP
  case "$KEEP" in [nN]*) KEEP=n ;; *) KEEP=y ;; esac
fi
if [ "$KEEP" != y ]; then
  echo "   Same token as on your PC: @BotFather -> /mybots -> your bot -> API Token"
  echo "   El mismo token de tu PC: @BotFather -> /mybots -> tu bot -> API Token"
  read -rsp "   Paste the token (hidden) / Pega el token (oculto): " TOKEN; echo
  TOKEN=$(printf '%s' "$TOKEN" | tr -d '\r\n ')
  [ -n "$TOKEN" ] || { echo "No token entered. Run this script again. / Sin token. Vuelve a ejecutar."; exit 1; }
  mkdir -p "$(dirname "$ENV_FILE")"
  ( umask 077; printf 'TELEGRAM_BOT_TOKEN=%s\n' "$TOKEN" > "$ENV_FILE" )
fi
chmod 600 "$ENV_FILE"
T=$(cut -d= -f2- "$ENV_FILE" | tr -d '\r\n ')
echo -n "   Telegram says: "; curl -s --max-time 15 "https://api.telegram.org/bot$T/getMe"; echo

read -rp "   Connect Notion? / Conectar Notion? [y/N] " NOTION
case "$NOTION" in [yYsS]*)
  claude mcp add --transport http notion https://mcp.notion.com/mcp --scope user 2>&1 | tail -1
  echo "   Authorize it later with /mcp (see the guide). / Autorizalo luego con /mcp." ;;
esac

say "[7/7] Always-on service / Servicio siempre encendido"
mkdir -p "$(dirname "$RUNNER")"
cat > "$RUNNER" <<EOF
#!/usr/bin/env bash
# Keeps the bot running: if Claude exits for any reason, start it again.
export PATH="$HOME/.local/bin:$HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin"
cd "$HOME"
while true; do
  claude --channels $PLUGIN
  echo "Claude exited (\$?). Restarting in 10 seconds... / Reiniciando en 10 segundos..."
  sleep 10
done
EOF
chmod 755 "$RUNNER"

sudo tee "$UNIT" >/dev/null <<EOF
[Unit]
Description=PocketClaude Telegram bot
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=$USER
Environment=HOME=$HOME
WorkingDirectory=$HOME
ExecStart=/usr/bin/tmux new-session -d -s $SESSION -x 200 -y 50 $RUNNER
ExecStop=/usr/bin/tmux kill-session -t $SESSION
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable pocketclaude >/dev/null 2>&1
sudo systemctl restart pocketclaude
sleep 3
systemctl is-active --quiet pocketclaude && echo "service: running / servicio: encendido" \
  || { echo "service failed / el servicio fallo:"; sudo systemctl status pocketclaude --no-pager | tail -15; exit 1; }

cat <<EOF

==========================================================
 DONE. The bot now runs on this server, 24/7, and starts
 again by itself after a reboot.
 LISTO. El bot corre en este servidor 24/7 y se vuelve a
 encender solo si el servidor se reinicia.

 IMPORTANT / IMPORTANTE:
   Turn OFF the bot on your Windows PC (/exit in its window).
   Only one computer can use the same bot at a time.
   Apaga el bot de tu PC con Windows (/exit en su ventana).
   Solo una computadora puede usar el mismo bot a la vez.

 Open the bot console / Abrir la consola del bot:
   tmux attach -t $SESSION
 Leave it running / Salir sin apagarlo:  Ctrl+B, then D

 Inside the console, the first time / Dentro, la primera vez:
   1. Message your bot on Telegram; it replies with a code.
   2. /telegram:access pair <code>
   3. /telegram:access policy allowlist
   4. /mcp   (only if you connected Notion)
==========================================================
EOF
