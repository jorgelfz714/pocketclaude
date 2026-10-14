# Bot siempre encendido, sin tu computadora

En Windows el bot vive en una ventana de tu PC: si la apagas, el bot se calla.
Para tenerlo activo 24/7, instálalo en un **servidor Linux en la nube**, una
computadora pequeña que nunca se apaga. Claude Code y el plugin de Telegram
funcionan ahí sin WSL ni parches de Windows.

## 1. Consigue un servidor

Cualquier servidor con **Ubuntu 22.04 o 24.04** sirve. Dos opciones:

| Opción | Costo | Notas |
|---|---|---|
| **Google Cloud, e2-micro** | Gratis (nivel "Always Free") | 1 GB de RAM; el script agrega memoria swap. Solo en las regiones `us-west1`, `us-central1` o `us-east1`. Pide tarjeta para verificar identidad. |
| Hetzner, DigitalOcean, Vultr, etc. | Unos USD 4–6 al mes | Más RAM, menos pasos. |

Con Google Cloud:

1. Entra a <https://console.cloud.google.com> → **Compute Engine** → **VM
   instances** → **Create instance**.
2. Región `us-central1` (o `us-west1` / `us-east1`), tipo de máquina **e2-micro**.
3. En **Boot disk** elige **Ubuntu 24.04 LTS**, disco *Standard persistent* de
   30 GB.
4. **Create**. Cuando aparezca, pulsa el botón **SSH**: se abre una terminal en tu
   navegador. No necesitas instalar nada en tu PC.

Revisa las condiciones actuales del nivel gratuito en
<https://cloud.google.com/free> antes de crear la máquina.

## 2. Instala PocketClaude en el servidor

En la terminal SSH pega:

```bash
curl -fsSL https://raw.githubusercontent.com/jorgelfz714/pocketclaude/main/server/install.sh -o install.sh
bash install.sh
```

El script hace en siete pasos lo mismo que los scripts de Windows:

1. Instala `curl`, `unzip` y `tmux`, y agrega swap si la máquina tiene poca RAM.
2. Instala Claude Code.
3. Instala Bun y lo enlaza en `/usr/local/bin` (el mismo arreglo que en Windows).
4. Abre Claude para que inicies sesión. Como el servidor no tiene navegador, te
   muestra un **enlace**: ábrelo en tu celular o PC, inicia sesión, copia el código
   y pégalo en la terminal. Si pregunta si confías en la carpeta, elige **sí**.
   Luego escribe `/exit`.
5. Instala el plugin de Telegram.
6. Te pide el token de tu bot (el mismo que ya usas; está en @BotFather →
   `/mybots` → tu bot → **API Token**) y lo verifica: debes ver `"ok":true`.
7. Crea un servicio del sistema que mantiene el bot encendido, lo reinicia si se
   cae y lo arranca solo cuando el servidor se reinicia.

## 3. Apaga el bot de tu PC

Telegram entrega los mensajes a un solo programa por bot. Escribe `/exit` en la
ventana de `5-start-bot.cmd` de tu PC y no la vuelvas a abrir mientras el servidor
esté activo. Si los dos corren a la vez, se pelean los mensajes (`409 Conflict`).

## 4. Empareja de nuevo (una sola vez)

El bot corre dentro de una consola `tmux` en el servidor. Para entrar:

```bash
tmux attach -t pocketclaude
```

1. Escríbele a tu bot desde Telegram: te responde con un código.
2. En la consola: `/telegram:access pair <código>`
3. Luego: `/telegram:access policy allowlist`
4. Si conectaste Notion: `/mcp` y autorízalo con el enlace que te muestre.

Para salir **sin apagar el bot**: `Ctrl+B` y luego `D`. Ya puedes cerrar la
ventana SSH y apagar tu PC.

## Comandos útiles

| Para | Comando |
|---|---|
| Ver la consola del bot | `tmux attach -t pocketclaude` (salir: `Ctrl+B`, `D`) |
| ¿Está encendido? | `systemctl status pocketclaude` |
| Reiniciarlo | `sudo systemctl restart pocketclaude` |
| Apagarlo | `sudo systemctl stop pocketclaude` |
| Que no arranque solo | `sudo systemctl disable pocketclaude` |
| Volver a configurar (token, Notion) | `bash install.sh` |

## Si el bot no responde

- **Se quedó esperando un permiso.** Si le pediste algo que Claude necesita
  aprobar y la aprobación no llegó a Telegram, queda esperando en la consola.
  Entra con `tmux attach -t pocketclaude`, apruébalo y, si es una herramienta que
  usas seguido, elige la opción de no volver a preguntar.
- **Se cerró la sesión de Claude.** Entra a la consola: si ves un mensaje de
  inicio de sesión, sigue el enlace como en el paso 2.
- **Volviste a encender el bot en tu PC.** Apágalo; solo puede haber uno.
- El resto de errores y sus soluciones están en
  [troubleshooting.es.md](troubleshooting.es.md); los comandos de diagnóstico de
  `6-diagnose.cmd` funcionan igual en el servidor, sin el prefijo `wsl`.

## Seguridad

El servidor guarda tu sesión de Claude y el token del bot, y el bot puede usar tus
cuentas conectadas. Trátalo como tu PC: no compartas el acceso SSH, deja la
política en `allowlist` y, si el token se filtra, revócalo en @BotFather con
`/revoke` y vuelve a ejecutar `bash install.sh`.
