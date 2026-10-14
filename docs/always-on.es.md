# Bot siempre encendido, sin tu computadora

En Windows el bot vive en una ventana de tu PC: si la apagas, el bot se calla.
Para tenerlo activo 24/7 hace falta **otro equipo que nunca se apague** y que
corra Linux. Claude Code y el plugin de Telegram funcionan ahí sin WSL ni parches
de Windows.

Este proyecto tiene una regla: **costo cero**. Nada de pruebas gratuitas que se
convierten en cobros ni cuentas de pago "por si acaso". Por eso esta guía **no**
recomienda servidores de pago, ni Google Cloud (para seguir usando su nivel
gratuito después de la prueba hay que pasar a una cuenta de pago, y hay reportes
de cobros pequeños inesperados).

## 1. Elige dónde va a vivir el bot

| Opción | Costo | Lo bueno | Lo malo |
|---|---|---|---|
| **A. Un equipo viejo en casa** (laptop, mini PC, Raspberry Pi 4/5) | 0 si ya lo tienes (solo la luz) | Sin tarjeta, sin cuentas, sin límites | Tiene que quedarse encendido y con internet |
| **B. Oracle Cloud "Always Free"** | 0 mientras **no** actualices la cuenta | Encendido en un centro de datos | Pide tarjeta solo para verificar identidad. Oracle puede **detener** máquinas gratuitas que pasan 7 días casi sin uso, y un bot de chat usa muy poco; si pasa, hay que volver a encenderla desde la consola. |

Si no quieres depender de ningún equipo, mira también la
[alternativa sin servidor](#alternativa-sin-servidor) al final.

### Opción A — Equipo en casa

1. Instala **Ubuntu 24.04** (laptop o mini PC) o **Raspberry Pi OS de 64 bits**
   (Raspberry Pi). Ambos son gratuitos.
2. Configúralo para que no se suspenda: en Ubuntu, *Configuración → Energía →
   Suspensión automática: desactivada*. En una laptop, déjala conectada a la
   corriente.
3. Abre una terminal en ese equipo y sigue el paso 2.

### Opción B — Oracle Cloud Always Free

1. Crea una cuenta en <https://www.oracle.com/cloud/free/>. Pide una tarjeta para
   verificar tu identidad. **Nunca pulses "Upgrade" ni "Pay As You Go"**: mientras
   la cuenta siga siendo gratuita, Oracle no puede cobrarte.
2. En la consola: **Compute → Instances → Create instance**. Imagen **Ubuntu
   24.04**. En *Shape* elige una marcada **Always Free-eligible**
   (`VM.Standard.E2.1.Micro` o `VM.Standard.A1.Flex`).
3. En *Add SSH keys* pulsa **Save private key** y guarda el archivo.
4. **Create**. Copia la *Public IP address* y conéctate desde PowerShell en tu PC:
   ```
   ssh -i RUTA\DEL\ARCHIVO.key ubuntu@IP-PUBLICA
   ```
5. Revisa en <https://www.oracle.com/cloud/free/> qué incluye hoy el nivel
   gratuito; las condiciones pueden cambiar.

Si un día el bot deja de responder, entra a la consola de Oracle y mira si la
instancia aparece **Stopped**: pulsa **Start** y el servicio arranca solo.

## 2. Instala PocketClaude en el equipo

En la terminal del equipo (o en la sesión SSH, si es Oracle) pega:

```bash
curl -fsSL https://raw.githubusercontent.com/jorgelfz714/pocketclaude/main/server/install.sh -o install.sh
bash install.sh
```

El script hace en siete pasos lo mismo que los scripts de Windows:

1. Instala `curl`, `unzip` y `tmux`, y agrega swap si la máquina tiene poca RAM.
2. Instala Claude Code.
3. Instala Bun y lo enlaza en `/usr/local/bin` (el mismo arreglo que en Windows).
4. Abre Claude para que inicies sesión. Si el equipo no tiene navegador, te
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

## Alternativa sin servidor

Si lo que necesitas es hablar con tu asistente desde el celular a cualquier hora,
la **app de Claude** (iOS/Android) ya lo hace sin ningún equipo encendido y sin
costo extra: viene con el plan de Claude que ya pagas. Conecta ahí Gmail, Google
Calendar, Google Drive y Notion en *Configuración → Conectores* y pregúntale lo
mismo que al bot. Lo que pierdes frente al bot es Telegram y el acceso a los
archivos de tu computadora.
