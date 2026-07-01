---
name: agent-board-self-improvement
description: Use when Loren wants to improve, debug, extend, refactor, or teach the pi-agent-board workflow/extension/skills/prompts while using it live.
---

# Agent Board Self-Improvement

Use this skill when working on the live `pi-agent-board` package itself.

## Package location

Default source repo:

`~/repo/pi-agent-board`

Key files:

- `package.json` — pi package manifest
- `extensions/agent-board.ts` — extension tools, commands, tmux spawning, board state, lifecycle events
- `skills/*/SKILL.md` — procedural memory for recurring workflows
- `prompts/*.md` — prompt-template workflows
- `~/docs/work/agent-board/` — runtime board state, prompts, events, alerts

Read [references/OPERATING.md](references/OPERATING.md) before making non-trivial changes.

## Live-edit workflow

1. Inspect the relevant source files in `~/repo/pi-agent-board`.
2. Make the smallest coherent change.
3. Explain whether the change requires `/reload`.
4. Ask Loren to run `/reload` after extension changes, unless he explicitly asks you to do it from the orchestrator session.
5. After reload, test the behavior in a small way.
6. Update this skill or its references when a durable operating rule emerges.

## What belongs where

- Extension code: deterministic tools/commands/hooks, tmux integration, board state writes.
- Skills: reusable procedures and operating doctrine.
- Prompts: ergonomic one-shot workflows.
- `~/docs/work`: current tasks, initiatives, handoffs, daily notes, and runtime board state.

## Safety rules

- Do not add a custom LLM loop, React UI, or daemon unless Loren explicitly decides to.
- Prefer pi extension/tool/resource primitives over bespoke orchestration code.
- Keep interactive spawned-agent prompts lightweight; heavy output contracts are for headless workers.
- Board coordination files must be updated through deterministic code paths, not ad-hoc agent edits.
- If multiple pi sessions may write a file, use locking or an append-only log.
