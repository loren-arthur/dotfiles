# pi-agent-board Operating Notes

## Purpose

`pi-agent-board` is a personal staff-engineering control plane on top of pi.

It should remain small:

- pi is the agent runtime
- tmux is the interactive session surface
- `~/docs/work` is the human-readable work state
- this package provides tools, commands, skills, and prompts to connect those pieces

## Current architecture

```text
global orchestrator pi session
  ├─ uses spawn_interactive_agent to open human-steerable pi sessions in tmux
  ├─ reads/writes ~/docs/work task and handoff files
  ├─ tracks spawned sessions in ~/docs/work/agent-board/sessions.json
  └─ receives lifecycle events in ~/docs/work/agent-board/events.jsonl
```

## Source vs runtime state

Source package:

`~/repo/pi-agent-board`

Runtime state:

`~/docs/work/agent-board`

Do not confuse them. Source changes require `/reload`; runtime state changes do not.

## Reload behavior

When editing `extensions/agent-board.ts`, the currently loaded extension code does not change until pi reloads resources.

Use `/reload` after source edits. After reload:

- future commands/events/tool calls use the new extension version
- old in-flight command frames should be treated as stale
- spawned pi sessions started after reload get the new extension code

Skills and prompt templates also reload with `/reload`.

## Interactive spawned agents

Interactive spawned agents are for Loren to steer directly. Their kickoff prompt should be short and human-friendly:

- role
- assignment
- cwd
- relevant handoff/context path if known
- how to start
- context discipline

Do not include board internals, session ids, event paths, or mandatory final response contracts unless the task specifically needs them.

## Headless workers

Headless workers are different. They may need:

- strict output contract
- report path
- status protocol
- bounded task scope
- verification requirements

Keep the interactive and headless prompt builders separate when headless support is added.

## Board state discipline

Current files:

- `sessions.json` — current session registry
- `events.jsonl` — append-only lifecycle/event log
- `alerts.md` — human-readable alerts
- `prompts/*.md` — generated kickoff prompts

Rules:

- Source code should write board coordination state through locked helper functions.
- Agents should not directly rewrite `sessions.json`.
- Human docs such as task files and handoffs may be edited normally, with care.

## Design constraints

Avoid rebuilding:

- custom TUI
- React loop
- custom LLM loop
- custom session database unless locked JSON/JSONL becomes insufficient
- replacement terminal multiplexer

Prefer:

- pi extensions for tools/commands/hooks
- pi skills for durable procedures
- pi prompt templates for ergonomic workflows
- tmux for windows
- markdown for human-readable plans/tasks/handoffs
