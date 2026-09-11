# Bitácora de errores

Cada error encontrado realmente al poner en marcha el canal de Telegram de Claude
Code en Windows, en el orden en que aparecieron. Cada entrada tiene el **texto
exacto del error** (para que los buscadores lo encuentren), la **causa** y la
**solución**.

---

## 1. El bot nunca recibe mensajes en Windows nativo

**Síntoma.** Claude Code corre, el plugin está instalado, el bot existe, y los
mensajes que le envías simplemente se ignoran. La salida sí funciona: si Claude
envía una respuesta, llega. La entrada nunca.

**Causa.** Un error en cómo Claude Code lanza el servidor MCP del canal en Windows
nativo: el bucle que consulta `getUpdates` de Telegram nunca arranca. Registrado en
[claude-code#39776](https://github.com/anthropics/claude-code/issues/39776) y
[claude-plugins-official#797](https://github.com/anthropics/claude-plugins-official/issues/797),
ambos abiertos al momento de escribir esto.

**Solución.** Correr Claude Code dentro de **WSL 2** en lugar de Windows nativo.
Eso es lo que automatiza este repositorio. No se conoce arreglo para la ruta de
Windows nativo.

---

## 2. `wsl --install` falla con el error `0xc004000d`

```
Instalando: Plataforma de máquina virtual
Error: 0xc004000d
```

**Causa.** El `wsl.exe` que viene dentro de Windows (la versión "de fábrica")
intenta activar la Plataforma de máquina virtual por una vía que falla en algunos
equipos. El código de error suena a licencias, pero el problema real está en el
instalador de la característica.

**Solución.** Activar las características con DISM, desde una PowerShell **como
administrador**:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Si DISM también falla, usa la vía gráfica: `Win+R` → `optionalfeatures` → marca
**Plataforma de máquina virtual** y **Subsistema de Windows para Linux** →
Aceptar → reinicia.

`1-enable-wsl.cmd` hace la vía DISM por ti.

---

## 3. `--install: unrecognized option: web-download`

```
--install: unrecognized option: web-download
```

**Causa.** Sigues usando el `wsl.exe` de fábrica, más antiguo que las opciones que
describe la documentación. Acepta `--update --web-download` pero no
`--install --web-download`.

**Solución.** Actualizar WSL primero y después instalar la distribución:

```powershell
wsl --update --web-download
wsl --set-default-version 2
wsl --install -d Ubuntu
```

Si `wsl --update --web-download` falla, descarga el instalador a mano desde
[github.com/microsoft/WSL/releases](https://github.com/microsoft/WSL/releases)
(el archivo `.x64.msi` de la última versión) y ejecútalo.

---

## 4. `HCS_E_HYPERV_NOT_INSTALLED`

```
WSL2 no se puede iniciar porque la virtualización no está habilitada en esta máquina.
Código de error: Wsl/InstallDistro/Service/RegisterDistro/CreateVm/HCS/HCS_E_HYPERV_NOT_INSTALLED
```

**Causa.** Dos cosas distintas producen este mensaje idéntico, y distinguirlas es
todo el truco:

1. La característica Plataforma de máquina virtual está apagada, o el hipervisor
   no arranca con el sistema.
2. La virtualización por hardware está desactivada en el BIOS/UEFI.

**Diagnóstico.** En PowerShell como administrador:

```powershell
systeminfo | Select-String "Hyper-V|firmware|virtualiz"
bcdedit /enum | Select-String hypervisorlaunchtype
Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform | Select-Object FeatureName, State
```

Cómo leer el resultado:

| Lo que ves | Qué significa | Solución |
|---|---|---|
| `hypervisorlaunchtype: Off` (o no aparece) | Hipervisor apagado por software | `bcdedit /set hypervisorlaunchtype auto`, reiniciar |
| `VirtualMachinePlatform: Disabled` | Característica sin activar | `wsl --install --no-distribution`, reiniciar |
| `Se habilitó la virtualización en el firmware: No` | **BIOS** | Ver abajo |
| `Se ha detectado un hipervisor` | La virtualización funciona | Buscar en otro lado |

**El arreglo del BIOS.** Ningún script puede hacerlo; ocurre antes de que Windows
arranque. **Apaga** la máquina (no reiniciar), enciéndela y pulsa repetidamente la
tecla de configuración: HP `F10`, Dell `F2`, Lenovo `F1`/`F2`, ASUS/Acer `F2` o
`Supr`. Busca en **System Configuration**, **Advanced** o **Security** la opción
**Virtualization Technology**, **Intel VT-x** o **SVM Mode** (AMD) y ponla en
**Enabled**. Si aparece **VT-d** / **Virtualization Technology for Directed I/O**,
actívala también. Guarda con `F10` y confirma.

---

## 5. `apt` falla con `403 Forbidden` dentro de Ubuntu

```
E: Failed to fetch http://archive.ubuntu.com/ubuntu/dists/... 403 Forbidden
E: The repository 'http://archive.ubuntu.com/ubuntu ... InRelease' is no longer signed.
```

**Causa.** Tu red — típicamente corporativa, universitaria o con filtrado —
bloquea o intercepta el HTTP plano hacia los espejos de Ubuntu. HTTPS suele pasar.

**Solución.** Apuntar las fuentes a HTTPS:

```bash
sudo sed -i 's|http://|https://|g' /etc/apt/sources.list.d/ubuntu.sources
sudo sed -i 's|http://|https://|g' /etc/apt/sources.list
sudo apt-get update
```

Si aun así falla, sáltate `apt` por completo para Bun: ver la entrada siguiente.

---

## 6. `error: unzip is required to install bun`

```
error: unzip is required to install bun
```

**Causa.** El instalador oficial de Bun descomprime un `.zip` y Ubuntu sobre WSL
no trae `unzip`. Si además `apt` está bloqueado (entrada 5), quedas en un círculo
cerrado.

**Solución.** Instala `unzip` si puedes (`sudo apt-get install -y unzip`). Si
`apt` no está disponible, descarga y extrae Bun sin él, usando el Python que
Ubuntu ya trae:

```bash
mkdir -p ~/.bun/bin /tmp/bunx
curl -fsSL -o /tmp/bun.zip https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip
python3 -c 'import zipfile; zipfile.ZipFile("/tmp/bun.zip").extractall("/tmp/bunx")'
cp /tmp/bunx/bun-linux-x64/bun ~/.bun/bin/bun
chmod +x ~/.bun/bin/bun
~/.bun/bin/bun --version
```

Si ese binario revienta con un error de instrucción ilegal, tu procesador no tiene
AVX2: usa `bun-linux-x64-baseline.zip` (los mismos comandos, con `baseline` tanto
en la URL como en el nombre de la carpeta extraída).

---

## 7. `ENOENT: Executable not found in $PATH: "bun"` — el importante

Aparece en
`~/.cache/claude-cli-nodejs/*/mcp-logs-plugin-telegram-telegram/*.jsonl`:

```json
{"debug":"Connection failed after 52ms (ENOENT): Executable not found in $PATH: \"bun\""}
{"error":"Connection failed (ENOENT): Executable not found in $PATH: \"bun\""}
```

**Síntoma.** El bot está completamente mudo. Los comandos `/telegram:access`
funcionan, así que el plugin evidentemente está instalado. `bun --version`
responde en tu terminal. Nada sugiere un problema de PATH, y sin embargo.

**Causa.** El `.mcp.json` del plugin declara `"command": "bun"`, y Claude Code
lanza ese proceso con un **entorno mínimo**. El PATH de tu shell — incluidos
`~/.bun/bin` y `~/.local/bin`, y cualquier cosa que hayas exportado antes de
lanzar `claude` — no se hereda. Un Bun que vive en tu carpeta personal le resulta
invisible.

**Solución.** Poner Bun en una ruta que exista en el entorno por defecto:

```bash
sudo ln -sf $HOME/.bun/bin/bun /usr/local/bin/bun
sudo chmod 755 $HOME $HOME/.bun $HOME/.bun/bin
```

El `chmod` importa: el enlace no sirve de nada si el proceso lanzado no puede
atravesar tu carpeta personal para llegar al binario real.

**Verifícalo como lo verá Claude Code** — con un entorno vacío, no con tu shell:

```bash
env -i bash -c 'which bun && bun --version'
```

Eso debe imprimir `/usr/local/bin/bun` y una versión. Si no imprime nada, el
arreglo no tomó efecto y Claude Code seguirá fallando.

---

## 8. El canal conecta y muere doce segundos después

```json
{"debug":"Successfully connected (transport: stdio) in 518ms"}
{"debug":"Channel notifications registered"}
{"debug":"Sending SIGINT to MCP server process"}
{"debug":"MCP server process exited cleanly"}
```

**Síntoma.** El registro demuestra que el canal arrancó bien, y el bot sigue sin
responder. `pgrep -af server.ts` no devuelve nada.

**Causa.** La sesión de Claude Code terminó, y el servidor del canal muere con
ella. En la práctica esto es casi siempre la pregunta de confianza de la carpeta:

```
Quick safety check: Is this a project you created or one you trust?
 ❯ No, exit
   Yes, I trust this folder
```

**La opción marcada por defecto es "No, exit".** Pulsar Enter por costumbre cierra
Claude, y se lleva el canal por delante sin avisar.

**Solución.** Pulsa la **flecha abajo** para elegir "Yes, I trust this folder"
antes de Enter. Y deja la ventana del terminal abierta: el bot solo existe
mientras esa sesión corre.

---

## 9. Los mensajes se acumulan en Telegram y nadie los consume

```json
{"ok":true,"result":{"url":"","pending_update_count":4}}
```

**Cómo revisarlo.** Dentro de Ubuntu:

```bash
T=$(cut -d= -f2- ~/.claude/channels/telegram/.env | tr -d '\r\n ')
curl -s "https://api.telegram.org/bot$T/getWebhookInfo"
pgrep -af server.ts
```

**Cómo leerlo.**

- `pending_update_count` mayor que cero **y** sin proceso `server.ts` → nadie está
  escuchando. Vuelve a las entradas 7 y 8.
- `pending_update_count` mayor que cero **y** con `server.ts` corriendo → el
  servidor está arriba pero no consume. Normalmente otro programa está usando el
  mismo token (Telegram entrega a un solo consumidor a la vez, y el perdedor ve
  `409 Conflict: terminated by other getUpdates request`). Apaga el otro programa,
  o crea un segundo bot en @BotFather para Claude.
- `"url"` no está vacío → hay un webhook registrado en ese bot y el sondeo nunca
  funcionará. Bórralo: `curl -s "https://api.telegram.org/bot$T/deleteWebhook"`.

---

## 10. Telegram responde `"ok":false` o `401 Unauthorized`

**Causa.** El token está mal, cortado, o tiene espacios de más: una víctima muy
común del copiar y pegar, porque el token lleva dos puntos y es fácil recortarlo.

**Solución.** Compruébalo directamente:

```bash
T=$(cut -d= -f2- ~/.claude/channels/telegram/.env | tr -d '\r\n ')
curl -s "https://api.telegram.org/bot$T/getMe"
```

Un token sano devuelve `"ok":true` con el `username` de tu bot. Si no, vuelve a
ejecutar `4-configure-telegram.cmd` y pégalo otra vez. Si sospechas que se filtró,
revócalo en @BotFather con `/revoke` y usa el nuevo.

---

## 11. Emparejamiento: `pending` sigue vacío

```
/telegram:access pair <código>
→ there are no pending pairing requests right now (pending is empty)
```

**Causa.** El código de emparejamiento lo genera **el servidor del canal** cuando
recibe tu mensaje. Que `pending` esté vacío significa que tu mensaje nunca le
llegó, lo cual es la entrada 7, 8 o 9, no un problema de emparejamiento.

**Solución.** Primero pon el canal a funcionar, confirmado con
`pgrep -af server.ts` devolviendo un proceso. Entonces escríbele al bot y el
código aparece.

**Atajo si ya conoces tu identificador de Telegram.** Puedes autorizarte sin
emparejar. Consigue tu id numérico escribiéndole a
[@userinfobot](https://t.me/userinfobot) y escríbelo en el archivo de acceso:

```bash
cat > ~/.claude/channels/telegram/access.json <<'JSON'
{
  "dmPolicy": "allowlist",
  "allowFrom": ["TU_ID_NUMERICO"],
  "groups": {},
  "pending": {}
}
JSON
```

Reinicia el bot y escríbele directamente.

---

## Dónde está la evidencia

Cuando necesites saber qué pasó de verdad, estos cuatro lugares te lo dicen:

| Pregunta | Dónde mirar |
|---|---|
| ¿Claude logró arrancar el canal? | `~/.cache/claude-cli-nodejs/*/mcp-logs-plugin-telegram-telegram/*.jsonl` |
| ¿El servidor del canal está vivo ahora? | `pgrep -af server.ts` |
| ¿Telegram guarda mensajes que nadie lee? | `getWebhookInfo` (ver entrada 9) |
| ¿Quién puede hablarle al bot? | `~/.claude/channels/telegram/access.json` |

`scripts/6-diagnose.cmd` revisa los cuatro de una sola pasada.
