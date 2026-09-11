# La capa de asistente en Notion

El bot de Telegram por sí solo ya es útil. Esta capa lo convierte en un asistente
que te lleva la cuenta de las cosas a través de varios trabajos, bandejas de
entrada y calendarios.

Se diseñó para alguien que da clases en tres universidades con tres cuentas de
correo distintas, pero la forma sirve para cualquiera que maneje más de un
empleador, cliente o proyecto.

---

## La idea en un párrafo

El problema real de tener varios trabajos no es el volumen, es la
**fragmentación**: varias cuentas, varios calendarios, varias maneras en que la
gente te pide cosas, y tu cabeza como único lugar donde todo se junta. El
asistente pasa a ser ese lugar. Todo lo que toca lleva la etiqueta del **frente**
al que pertenece.

Tres sistemas, tres papeles:

- **Google / Microsoft** siguen siendo la fuente de verdad del correo y la agenda.
  El asistente los lee; nunca los duplica.
- **Notion** guarda lo que el correo y el calendario no pueden: tareas, el
  contexto de cada frente y el historial de resúmenes.
- **Claude** es el motor: lee, clasifica, crea tareas, redacta borradores y
  escribe los briefings.

---

## Paso 1 — Consolidar bandejas y calendarios

Los conectores ven una cuenta de Gmail y una de Microsoft. Todo lo demás tiene que
llegar hasta ahí.

**Correo.** En cada cuenta adicional, activa el reenvío automático hacia tu Gmail
principal. Después, en Gmail, crea un filtro por dominio de origen que aplique una
etiqueta:

| Ajuste | Valor |
|---|---|
| Filtro | `from:(@tudominio.edu)` |
| Acción | Aplicar etiqueta `NOMBRE-DEL-FRENTE`, y saltar la bandeja si prefieres |

Pídele a Claude que cree las etiquetas: con el conector de Gmail lo hace en un
mensaje: *"crea las etiquetas A, B y C en Gmail"*.

**Calendarios.** Comparte cada calendario adicional con tu cuenta principal de
Google, o suscríbete por enlace ICS (Outlook: Calendario → Compartir/Publicar →
copiar el enlace ICS; Google Calendar → Otros calendarios → Desde URL). Una vez
suscritos, el conector los ve todos a la vez, que es justo lo que permite detectar
choques entre dos trabajos: algo casi invisible cuando mantienes los calendarios
separados.

---

## Paso 2 — Crear la estructura en Notion

Abre Claude con el conector de Notion activo y pega esto. Construye todo de una
sola vez:

> Crea una página de Notion llamada **Asistente personal** con tres bases de datos
> dentro.
>
> **Frentes** — una fila por área de trabajo. Propiedades: Frente (título, sigla
> corta), Institución (texto), Unidad o facultad (texto), Roles (multi-select),
> Correo institucional (email), Sistema de correo (select: Microsoft 365, Google
> Workspace, Por confirmar), Conexión con el asistente (select: Conectado,
> Pendiente), Cómo se conecta (multi-select: conector, reenvío, calendario
> compartido), Etiqueta de correo (texto), Calendario (texto), Periodo actual
> (rango de fechas), Contactos clave (texto), Notas (texto).
>
> **Tareas** — relacionada con Frentes. Propiedades: Tarea (título), Estado
> (select: Pendiente, En curso, En espera, Hecha, Cancelada), Prioridad (select:
> Alta, Media, Baja), Tipo (select — usa mis propias categorías), Fecha límite
> (fecha), Frente (relación con Frentes), Origen (select: Correo, Reunión, Chat,
> Manual, Asistente), Enlace origen (URL), Creada por asistente (casilla), Notas
> (texto), ID (id único), Creada (fecha de creación). Agrega tres vistas: un
> tablero agrupado por Frente que oculte las hechas, un tablero agrupado por
> Estado, y un calendario por fecha límite.
>
> **Briefings** — donde escribes mis resúmenes. Propiedades: Briefing (título),
> Fecha (fecha), Tipo (select: Diario, Semanal, Triage de correo), Frentes
> (relación con Frentes), Tareas generadas (relación con Tareas), Requiere
> atención (casilla), Resumen (texto), Generado (fecha de creación).
>
> Luego crea una fila en Frentes por cada uno de estos: [lista aquí tus frentes].

Ajusta el texto a tu propia vida. Las decisiones estructurales que importan son:
la **relación con Frente** en cada tarea, el **enlace al origen** que apunta al
correo que la provocó, y la relación **Tareas generadas** en los briefings, que es
lo que te permite mirar atrás y saber de dónde salió cada cosa.

---

## Paso 3 — Escribir las reglas

Ponlas en la página raíz, y también en las instrucciones de tu proyecto de Claude.
Son las que mantienen al asistente predecible:

1. Todo lo que toca lleva la etiqueta de su **frente**.
2. El asistente **lee y propone**; no ejecuta acciones irreversibles solo. Redacta
   borradores de correo pero nunca los envía; sugiere eventos pero no los crea ni
   borra sin confirmación.
3. El triage de correo arranca el día que lo enciendes. No intenta rescatar el
   pasado.
4. Las solicitudes de personas y los pedidos de autoridades generan **tarea con
   fecha**; los comunicados masivos solo se resumen.
5. Los borradores adaptan el tono al contexto: cercano y claro con estudiantes o
   personas a tu cargo, formal con autoridades y administración.
6. El briefing diario se organiza **por frente, no por hora**, y avisa de choques
   entre calendarios.
7. La revisión semanal da balance por frente, carga de la semana siguiente e hitos
   institucionales próximos.

La regla 2 es la que marca la diferencia entre un asistente útil y uno que da
miedo.

---

## Paso 4 — Programar el briefing diario

Las tareas programadas de Claude corren en la nube con la frecuencia que definas:
no necesitan que tu computadora esté encendida, y alcanzan conectores, skills y
plugins. Crea una con este prompt, a la hora en que empiezas tu día:

> Escribe mi briefing diario de hoy y guárdalo como una página nueva en la base
> **Briefings** de Notion (tipo: Diario, fecha de hoy, relacionada con los frentes
> que cubra).
>
> Organízalo **por frente**, no por hora. Para cada frente incluye: los eventos de
> hoy en el calendario, los correos que requieren respuesta o acción mía, y las
> tareas de la base Tareas que vencen hoy o están vencidas.
>
> Empieza con una sección de **alertas** si se cumple alguna de estas: dos eventos
> se solapan o están en lugares distintos sin tiempo de traslado entre ellos, hay
> una tarea vencida, o se acerca un plazo institucional dentro de una semana.
>
> Convierte cada correo que requiera acción en una tarea de la base Tareas,
> relacionada con su frente, con fecha límite cuando el correo la indique y un
> enlace de vuelta al mensaje. Márcalas como creadas por el asistente. No envíes
> ningún correo.
>
> Termina con un resumen de una línea en la propiedad Resumen de la página, y
> marca "requiere atención" si hubo alertas.

Agrega una variante semanal los viernes que revise qué se cerró, qué se corrió de
fecha y qué viene.

El resultado te llega como notificación push y queda en Notion. Y como el bot de
Telegram lee ese mismo Notion, puedes preguntarle desde el celular *"¿qué decía el
briefing sobre el plazo?"*.

---

## Lo que esto no es

Esto no reemplaza tu calendario ni tu bandeja de entrada, y no debería intentarlo.
El asistente es una capa de lectura y organización sobre herramientas que ya
funcionan. Todo intento de convertir Notion en la copia maestra de un calendario
termina con dos calendarios que no coinciden.
