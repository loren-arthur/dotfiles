---
name: project-handoff
description: Use when preserving golden context for a long-running initiative, coding task, research thread, or cross-repo staff-engineering workstream.
---

# Project / Initiative Handoff

Use this skill to maintain durable context that survives session changes, compaction, interruptions, and switching between projects.

## Default locations

Default work root: `~/docs/work`.

For an initiative named `<initiative>`:

- `~/docs/work/initiatives/<initiative>/handoff.md`
- `~/docs/work/initiatives/<initiative>/decisions.md`
- `~/docs/work/initiatives/<initiative>/log.md`

If a session was spawned by agent-board, also inspect:

- `~/docs/work/agent-board/sessions.json`
- `~/docs/work/agent-board/events.jsonl`

## Handoff format

```md
# Handoff — <initiative/task>

## Goal

## Current status

## Golden context

## Constraints

## Decisions

## Active tasks / phases

## Completed work

## Files / repos touched

## Verification

## Blockers / open questions

## Next action
```

## Rules

- Handoff docs are for cold resume. Include enough context for a future agent or Loren to continue.
- Ground claims in observed files, commands, session outputs, or explicit user instructions.
- Do not bury blockers; put them in both `Current status` and `Blockers / open questions`.
- Update `Next action` whenever meaningful progress is made.
- Prefer exact edits that preserve prior useful context.
