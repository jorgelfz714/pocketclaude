# Always-on bot, without your computer

On Windows the bot lives in a window on your PC: turn the PC off and the bot goes
quiet. To keep it running 24/7 you need **another machine that never turns off**
and runs Linux. Claude Code and the Telegram plugin work there without WSL or any
Windows workaround.

This project has one rule: **zero cost**. No free trials that turn into charges
and no paid accounts "just in case". That is why this guide does **not**
recommend paid servers, or Google Cloud (keeping its free tier after the trial
requires upgrading to a paid account, and there are reports of small unexpected
charges).

## 1. Choose where the bot will live

| Option | Cost | Good | Bad |
|---|---|---|---|
| **A. An old machine at home** (laptop, mini PC, Raspberry Pi 4/5) | 0 if you already own it (just power) | No card, no accounts, no limits | It has to stay on and online |
| **B. Oracle Cloud "Always Free"** | 0 as long as you **don't** upgrade the account | Runs in a data center | Asks for a card only to verify identity. Oracle may **stop** free machines that sit almost idle for 7 days, and a chat bot uses very little; if that happens you start it again from the console. |

If you don't want to depend on any machine, see the
[serverless alternative](#serverless-alternative) at the end.

### Option A — A machine at home

1. Install **Ubuntu 24.04** (laptop or mini PC) or **Raspberry Pi OS 64-bit**
   (Raspberry Pi). Both are free.
2. Make sure it never sleeps: in Ubuntu, *Settings → Power → Automatic suspend:
   off*. Keep a laptop plugged in.
3. Open a terminal on that machine and follow step 2.

### Option B — Oracle Cloud Always Free

1. Create an account at <https://www.oracle.com/cloud/free/>. It asks for a card
   to verify your identity. **Never press "Upgrade" or "Pay As You Go"**: while the
   account stays free, Oracle cannot charge you.
2. In the console: **Compute → Instances → Create instance**. Image **Ubuntu
   24.04**. Under *Shape* pick one marked **Always Free-eligible**
   (`VM.Standard.E2.1.Micro` or `VM.Standard.A1.Flex`).
3. Under *Add SSH keys* press **Save private key** and keep the file.
4. **Create**. Copy the *Public IP address* and connect from PowerShell on your PC:
   ```
   ssh -i PATH\TO\FILE.key ubuntu@PUBLIC-IP
   ```
5. Check what the free tier includes today at <https://www.oracle.com/cloud/free/>;
   the terms can change.

If the bot ever stops answering, open the Oracle console and check whether the
instance shows **Stopped**: press **Start** and the service comes back by itself.

## 2. Install PocketClaude on the machine

In a terminal on the machine (or the SSH session, for Oracle), paste:

```bash
curl -fsSL https://raw.githubusercontent.com/jorgelfz714/pocketclaude/main/server/install.sh -o install.sh
bash install.sh
```

In seven steps the script does what the Windows scripts do:

1. Installs `curl`, `unzip` and `tmux`, and adds swap if the machine is low on RAM.
2. Installs Claude Code.
3. Installs Bun and links it into `/usr/local/bin` (the same fix as on Windows).
4. Opens Claude so you can sign in. If the machine has no browser, it prints a
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

## Serverless alternative

If what you need is to talk to your assistant from your phone at any hour, the
**Claude app** (iOS/Android) already does that with no machine turned on and no
extra cost: it comes with the Claude plan you already pay for. Connect Gmail,
Google Calendar, Google Drive and Notion there under *Settings → Connectors* and
ask it the same things you ask the bot. What you lose compared to the bot is
Telegram and access to the files on your computer.
