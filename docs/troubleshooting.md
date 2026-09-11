# Troubleshooting log

Every error actually encountered while getting Claude Code's Telegram channel
running on Windows, in the order they appeared. Each entry has the **exact error
text** (so search engines can find it), the **cause**, and the **fix**.

---

## 1. The bot never receives messages on native Windows

**Symptom.** Claude Code runs, the plugin is installed, the bot exists — and
messages sent to it are simply ignored. Outbound works: if Claude sends a reply,
it arrives. Inbound never does.

**Cause.** A bug in how Claude Code spawns the channel's MCP server on native
Windows: the polling loop that calls Telegram's `getUpdates` never starts. Tracked
in [claude-code#39776](https://github.com/anthropics/claude-code/issues/39776) and
[claude-plugins-official#797](https://github.com/anthropics/claude-plugins-official/issues/797).
Both were open at the time of writing.

**Fix.** Run Claude Code inside **WSL 2** instead of native Windows. That is what
this repository automates. There is no known fix for the native Windows path.

---

## 2. `wsl --install` fails with error `0xc004000d`

```
Instalando: Plataforma de máquina virtual
Error: 0xc004000d
```
```
Installing: Virtual Machine Platform
Error: 0xc004000d
```

**Cause.** The `wsl.exe` that ships inside Windows (the "inbox" version) tries to
enable the Virtual Machine Platform feature through a path that fails on some
systems. The error code is licensing-flavoured but the real problem is the feature
installer.

**Fix.** Enable the features with DISM instead, from an **administrator**
PowerShell:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

If DISM also fails, use the graphical route: `Win+R` → `optionalfeatures` → tick
**Virtual Machine Platform** and **Windows Subsystem for Linux** → OK → reboot.

`1-enable-wsl.cmd` does the DISM route for you.

---

## 3. `--install: unrecognized option: web-download`

```
--install: unrecognized option: web-download
```

**Cause.** You are still running the inbox `wsl.exe`, which is older than the
flags the documentation describes. It accepts `--update --web-download` but not
`--install --web-download`.

**Fix.** Update WSL first, then install the distribution:

```powershell
wsl --update --web-download
wsl --set-default-version 2
wsl --install -d Ubuntu
```

If `wsl --update --web-download` itself fails, download the installer manually
from [github.com/microsoft/WSL/releases](https://github.com/microsoft/WSL/releases)
(the `.x64.msi` of the latest release) and run it.

---

## 4. `HCS_E_HYPERV_NOT_INSTALLED`

```
WSL2 no se puede iniciar porque la virtualización no está habilitada en esta máquina.
Código de error: Wsl/InstallDistro/Service/RegisterDistro/CreateVm/HCS/HCS_E_HYPERV_NOT_INSTALLED
```
```
WSL2 is not supported with your current machine configuration.
Error code: Wsl/InstallDistro/Service/RegisterDistro/CreateVm/HCS/HCS_E_HYPERV_NOT_INSTALLED
```

**Cause.** Two different things produce this identical message, and telling them
apart is the whole trick:

1. The Virtual Machine Platform feature is off, or the hypervisor is not set to
   launch at boot.
2. Hardware virtualization is disabled in the BIOS/UEFI.

**Diagnosis.** In an administrator PowerShell:

```powershell
systeminfo | Select-String "Hyper-V|firmware|virtualiz"
bcdedit /enum | Select-String hypervisorlaunchtype
Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform | Select-Object FeatureName, State
```

Read the results like this:

| What you see | What it means | Fix |
|---|---|---|
| `hypervisorlaunchtype: Off` (or absent) | Hypervisor disabled in software | `bcdedit /set hypervisorlaunchtype auto`, reboot |
| `VirtualMachinePlatform: Disabled` | Feature not enabled | `wsl --install --no-distribution`, reboot |
| `Virtualization enabled in firmware: No` | **BIOS** | See below |
| `A hypervisor has been detected` | Virtualization is working | Look elsewhere |

**The BIOS fix.** No script can do this; it happens before Windows starts. Shut
the machine **down** (not restart), power it on and press the setup key
repeatedly: HP `F10`, Dell `F2`, Lenovo `F1`/`F2`, ASUS/Acer `F2` or `Del`. Look
in **System Configuration**, **Advanced**, or **Security** for **Virtualization
Technology**, **Intel VT-x**, or **SVM Mode** (AMD). Set it to **Enabled**. If
**VT-d** / **Virtualization Technology for Directed I/O** is there, enable it too.
Save with `F10` and confirm.

---

## 5. `apt` fails with `403 Forbidden` inside Ubuntu

```
E: Failed to fetch http://archive.ubuntu.com/ubuntu/dists/... 403 Forbidden
E: The repository 'http://archive.ubuntu.com/ubuntu ... InRelease' is no longer signed.
```

**Cause.** Your network — typically a corporate, university, or filtered
connection — blocks or intercepts plain HTTP to Ubuntu's mirrors. HTTPS usually
passes.

**Fix.** Point the sources at HTTPS:

```bash
sudo sed -i 's|http://|https://|g' /etc/apt/sources.list.d/ubuntu.sources
sudo sed -i 's|http://|https://|g' /etc/apt/sources.list
sudo apt-get update
```

If that still fails, skip `apt` entirely for Bun — see the next entry.

---

## 6. `error: unzip is required to install bun`

```
error: unzip is required to install bun
```

**Cause.** Bun's official installer script unpacks a `.zip` and Ubuntu on WSL does
not ship `unzip`. If `apt` is also blocked (entry 5), you are stuck in a loop.

**Fix.** Install `unzip` if you can (`sudo apt-get install -y unzip`). If `apt` is
unavailable, download and extract Bun without it, using the Python that Ubuntu
already has:

```bash
mkdir -p ~/.bun/bin /tmp/bunx
curl -fsSL -o /tmp/bun.zip https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip
python3 -c 'import zipfile; zipfile.ZipFile("/tmp/bun.zip").extractall("/tmp/bunx")'
cp /tmp/bunx/bun-linux-x64/bun ~/.bun/bin/bun
chmod +x ~/.bun/bin/bun
~/.bun/bin/bun --version
```

If that binary crashes with an illegal-instruction error, your CPU lacks AVX2 —
use `bun-linux-x64-baseline.zip` instead (same commands, `baseline` in both the
URL and the extracted folder name).

---

## 7. `ENOENT: Executable not found in $PATH: "bun"` — the important one

Found in
`~/.cache/claude-cli-nodejs/*/mcp-logs-plugin-telegram-telegram/*.jsonl`:

```json
{"debug":"Connection failed after 52ms (ENOENT): Executable not found in $PATH: \"bun\""}
{"error":"Connection failed (ENOENT): Executable not found in $PATH: \"bun\""}
```

**Symptom.** The bot is completely silent. `/telegram:access` commands work, so
the plugin is clearly installed. `bun --version` works in your terminal. Nothing
suggests a PATH problem — and yet.

**Cause.** The plugin's `.mcp.json` declares `"command": "bun"`, and Claude Code
spawns that process with a **minimal environment**. Your shell's PATH — including
`~/.bun/bin` and `~/.local/bin`, and anything you exported before launching
`claude` — is not inherited. A Bun that lives in your home directory is invisible
to it.

**Fix.** Put Bun on a path that exists in the default environment:

```bash
sudo ln -sf $HOME/.bun/bin/bun /usr/local/bin/bun
sudo chmod 755 $HOME $HOME/.bun $HOME/.bun/bin
```

The `chmod` matters: the symlink is useless if the spawned process cannot traverse
into your home directory to reach the real binary.

**Verify the way Claude Code will see it** — an empty environment, not your shell:

```bash
env -i bash -c 'which bun && bun --version'
```

That must print `/usr/local/bin/bun` and a version. If it prints nothing, the fix
did not take, and Claude Code will still fail.

---

## 8. The channel connects, then dies twelve seconds later

```json
{"debug":"Successfully connected (transport: stdio) in 518ms"}
{"debug":"Channel notifications registered"}
{"debug":"Sending SIGINT to MCP server process"}
{"debug":"MCP server process exited cleanly"}
```

**Symptom.** The log proves the channel started correctly, and the bot still does
not answer. `pgrep -af server.ts` returns nothing.

**Cause.** The Claude Code session ended, and the channel server dies with it. In
practice this is almost always the folder-trust prompt:

```
Quick safety check: Is this a project you created or one you trust?
 ❯ No, exit
   Yes, I trust this folder
```

The **highlighted default is "No, exit"**. Pressing Enter out of habit quits
Claude — and takes the channel with it, silently.

**Fix.** Press the **down arrow** to select "Yes, I trust this folder" before
Enter. And keep the terminal window open: the bot only exists while that session
runs.

---

## 9. Messages pile up at Telegram and nothing consumes them

```json
{"ok":true,"result":{"url":"","pending_update_count":4}}
```

**How to check.** Inside Ubuntu:

```bash
T=$(cut -d= -f2- ~/.claude/channels/telegram/.env | tr -d '\r\n ')
curl -s "https://api.telegram.org/bot$T/getWebhookInfo"
pgrep -af server.ts
```

**Reading it.**

- `pending_update_count` above zero **and** no `server.ts` process → nobody is
  listening. Go back to entries 7 and 8.
- `pending_update_count` above zero **and** a `server.ts` process running → the
  server is up but not consuming. Usually another program is polling the same bot
  token (Telegram only delivers to one consumer at a time, and the loser sees
  `409 Conflict: terminated by other getUpdates request`). Stop the other program,
  or create a second bot with @BotFather for Claude.
- `"url"` is not empty → a webhook is registered on this bot and polling will
  never work. Clear it: `curl -s "https://api.telegram.org/bot$T/deleteWebhook"`.

---

## 10. `"ok":false` or `401 Unauthorized` from Telegram

**Cause.** The token is wrong, truncated, or has stray whitespace — a very common
copy-paste casualty, because the token contains a colon and is easy to clip.

**Fix.** Check it directly:

```bash
T=$(cut -d= -f2- ~/.claude/channels/telegram/.env | tr -d '\r\n ')
curl -s "https://api.telegram.org/bot$T/getMe"
```

A healthy token returns `"ok":true` with your bot's `username`. If not, rerun
`4-configure-telegram.cmd` and paste it again. If you suspect the token leaked,
revoke it in @BotFather with `/revoke` and use the new one.

---

## 11. Pairing: `pending` stays empty

```
/telegram:access pair <code>
→ there are no pending pairing requests right now (pending is empty)
```

**Cause.** The pairing code is generated **by the channel server** when it
receives your message. An empty `pending` means your message never reached it —
which is entry 7, 8, or 9, not a pairing problem.

**Fix.** Get the channel running first, confirmed by
`pgrep -af server.ts` returning a process. Then message the bot and the code
appears.

**Shortcut if you already know your Telegram user id.** You can authorize yourself
without pairing at all. Find your numeric id by messaging
[@userinfobot](https://t.me/userinfobot), then write it into the access file:

```bash
cat > ~/.claude/channels/telegram/access.json <<'JSON'
{
  "dmPolicy": "allowlist",
  "allowFrom": ["YOUR_NUMERIC_ID"],
  "groups": {},
  "pending": {}
}
JSON
```

Restart the bot and write to it directly.

---

## Where the evidence lives

When you need to know what actually happened, these four places tell you:

| Question | Where to look |
|---|---|
| Did Claude manage to start the channel? | `~/.cache/claude-cli-nodejs/*/mcp-logs-plugin-telegram-telegram/*.jsonl` |
| Is the channel server alive right now? | `pgrep -af server.ts` |
| Is Telegram holding messages nobody reads? | `getWebhookInfo` (see entry 9) |
| Who is allowed to talk to the bot? | `~/.claude/channels/telegram/access.json` |

`scripts/6-diagnose.cmd` checks all four in one run.
