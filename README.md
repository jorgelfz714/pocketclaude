# PocketClaude

![PocketClaude](docs/img/banner.png)

**Talk to Claude from Telegram, on Windows.** A complete, tested setup for running
Claude Code's Telegram channel on a Windows PC through WSL 2, plus an optional
personal-assistant layer that reads your email and calendar and keeps your tasks
in Notion.

Español: [README.es.md](README.es.md)

---

## Why this exists

Anthropic ships an official Telegram channel plugin for Claude Code. On macOS and
Linux it works out of the box. **On Windows it does not**, and the reasons are not
in the documentation:

1. On **native Windows**, the plugin sends messages but never receives them. The
   bot appears dead. This is a known, unresolved bug
   ([claude-code#39776](https://github.com/anthropics/claude-code/issues/39776),
   [claude-plugins-official#797](https://github.com/anthropics/claude-plugins-official/issues/797)).
   The workaround is to run everything inside WSL 2.
2. Inside **WSL 2**, the plugin still fails with
   `Connection failed (ENOENT): Executable not found in $PATH: "bun"` — even when
   `bun --version` works perfectly in your terminal. Claude Code spawns MCP servers
   with a minimal environment, so a Bun installed in your home directory is
   invisible to it. **One symlink fixes it**, and that symlink is the single most
   important line in this repository:

   ```bash
   sudo ln -sf $HOME/.bun/bin/bun /usr/local/bin/bun
   ```

Getting from "nothing installed" to "the bot answers me" took a full afternoon of
dead ends. This repo is that afternoon, compressed into six scripts and a
troubleshooting log, so it takes you about thirty minutes instead.

> Community project. Not affiliated with or endorsed by Anthropic or Telegram.

---

## How it works

![Architecture](docs/img/architecture.png)

You write from anywhere. The work happens on your own computer, against your own
accounts. Nothing is copied into a third-party service, and nothing is duplicated:
your calendar stays your calendar, your inbox stays your inbox.

---

## What you end up with

- A **Telegram bot that is really Claude**, running on your own machine with
  access to your own files.
- Anything you have connected to your Claude account — Gmail, Google Calendar,
  Google Drive, Notion, Microsoft 365 — reachable from a chat on your phone.
  *"What meetings do I have tomorrow?"*, *"add a task: send the report Friday"*,
  *"summarize the email from the dean"*.
- Optionally, a **personal assistant structure in Notion** that organizes
  everything by area of work, turns actionable emails into tasks, and writes you a
  daily briefing. See [docs/notion-assistant.md](docs/notion-assistant.md).

![Integrations](docs/img/integrations.png)

---

## Requirements

| What | Notes |
|---|---|
| Windows 10 (build 1809+) or Windows 11 | Home edition is fine |
| A CPU with virtualization, **enabled in BIOS** | Step 1 checks this for you |
| A paid Claude plan (Pro, Max, Team or Enterprise) | Claude Code is included; the free plan does not include it |
| A Telegram account | The bot itself is free |
| About 30 minutes, and one reboot | |

Everything installed here is free: WSL 2, Ubuntu, Claude Code (included in your
plan), Bun, and the Telegram bot.

---

## Install

![Install flow](docs/img/install-flow.png)

Download this repository (green **Code** button → **Download ZIP**), unzip it
anywhere, and run the scripts in `scripts/` in order. Each one tells you what it
did and what comes next.

### Step 1 — Enable WSL 2

Double-click **`1-enable-wsl.cmd`** and accept the administrator prompt.

It turns on the two Windows features WSL needs, sets the hypervisor to start at
boot, updates WSL from the web, and reads your firmware status. It writes
everything to `wsl-report.txt`.

At the end it tells you one of two things:

- **"Fixes applied. REBOOT now"** → reboot and go to step 2.
- **"virtualization is DISABLED in your BIOS"** → this is the one thing no script
  can do for you. Reboot, press your manufacturer's setup key while the machine
  starts (HP `F10`, Dell `F2`, Lenovo `F1`/`F2`, ASUS/Acer `F2` or `Del`), find
  **Virtualization Technology** / **Intel VT-x** / **SVM Mode**, set it to
  **Enabled**, save with `F10`, and let Windows start.

### Step 2 — Install Ubuntu

Double-click **`2-install-ubuntu.cmd`**.

Ubuntu downloads and opens a window asking for a Linux username and password.
Use lowercase, no spaces, and **write the password down** — you need it once, in
step 3. The script then prints your distributions; you want `Ubuntu` with
`VERSION 2`.

### Step 3 — Install Claude Code and Bun

Double-click **`3-install-claude-and-bun.cmd`**. This is the step that contains
the actual fix.

It switches Ubuntu's package sources to HTTPS (many corporate and university
networks return `403 Forbidden` on plain HTTP, which breaks `apt`), installs
Claude Code, installs Bun — falling back to a direct download from GitHub, and
then to the `baseline` build for older CPUs, if the normal installer fails — and
finally links Bun into `/usr/local/bin`, which is what makes Claude Code able to
find it.

Ubuntu asks for the Linux password you just created, once.

The script ends by testing Bun **in an empty environment**, which is how Claude
Code will see it:

```
bun with an empty environment: /usr/local/bin/bun
1.4.2
```

If you get a path and a version number, the hard part is over.

### Step 4 — Create the bot and connect it

Before running it, create your bot: open Telegram, search **@BotFather**, send
`/newbot`, give it a display name and a username ending in `bot`, and copy the
token it returns (`123456789:AAH...`). **That token is the password to your bot —
never commit it or share it.**

Then double-click **`4-configure-telegram.cmd`**. It:

1. Opens Claude Code so you can sign in (a browser window completes the login).
   Type `/exit` when you see the prompt.
2. Installs the Telegram channel plugin.
3. Asks for your token, saves it to `~/.claude/channels/telegram/.env` with
   permissions `600`, and verifies it against Telegram. You should see
   `"ok":true` and your bot's name.
4. Optionally adds the Notion MCP server.

### Step 5 — Start the bot

Double-click **`5-start-bot.cmd`**. Two things decide whether this works:

- If Claude asks **"Is this a project you created or one you trust?"**, do **not**
  press Enter straight away. The highlighted option is **"No, exit"**, and it
  closes Claude — which silently kills the channel with it. Press the **down
  arrow** to select "Yes, I trust this folder", then Enter. It only asks once.
- **Leave that window open.** The bot lives inside it.

Now message your bot from Telegram. The first time, it replies with a
six-character pairing code. In the Claude window type:

```
/telegram:access pair <that code>
/telegram:access policy allowlist
```

The first command authorizes you; the second locks the bot so only you can use
it. From then on, just write to it.

If you connected Notion, type `/mcp` once and authorize it in the browser.

---

## Daily use

Run `5-start-bot.cmd`, accept the trust prompt if asked, leave the window open,
and talk to your bot from anywhere. `/exit` stops it.

Want it running 24/7 without your PC turned on? Install it on a cloud server:
[docs/always-on.md](docs/always-on.md).

The bot is Claude with your tools, so useful messages look like:

- *"What's on my calendar today?"*
- *"Any email I need to answer today?"*
- *"Add a task: submit the grades report by Friday"*
- *"Summarize the last message from <person>"*

---

## Running it from another computer

You can install PocketClaude on a second Windows PC (or move it to a new one) by
following the same steps 1 to 5. Three things are different:

- **Reuse the same bot.** In step 4, paste the token of the bot you already
  have; there is no need to create another one with @BotFather. If you don't have
  it at hand, send `/mybots` to @BotFather, pick your bot and tap **API Token**.
- **Run the bot on one computer at a time.** Telegram delivers messages to a
  single program per token. If `5-start-bot.cmd` runs on two PCs at once, they
  fight over the messages (`409 Conflict`) and the bot only half answers. Type
  `/exit` on the other PC before starting this one. If you want both running at
  once, create a second bot.
- **Pair again.** The list of who may talk to the bot lives on each computer.
  The first time you message it from this PC it gives you a code: repeat
  `/telegram:access pair <code>` and `/telegram:access policy allowlist`. If you
  connected Notion or other tools, authorize them again with `/mcp`.

---

## When something breaks

Run **`6-diagnose.cmd`** in a second window while the bot window is open. It
checks the five things that actually go wrong and tells you how to read the
result.

The full log of every failure encountered while building this — with the exact
error text, the cause, and the fix — is in
**[docs/troubleshooting.md](docs/troubleshooting.md)**. If you landed here from a
search engine, that is probably the page you want.

---

## Security notes

- Your bot token lives only in `~/.claude/channels/telegram/.env` inside WSL, with
  permissions `600`. It is never stored in this repository. The `.gitignore`
  blocks `.env` files and `access.json` so you cannot commit them by accident.
- Always run `/telegram:access policy allowlist` after pairing. Without it, the
  policy stays `pairing` and anyone who finds your bot's username can request a
  code.
- The bot is Claude Code running on your machine with access to your files and
  your connected accounts. Treat the Telegram chat as you would treat an open
  terminal: do not add people you do not trust to the allowlist.
- If you ever leak the token, open @BotFather, `/revoke`, and run step 4 again
  with the new token.

---

## Repository layout

```
scripts/
  1-enable-wsl.cmd            Windows features, hypervisor, firmware check
  2-install-ubuntu.cmd        Ubuntu on WSL 2
  3-install-claude-and-bun.cmd  Claude Code, Bun, and the /usr/local/bin fix
  4-configure-telegram.cmd    Login, plugin, bot token, optional Notion
  5-start-bot.cmd             Start the bot (use this one every day)
  6-diagnose.cmd              Diagnostics when the bot goes quiet
  publish-to-github.cmd       Publish your own copy (optional)
server/
  install.sh                  24/7 bot on a cloud Linux server
docs/
  troubleshooting.md          Every error, its cause, and its fix
  notion-assistant.md         The Notion assistant layer
  always-on.md                Always-on bot, without your computer
  img/                        Diagrams used in this README
```

---

## Credits

Built and documented by [Jorge Ludena](https://github.com/) while setting up a
personal assistant for academic work across three universities. Contributions and
corrections are welcome — if you hit an error that is not in the troubleshooting
log, please open an issue with the exact message.
