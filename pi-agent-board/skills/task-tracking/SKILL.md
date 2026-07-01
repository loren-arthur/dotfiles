---
name: task-tracking
description: Use when adding, updating, completing, prioritizing, blocking, or reviewing Loren's personal work tasks under ~/docs/work/tasks.
---

# Task Tracking

Use this skill to manage Loren's cross-project work queue.

## Source of truth

Default work root: `~/docs/work`.

Task files:

- `~/docs/work/tasks/active.md`
- `~/docs/work/tasks/waiting.md`
- `~/docs/work/tasks/backlog.md`
- `~/docs/work/tasks/done.md`

## Task conventions

Prefer markdown checklists with enough metadata to resume cold:

```md
- [ ] Task title
  - initiative: name
  - project/repo: optional
  - status: active | waiting | blocked | done
  - next: concrete next action
  - blocker: optional
  - updated: YYYY-MM-DD
```

## Rules

- Every active task should have a concrete `next` action.
- Move completed tasks to `done.md` with completion date.
- Move blocked/waiting tasks to `waiting.md` or clearly mark them in place.
- Preserve human-written context.
- Prefer exact edits to whole-file rewrites.
- If priority/status is ambiguous, ask Loren rather than inventing it.
