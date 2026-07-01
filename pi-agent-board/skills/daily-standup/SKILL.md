---
name: daily-standup
description: Use when preparing Loren's daily standup, planning the day, or summarizing yesterday/today/blockers from ~/docs/work.
---

# Daily Standup

Use this skill to prepare a staff-engineer style daily standup across projects, repos, goals, and agent sessions.

## Source of truth

Default work root: `~/docs/work`.

Read, when present:

- `~/docs/work/tasks/active.md`
- `~/docs/work/tasks/waiting.md`
- `~/docs/work/tasks/done.md`
- yesterday's `~/docs/work/daily/YYYY-MM-DD.md`
- today's `~/docs/work/daily/YYYY-MM-DD.md`
- `~/docs/work/agent-board/sessions.json`
- `~/docs/work/agent-board/alerts.md`
- relevant `~/docs/work/initiatives/*/handoff.md` files

## Output files

Update or create:

- `~/docs/work/standups/YYYY-MM-DD.md`
- `~/docs/work/daily/YYYY-MM-DD.md`

## Standup format

```md
# Standup — YYYY-MM-DD

## Yesterday

## Today

## Blockers / needs attention

## Agent sessions ready for Loren

## Follow-ups

## Recommended focus
```

## Rules

- Be concise and useful for an actual work standup.
- Separate what Loren did from what agents did.
- Surface cross-project blockers and stale threads.
- Do not invent status. Ask if a task/session state is unclear.
- Preserve existing daily-note content; append or exact-edit rather than overwrite unless creating a new file.
