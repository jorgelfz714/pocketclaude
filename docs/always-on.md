# Always-on bot, without your computer

On Windows the bot lives in a window on your PC: turn the PC off and the bot goes
quiet. To keep it running 24/7, install it on a **Linux server in the cloud**, a
small computer that never turns off. Claude Code and the Telegram plugin work
there without WSL or any Windows workaround.

## 1. Get a server

Any server running **Ubuntu 22.04 or 24.04** works. Two options:

| Option | Cost | Notes |
|---|---|---|
| **Google Cloud, e2-micro** | Free ("Always Free" tier) | 1 GB of RAM; the script adds swap. Only in the `us-west1`, `us-central1` or `us-east1` regions. Requires a card for identity verification. |
| Hetzner, DigitalOcean, Vultr, etc. | About USD 4–6 a month | More RAM, fewer steps. |

With Google Cloud:

1. Go to <https://console.cloud.google.com> → **Compute Engine** → **VM
   instances** → **Create instance**.
2. Region `us-central1` (or `us-west1` / `us-east1`), machine type **e2-micro**.
3. Under **Boot disk** choose **Ubuntu 24.04 LTS**, *Standard persistent* disk,
   30 GB.
4. **Create**. When it shows up, press the **SSH** button: a terminal opens in your
   browser. Nothing to install on your PC.

Check the current free-tier terms at <https://cloud.google.com/free> before
creating the machine.

## 2. Install PocketClaude on the server

In the SSH terminal, paste:

```bash
curl -fsSL https://raw.githubusercontent.com/jorgelfz714/pocketclaude/main/server/install.sh -o install.sh
bash install.sh
```

In seven steps the script does what the Windows scripts do:

1. Installs `curl`, `unzip` and `tmux`, and adds swap if the machine is low on RAM.
2. Installs Claude Code.
3. Installs Bun and links it into `/usr/local/bin` (the same fix as on Windows).
4. Opens Claude so you can sign in. The server has no browser, so it prints a
   **link**: open it on your phone or PC, sign in, copy the code and paste it into
   the terminal. If it asks whether you trust the folder, choose **yes**. Then type
   `/exit`.
5. Installs the Telegram plugin.
6. Asks for your bot token (the one you already use: @BotFather → `/mybots` → your
   bot → **API Token**) and verifies it: you should see `"ok":true`.
7. Creates a system service that keeps the bot running, restarts it if it crashes
   and starts it on its own when the server reboots.

## 3. Turn off the bot on your PC

Telegram delivers messages to a single program per bot. Type `/exit` in the
`5-start-bot.cmd` window on your PC and don't open it again while the server is
running. If both run at once they fight over messages (`409 Conflict`).

## 4. Pair again (once)

The bot runs inside a `tmux` console on the server. To get in:

```bash
tmux attach -t pocketclaude
```

1. Message your bot on Telegram: it replies with a code.
2. In the console: `/telegram:access pair <code>`
3. Then: `/telegram:access policy allowlist`
4. If you connected Notion: `/mcp` and authorize it with the link it shows.

To leave **without stopping the bot**: `Ctrl+B`, then `D`. You can now close the
SSH window and turn off your PC.

## Useful commands

| To | Command |
|---|---|
| See the bot console | `tmux attach -t pocketclaude` (leave: `Ctrl+B`, `D`) |
| Is it running? | `systemctl status pocketclaude` |
| Restart it | `sudo systemctl restart pocketclaude` |
| Stop it | `sudo systemctl stop pocketclaude` |
| Don't start on boot | `sudo systemctl disable pocketclaude` |
| Reconfigure (token, Notion) | `bash install.sh` |

## If the bot doesn't answer

- **It's waiting for a permission.** If you asked for something Claude needs to
  approve and the approval didn't reach Telegram, it waits in the console. Run
  `tmux attach -t pocketclaude`, approve it, and for tools you use often choose
  the option not to ask again.
- **Your Claude session expired.** Open the console: if you see a sign-in
  message, follow the link as in step 2.
- **You started the bot on your PC again.** Stop it; there can only be one.
- Every other error and its fix is in [troubleshooting.md](troubleshooting.md);
  the commands in `6-diagnose.cmd` work the same on the server, without the `wsl`
  prefix.

## Security

The server holds your Claude session and the bot token, and the bot can use your
connected accounts. Treat it like your PC: don't share SSH access, keep the policy
on `allowlist`, and if the token leaks, revoke it with `/revoke` in @BotFather and
run `bash install.sh` again.
