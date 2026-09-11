# The Notion assistant layer

The Telegram bot alone is already useful. This layer turns it into an assistant
that keeps track of things for you across several jobs, inboxes and calendars.

It was designed for someone teaching at three universities with three separate
email accounts, but the shape works for anyone juggling more than one employer,
client, or project.

---

## The idea in one paragraph

The real problem with several jobs is not volume, it is **fragmentation**:
several accounts, several calendars, several ways people ask you for things, and
your head as the only place where it all comes together. The assistant becomes
that place. Everything it touches is tagged with the **front** it belongs to.

Three systems, three roles:

- **Google / Microsoft** stay the source of truth for email and calendar. The
  assistant reads them; it never duplicates them.
- **Notion** holds what email and calendar cannot: tasks, the context of each
  front, and the history of briefings.
- **Claude** is the engine: it reads, classifies, creates tasks, drafts replies,
  and writes the briefings.

---

## Step 1 — Consolidate your inboxes and calendars

The connectors see one Gmail account and one Microsoft account. Everything else
has to reach them.

**Email.** In each additional account, turn on automatic forwarding to your main
Gmail. Then in Gmail, create one filter per source domain that applies a label:

| Setting | Value |
|---|---|
| Filter | `from:(@yourdomain.edu)` |
| Action | Apply label `FRONT-NAME`, skip the inbox if you prefer |

Ask Claude to create the labels for you — with the Gmail connector it does it in
one message: *"create Gmail labels called A, B and C"*.

**Calendars.** Share each additional calendar with your main Google account, or
subscribe to it by ICS link (Outlook: Calendar → Share/Publish → copy the ICS
link; Google Calendar → Other calendars → From URL). Once subscribed, the
connector sees them all at once — which is what makes it possible to catch
clashes between two jobs, something almost invisible when you keep the calendars
apart.

---

## Step 2 — Create the Notion structure

Open Claude with the Notion connector enabled and paste this. It builds
everything in one go:

> Create a Notion page called **Personal assistant** with three databases inside
> it.
>
> **Fronts** — one row per area of work. Properties: Front (title, short code),
> Organization (text), Unit or department (text), Roles (multi-select), Work email
> (email), Mail system (select: Microsoft 365, Google Workspace, To confirm),
> Connection status (select: Connected, Pending), How it connects (multi-select:
> connector, forwarding, shared calendar), Mail label (text), Calendar (text),
> Current period (date range), Key contacts (text), Notes (text).
>
> **Tasks** — related to Fronts. Properties: Task (title), Status (select:
> To do, In progress, Waiting, Done, Cancelled), Priority (select: High, Medium,
> Low), Type (select — use my own categories), Due date (date), Front (relation to
> Fronts), Source (select: Email, Meeting, Chat, Manual, Assistant), Source link
> (URL), Created by assistant (checkbox), Notes (text), ID (unique id), Created
> (created time). Add three views: a board grouped by Front filtered to hide
> Done, a board grouped by Status, and a calendar by due date.
>
> **Briefings** — where you write my summaries. Properties: Briefing (title),
> Date (date), Type (select: Daily, Weekly, Mail triage), Fronts (relation to
> Fronts), Tasks generated (relation to Tasks), Needs attention (checkbox),
> Summary (text), Generated (created time).
>
> Then create one row in Fronts for each of these: [list your fronts here].

Adjust the wording to your own life. The important structural choices are: the
**Front relation** on every task, the **Source link** back to the email that
caused it, and the **Tasks generated** relation on briefings, which is what lets
you look back and see where a task came from.

---

## Step 3 — Write the rules

Put these on the root page, and in your Claude project instructions. They are what
keep the assistant predictable:

1. Everything it touches carries the label of its **front**.
2. The assistant **reads and proposes**; it does not take irreversible actions
   alone. It drafts email replies but never sends them; it suggests events but
   does not create or delete them without confirmation.
3. Mail triage starts on the day you switch it on. It does not try to rescue the
   backlog.
4. Requests from individuals and from people in authority become **a task with a
   date**; mass announcements are only summarized.
5. Draft replies match the tone of the context — plain and warm with students or
   juniors, formal with senior staff and administration.
6. The daily briefing is organized **by front, not by hour**, and warns about
   clashes between calendars.
7. The weekly review gives a balance per front, the load of the week ahead, and
   upcoming institutional deadlines.

Rule 2 is the one that makes the difference between a useful assistant and a
frightening one.

---

## Step 4 — Schedule the daily briefing

Claude's scheduled tasks run in the cloud on a fixed cadence — they do not need
your computer to be on, and they reach connectors, skills and plugins. Create one
with this prompt, at whatever hour you start your day:

> Write my daily briefing for today and save it as a new page in the **Briefings**
> database in Notion (type: Daily, today's date, related to the fronts it covers).
>
> Organize it **by front**, not by hour. For each front include: today's calendar
> events, emails that need a reply or an action from me, and tasks from the Tasks
> database that are due today or overdue.
>
> Open with an **alerts** section if any of these are true: two events overlap or
> are at different locations with no travel time between them, a task is overdue,
> or an institutional deadline is within a week.
>
> Turn every email that needs action into a task in the Tasks database, related
> to its front, with a due date when the email states one and a link back to the
> message. Mark them as created by the assistant. Do not send any email.
>
> Finish with a one-line summary in the page's Summary property, and tick "needs
> attention" if there were alerts.

Add a weekly variant on Fridays that reviews what closed, what slipped, and what
is coming.

The result arrives as a push notification and lands in Notion. And because the
Telegram bot reads the same Notion, you can ask it *"what did the briefing say
about the deadline?"* from your phone.

---

## What this is not

This does not replace your calendar or your inbox, and it should not try to. The
assistant is a reading and organizing layer on top of tools that already work.
Every attempt to make Notion the master copy of a calendar ends with two
calendars that disagree.
