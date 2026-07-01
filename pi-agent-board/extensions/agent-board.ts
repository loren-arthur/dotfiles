import { execFileSync } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

type BoardStatus = "launched" | "active" | "running" | "ready_for_review" | "closed" | "blocked" | "done" | "dead";

type BoardInterface = "pi" | "pim";

type BoardSession = {
  id: string;
  role: string;
  title: string;
  initiative?: string;
  cwd: string;
  status: BoardStatus;
  tmuxSession?: string;
  tmuxWindowIndex?: string;
  tmuxWindowName?: string;
  piSessionName: string;
  promptPath: string;
  handoffPath?: string;
  model?: string;
  interface?: BoardInterface;
  pimPluginPath?: string;
  createdAt: string;
  updatedAt: string;
  lastEvent?: string;
  lastSummary?: string;
};

type BoardState = {
  version: 1;
  sessions: BoardSession[];
};

const StartInteractiveSchema = Type.Object({
  role: Type.String({ description: "Agent role, e.g. coding, research, planning, review, verification." }),
  title: Type.String({ description: "Human-readable task/session title." }),
  prompt: Type.String({ description: "Initial assignment for the spawned interactive pi session." }),
  cwd: Type.Optional(Type.String({ description: "Working directory for the spawned session. Defaults to the current cwd." })),
  initiative: Type.Optional(Type.String({ description: "Portfolio initiative/workstream this session belongs to." })),
  handoffPath: Type.Optional(Type.String({ description: "Durable handoff/context file this agent should read/update." })),
  model: Type.Optional(Type.String({ description: "Optional pi model override for this session." })),
  interface: Type.Optional(Type.String({ description: "Launch UI: 'pi' for the normal terminal TUI (default) or 'pim' for the Neovim pim adapter." })),
  pimPluginPath: Type.Optional(Type.String({ description: "Path to the pim Neovim plugin when interface='pim'. Defaults to ~/repo/pim or $PIM_PLUGIN_PATH." })),
  tmuxSession: Type.Optional(Type.String({ description: "tmux session to create the window in. Defaults to current tmux session or $AGENT_BOARD_TMUX_SESSION." })),
  windowName: Type.Optional(Type.String({ description: "Optional tmux window name. Defaults to '<role>:<short title>'." })),
  placement: Type.Optional(Type.String({ description: "Where to place the tmux window: 'after-current' (default) or 'end'." })),
  focus: Type.Optional(Type.Boolean({ description: "Switch to the new tmux window immediately. Default false.", default: false })),
});

const ListSchema = Type.Object({
  status: Type.Optional(Type.String({ description: "Optional status filter." })),
  initiative: Type.Optional(Type.String({ description: "Optional initiative filter." })),
});

const SessionIdSchema = Type.Object({
  id: Type.String({ description: "Agent board session id." }),
});

const UpdateStatusSchema = Type.Object({
  id: Type.String({ description: "Agent board session id." }),
  status: Type.String({ description: "New status." }),
  summary: Type.Optional(Type.String({ description: "Optional status summary." })),
});

function expandHome(p: string): string {
  if (p === "~") return os.homedir();
  if (p.startsWith("~/")) return path.join(os.homedir(), p.slice(2));
  return p;
}

function boardRoot(): string {
  return path.resolve(expandHome(process.env.AGENT_BOARD_ROOT || "~/docs/work"));
}

function boardDir(): string {
  return path.join(boardRoot(), "agent-board");
}

function sessionsPath(): string {
  return path.join(boardDir(), "sessions.json");
}

function boardViewPath(): string {
  return path.join(boardDir(), "board.md");
}

function lockDir(): string {
  return path.join(boardDir(), ".lock");
}

function withBoardLock<T>(fn: () => T): T {
  ensureBoardDirsNoState();
  const dir = lockDir();
  const start = Date.now();
  while (true) {
    try {
      fs.mkdirSync(dir);
      fs.writeFileSync(path.join(dir, "owner"), `${process.pid}\n${new Date().toISOString()}\n`, "utf8");
      break;
    } catch (err: any) {
      if (err?.code !== "EEXIST") throw err;
      // Recover stale locks left by crashed pi/tmux sessions.
      try {
        const ageMs = Date.now() - fs.statSync(dir).mtimeMs;
        if (ageMs > 30_000) {
          fs.rmSync(dir, { recursive: true, force: true });
          continue;
        }
      } catch {
        fs.rmSync(dir, { recursive: true, force: true });
        continue;
      }
      if (Date.now() - start > 10_000) {
        throw new Error(`Timed out waiting for agent-board lock: ${dir}`);
      }
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 50);
    }
  }
  try {
    return fn();
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function eventsPath(): string {
  return path.join(boardDir(), "events.jsonl");
}

function alertsPath(): string {
  return path.join(boardDir(), "alerts.md");
}

function promptsDir(): string {
  return path.join(boardDir(), "prompts");
}

const OPERATOR_NOTES_START = "<!-- agent-board:operator-notes:start -->";
const OPERATOR_NOTES_END = "<!-- agent-board:operator-notes:end -->";

function readOperatorNotes(): string {
  try {
    const text = fs.readFileSync(boardViewPath(), "utf8");
    const start = text.indexOf(OPERATOR_NOTES_START);
    const end = text.indexOf(OPERATOR_NOTES_END);
    if (start !== -1 && end !== -1 && end > start) {
      return text.slice(start + OPERATOR_NOTES_START.length, end).trim();
    }
  } catch {
    // Board view may not exist yet.
  }
  return "- Add freeform operator notes here. This section is preserved when the board regenerates.";
}

function recentEvents(limit = 20): string[] {
  try {
    const lines = fs.readFileSync(eventsPath(), "utf8").trim().split("\n").filter(Boolean);
    return lines.slice(-limit).reverse().map((line) => {
      try {
        const event = JSON.parse(line);
        const bits = [event.event || "event"];
        if (event.status) bits.push(`status=${event.status}`);
        if (event.role) bits.push(`role=${event.role}`);
        if (event.interface) bits.push(`ui=${event.interface}`);
        if (event.summary) bits.push(`summary=${event.summary}`);
        return `- ${event.time || "unknown"} — \`${event.id || "unknown"}\` ${bits.join(" ")}`;
      } catch {
        return `- ${line}`;
      }
    });
  } catch {
    return [];
  }
}

function alertLines(): string[] {
  try {
    return fs.readFileSync(alertsPath(), "utf8").split("\n").filter((line) => line.trim().startsWith("- "));
  } catch {
    return [];
  }
}

function sessionLine(s: BoardSession): string {
  const tags = [s.role, s.initiative && `initiative=${s.initiative}`, s.interface && s.interface !== "pi" && `ui=${s.interface}`, s.tmuxSession && s.tmuxWindowIndex && `tmux=${s.tmuxSession}:${s.tmuxWindowIndex}`]
    .filter(Boolean)
    .join("; ");
  const details = [
    `cwd: \`${s.cwd}\``,
    `prompt: \`${s.promptPath}\``,
    s.handoffPath && `handoff: \`${s.handoffPath}\``,
    s.lastSummary && `summary: ${s.lastSummary}`,
  ].filter(Boolean).join("; ");
  return `- [${s.status}] **${s.title}** — \`${s.id}\`${tags ? ` (${tags})` : ""}\n  - ${details}`;
}

function renderBoardView(state: BoardState): string {
  const operatorNotes = readOperatorNotes();
  const activeStatuses = new Set(["launched", "active", "running", "ready_for_review", "blocked"]);
  const active = state.sessions.filter((s) => activeStatuses.has(s.status));
  const inactive = state.sessions.filter((s) => !activeStatuses.has(s.status)).slice(0, 20);
  const alerts = alertLines();
  const events = recentEvents(20);

  return `# Agent Board

Generated: ${nowIso()}

This is the shared, file-native board for Loren and pi/pim agents. Edit the operator notes section freely; generated sections are rebuilt from board state.

## Operator notes

${OPERATOR_NOTES_START}
${operatorNotes}
${OPERATOR_NOTES_END}

## Active / attention sessions

${active.length ? active.map(sessionLine).join("\n") : "No active sessions."}

## Recent closed / done / dead sessions

${inactive.length ? inactive.map(sessionLine).join("\n") : "No inactive sessions recorded."}

## Alerts

${alerts.length ? alerts.join("\n") : "No alerts."}

## Recent events

${events.length ? events.join("\n") : "No events recorded."}

## Board files

- Sessions JSON: \`${sessionsPath()}\`
- Events JSONL: \`${eventsPath()}\`
- Alerts: \`${alertsPath()}\`
- Prompts: \`${promptsDir()}\`
`;
}

function writeBoardView(state: BoardState) {
  fs.writeFileSync(boardViewPath(), renderBoardView(state), "utf8");
}

function ensureBoardDirsNoState() {
  for (const dir of [
    boardRoot(),
    path.join(boardRoot(), "tasks"),
    path.join(boardRoot(), "daily"),
    path.join(boardRoot(), "standups"),
    path.join(boardRoot(), "initiatives"),
    boardDir(),
    promptsDir(),
  ]) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function ensureBoardDirs() {
  ensureBoardDirsNoState();
  try {
    fs.writeFileSync(alertsPath(), "# Agent Board Alerts\n\n", { encoding: "utf8", flag: "wx" });
  } catch (err: any) {
    if (err?.code !== "EEXIST") throw err;
  }
  try {
    fs.writeFileSync(sessionsPath(), JSON.stringify({ version: 1, sessions: [] }, null, 2) + "\n", { encoding: "utf8", flag: "wx" });
  } catch (err: any) {
    if (err?.code !== "EEXIST") throw err;
  }
  if (!fs.existsSync(boardViewPath())) {
    let state: BoardState = { version: 1, sessions: [] };
    try {
      const parsed = JSON.parse(fs.readFileSync(sessionsPath(), "utf8"));
      state = { version: 1, sessions: Array.isArray(parsed.sessions) ? parsed.sessions : [] };
    } catch {
      // Keep empty initial board state.
    }
    writeBoardView(state);
  }
}

function nowIso(): string {
  return new Date().toISOString();
}

function readState(): BoardState {
  ensureBoardDirs();
  try {
    const parsed = JSON.parse(fs.readFileSync(sessionsPath(), "utf8"));
    return { version: 1, sessions: Array.isArray(parsed.sessions) ? parsed.sessions : [] };
  } catch {
    return { version: 1, sessions: [] };
  }
}

function writeState(state: BoardState) {
  fs.mkdirSync(boardDir(), { recursive: true });
  const tmp = `${sessionsPath()}.tmp-${process.pid}`;
  fs.writeFileSync(tmp, JSON.stringify(state, null, 2) + "\n", "utf8");
  fs.renameSync(tmp, sessionsPath());
  writeBoardView(state);
}

function updateSession(id: string, patch: Partial<BoardSession>): BoardSession | undefined {
  return withBoardLock(() => {
    const state = readState();
    const idx = state.sessions.findIndex((s) => s.id === id);
    if (idx === -1) return undefined;
    state.sessions[idx] = { ...state.sessions[idx], ...patch, updatedAt: nowIso() };
    writeState(state);
    return state.sessions[idx];
  });
}

function appendEvent(event: Record<string, unknown>) {
  withBoardLock(() => {
    ensureBoardDirs();
    fs.appendFileSync(eventsPath(), JSON.stringify({ time: nowIso(), ...event }) + "\n", "utf8");
    writeBoardView(readState());
  });
}

function appendAlert(text: string) {
  withBoardLock(() => {
    ensureBoardDirs();
    fs.appendFileSync(alertsPath(), `- ${nowIso()} — ${text}\n`, "utf8");
    writeBoardView(readState());
  });
}

function makeId(role: string, title: string): string {
  const slug = `${role}-${title}`
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 36) || "agent";
  return `${slug}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 6)}`;
}

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, `'"'"'`)}'`;
}

function shortTitle(title: string, max = 22): string {
  const clean = title.replace(/\s+/g, " ").trim();
  return clean.length <= max ? clean : `${clean.slice(0, max - 1)}…`;
}

function sanitizeWindowName(value: string): string {
  return value.replace(/[\r\n:]/g, " ").replace(/\s+/g, " ").trim().slice(0, 48) || "agent";
}

function luaString(value: string): string {
  return JSON.stringify(value).replace(/\u2028/g, "\\u2028").replace(/\u2029/g, "\\u2029");
}

function luaStringArray(values: string[]): string {
  return `{ ${values.map(luaString).join(", ")} }`;
}

function currentTmuxSession(): string | undefined {
  if (process.env.AGENT_BOARD_TMUX_SESSION) return process.env.AGENT_BOARD_TMUX_SESSION;
  if (!process.env.TMUX) return undefined;
  try {
    return execFileSync("tmux", ["display-message", "-p", "#S"], { encoding: "utf8" }).trim() || undefined;
  } catch {
    return undefined;
  }
}

function currentTmuxWindowIndex(): string | undefined {
  if (!process.env.TMUX) return undefined;
  try {
    return execFileSync("tmux", ["display-message", "-p", "#I"], { encoding: "utf8" }).trim() || undefined;
  } catch {
    return undefined;
  }
}

function resolvePathMaybe(p: string | undefined, cwd: string): string | undefined {
  if (!p) return undefined;
  const expanded = expandHome(p);
  return path.isAbsolute(expanded) ? path.resolve(expanded) : path.resolve(cwd, expanded);
}

function writeDelegatedPrompt(input: {
  id: string;
  role: string;
  title: string;
  initiative?: string;
  cwd: string;
  prompt: string;
  handoffPath?: string;
}) {
  ensureBoardDirs();
  const promptPath = path.join(promptsDir(), `${input.id}.md`);
  const content = `# Interactive Agent Kickoff\n\nYou are a ${input.role} agent in an interactive pi session. Loren may steer you directly in this tmux window. Treat this as a focused working session, not a headless report job.\n\n## Assignment\n\n${input.prompt}\n\n## Working context\n\n- Title: ${input.title}\n- Initiative: ${input.initiative || "(none)"}\n- Working directory: \`${input.cwd}\`\n- Global work context root: \`${boardRoot()}\`\n${input.handoffPath ? `- Relevant handoff/context file: \`${input.handoffPath}\`\n` : ""}\n## How to start\n\n1. Briefly restate your understanding of the assignment.\n2. Inspect only the context you need.\n3. If the next step is ambiguous or risky, ask Loren before proceeding.\n4. Otherwise begin the work in small, reviewable steps.\n\n## Context discipline\n\n- Use \`${boardRoot()}\` for task, daily, initiative, and handoff context only when it is relevant.\n- Keep durable notes/handoffs updated for non-trivial long-running work.\n- Stay scoped to this assignment unless Loren redirects you.\n- If you become blocked, say what decision or input you need.\n`;
  fs.writeFileSync(promptPath, content, "utf8");
  return promptPath;
}

function formatSession(s: BoardSession): string {
  const loc = s.tmuxSession && s.tmuxWindowIndex ? ` tmux=${s.tmuxSession}:${s.tmuxWindowIndex}` : "";
  const init = s.initiative ? ` initiative=${s.initiative}` : "";
  const ui = s.interface && s.interface !== "pi" ? ` ui=${s.interface}` : "";
  return `- ${s.id} [${s.status}] ${s.role}: ${s.title}${init}${ui}${loc}\n  cwd: ${s.cwd}${s.lastSummary ? `\n  summary: ${s.lastSummary}` : ""}`;
}

function listSessions(filter: { status?: string; initiative?: string } = {}): BoardSession[] {
  return readState().sessions.filter((s) => {
    if (filter.status && s.status !== filter.status) return false;
    if (filter.initiative && s.initiative !== filter.initiative) return false;
    return true;
  });
}

function startInteractive(params: any, ctxCwd: string): BoardSession {
  ensureBoardDirs();
  const cwd = path.resolve(expandHome(params.cwd || ctxCwd));
  if (!fs.existsSync(cwd) || !fs.statSync(cwd).isDirectory()) {
    throw new Error(`cwd does not exist or is not a directory: ${cwd}`);
  }

  const id = makeId(params.role, params.title);
  const piSessionName = `${params.role}: ${params.title}`;
  const handoffPath = resolvePathMaybe(params.handoffPath, cwd);
  const promptPath = writeDelegatedPrompt({
    id,
    role: params.role,
    title: params.title,
    initiative: params.initiative,
    cwd,
    prompt: params.prompt,
    handoffPath,
  });

  const tmuxSession = params.tmuxSession || currentTmuxSession();
  if (!tmuxSession) {
    throw new Error("No tmux session found. Run from inside tmux or pass tmuxSession / set AGENT_BOARD_TMUX_SESSION.");
  }

  const requestedInterface = params.interface || "pi";
  if (!["pi", "pim"].includes(requestedInterface)) {
    throw new Error(`Unsupported agent-board interface: ${requestedInterface}. Expected 'pi' or 'pim'.`);
  }
  const ui = requestedInterface as BoardInterface;

  const windowName = sanitizeWindowName(params.windowName || `${params.role}:${shortTitle(params.title)}`);
  const piArgs = ["pi", "--name", shellQuote(piSessionName)];
  if (params.model) piArgs.push("--model", shellQuote(params.model));
  piArgs.push(shellQuote(`@${promptPath}`));

  const rpcPiArgs = ["pi", "--mode", "rpc", "--name", piSessionName];
  if (params.model) rpcPiArgs.push("--model", params.model);

  const pimPluginPath = ui === "pim" ? path.resolve(expandHome(params.pimPluginPath || process.env.PIM_PLUGIN_PATH || "~/repo/pim")) : undefined;
  if (ui === "pim" && (!pimPluginPath || !fs.existsSync(path.join(pimPluginPath, "plugin", "pim.lua")))) {
    throw new Error(`pim plugin not found at ${pimPluginPath}. Pass pimPluginPath or set PIM_PLUGIN_PATH.`);
  }

  const kickoffMessage = `Read and follow the agent-board kickoff prompt at @${promptPath}`;
  const pimLua = ui === "pim" ? `require("pim").setup({ pi_cmd = ${luaStringArray(rpcPiArgs)} }); require("pim").open(); require("pim").send(${luaString(kickoffMessage)})` : undefined;
  const runner = ui === "pim"
    ? [
        "nvim",
        "--clean",
        `+${shellQuote(`set rtp^=${pimPluginPath}`)}`,
        `+${shellQuote("runtime plugin/pim.lua")}`,
        `+${shellQuote(`lua ${pimLua}`)}`,
      ].join(" ")
    : piArgs.join(" ");

  const command = [
    `cd ${shellQuote(cwd)}`,
    `AGENT_BOARD_ID=${shellQuote(id)} AGENT_BOARD_ROOT=${shellQuote(boardRoot())} AGENT_BOARD_ROLE=${shellQuote(params.role)} ${runner}`,
  ].join(" && ");

  const placement = params.placement || "after-current";
  const currentIndex = currentTmuxWindowIndex();
  const currentSession = currentTmuxSession();
  const placeAfterCurrent = placement !== "end" && currentIndex && currentSession === tmuxSession;
  const tmuxArgs = ["new-window"];
  if (!params.focus) tmuxArgs.push("-d");
  if (placeAfterCurrent) tmuxArgs.push("-a", "-t", `${tmuxSession}:${currentIndex}`);
  else tmuxArgs.push("-t", tmuxSession);
  tmuxArgs.push("-P", "-F", "#{session_name}:#{window_index}:#{window_name}", "-n", windowName, command);

  const tmuxOut = execFileSync("tmux", tmuxArgs, { encoding: "utf8" }).trim();
  const [actualTmuxSession, tmuxWindowIndex, actualWindowName] = tmuxOut.split(":");

  const now = nowIso();
  const session: BoardSession = {
    id,
    role: params.role,
    title: params.title,
    initiative: params.initiative,
    cwd,
    status: "launched",
    tmuxSession: actualTmuxSession || tmuxSession,
    tmuxWindowIndex,
    tmuxWindowName: actualWindowName || windowName,
    piSessionName,
    promptPath,
    handoffPath,
    model: params.model,
    interface: ui,
    pimPluginPath,
    createdAt: now,
    updatedAt: now,
    lastEvent: "launched",
  };
  withBoardLock(() => {
    const state = readState();
    state.sessions.unshift(session);
    writeState(state);
    fs.appendFileSync(eventsPath(), JSON.stringify({ time: nowIso(), id, event: "launched", role: params.role, title: params.title, cwd, interface: ui, tmux: tmuxOut }) + "\n", "utf8");
  });
  return session;
}

function boardId(): string | undefined {
  return process.env.AGENT_BOARD_ID || undefined;
}

function markLifecycle(event: string, patch: Partial<BoardSession> = {}) {
  const id = boardId();
  if (!id) return;
  appendEvent({ id, event, role: process.env.AGENT_BOARD_ROLE });
  updateSession(id, { ...patch, lastEvent: event });
}

export default function agentBoard(pi: ExtensionAPI) {
  ensureBoardDirs();

  pi.registerCommand("board", {
    description: "Show agent board paths and active sessions",
    handler: async (_args, _ctx) => {
      const sessions = listSessions().slice(0, 12);
      pi.sendMessage({
        customType: "agent-board",
        display: true,
        content: `Agent board root: ${boardRoot()}\nBoard view: ${boardViewPath()}\n\n${sessions.length ? sessions.map(formatSession).join("\n") : "No sessions recorded."}`,
      });
    },
  });

  pi.registerCommand("agents", {
    description: "List agent-board sessions",
    handler: async (args, _ctx) => {
      const status = args?.trim() || undefined;
      const sessions = listSessions({ status }).slice(0, 30);
      pi.sendMessage({
        customType: "agent-board",
        display: true,
        content: sessions.length ? sessions.map(formatSession).join("\n") : `No sessions${status ? ` with status ${status}` : ""}.`,
      });
    },
  });

  pi.registerCommand("alerts", {
    description: "Show agent-board alerts",
    handler: async (_args, _ctx) => {
      ensureBoardDirs();
      pi.sendMessage({ customType: "agent-board", display: true, content: fs.readFileSync(alertsPath(), "utf8") });
    },
  });

  const executeStartInteractive = async (params: any, ctx: any) => {
    try {
      const session = startInteractive(params, ctx.cwd);
      return {
        content: [{ type: "text", text: `Started interactive agent.\n\n${formatSession(session)}\n\nPrompt: ${session.promptPath}` }],
        details: session,
      };
    } catch (err: any) {
      return { content: [{ type: "text", text: `Failed to start interactive agent: ${err?.message || err}` }], isError: true };
    }
  };

  pi.registerTool({
    name: "spawn_interactive_agent",
    label: "Spawn Interactive Agent",
    description: "Spawn a human-steerable interactive pi agent in a new tmux window. Use this when Loren says to spawn/start/open an interactive agent, coding agent, research agent, planning agent, or review agent. Can launch either the normal pi terminal UI or the pim Neovim adapter.",
    promptSnippet: "Spawn a human-steerable interactive pi agent in a new tmux window.",
    promptGuidelines: [
      "Use spawn_interactive_agent when Loren asks to spawn, start, or open an interactive agent/session/window for a task.",
      "spawn_interactive_agent must include the target cwd; use the orchestrator cwd only for global notes/work-board tasks, and use the relevant repo/project cwd for coding/research agents.",
      "spawn_interactive_agent should include a scoped assignment plus where to find/update handoff or global context.",
      "Use interface='pim' when Loren asks for a pim/neovim-backed interactive agent or wants editor-native feedback; otherwise use the default pi interface.",
    ],
    parameters: StartInteractiveSchema,
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      return executeStartInteractive(params, ctx);
    },
  });

  pi.on("before_agent_start", async (event) => {
    return {
      systemPrompt: `${event.systemPrompt}

## Interactive Agent Spawning

When Loren asks to spawn, start, open, or create an interactive agent/session/window, use the \`spawn_interactive_agent\` tool. Do not ask him to mention an agent board; the board is the hidden control plane.

Choose the correct \`cwd\` deliberately:
- Use \`~/docs/work\` or Loren's global work/notes directory for planning, task tracking, standup, and portfolio-management agents.
- Use the target repo/project directory for coding, research, review, or verification agents.

Use \`interface='pim'\` when Loren asks for a pim/Neovim-backed interactive agent or wants editor-native feedback. Use the default terminal pi interface otherwise.

Every spawned interactive agent should receive a scoped assignment and should know where to find/update relevant handoff, task, daily, or initiative context under \`~/docs/work\`.
`,
    };
  });

  pi.registerTool({
    name: "agent_board_list",
    label: "List Agent Board Sessions",
    description: "List sessions registered in the global agent board.",
    promptSnippet: "List cross-project interactive/background agent sessions and their statuses.",
    parameters: ListSchema,
    async execute(_toolCallId, params) {
      const sessions = listSessions(params).slice(0, 50);
      return {
        content: [{ type: "text", text: sessions.length ? sessions.map(formatSession).join("\n") : "No matching sessions." }],
        details: { sessions },
      };
    },
  });

  pi.registerTool({
    name: "agent_board_open",
    label: "Open Agent Session",
    description: "Switch tmux focus to a registered interactive agent session.",
    parameters: SessionIdSchema,
    async execute(_toolCallId, params) {
      const session = readState().sessions.find((s) => s.id === params.id);
      if (!session) return { content: [{ type: "text", text: `Unknown session id: ${params.id}` }], isError: true };
      if (!session.tmuxSession || !session.tmuxWindowIndex) {
        return { content: [{ type: "text", text: `Session ${params.id} has no tmux window recorded.` }], isError: true };
      }
      try {
        execFileSync("tmux", ["select-window", "-t", `${session.tmuxSession}:${session.tmuxWindowIndex}`]);
        return { content: [{ type: "text", text: `Switched to ${session.tmuxSession}:${session.tmuxWindowIndex} (${session.title}).` }], details: session };
      } catch (err: any) {
        return { content: [{ type: "text", text: `Failed to switch tmux window: ${err?.message || err}` }], isError: true };
      }
    },
  });

  pi.registerTool({
    name: "agent_board_update_status",
    label: "Update Agent Status",
    description: "Update a registered agent-board session status and optional summary.",
    parameters: UpdateStatusSchema,
    async execute(_toolCallId, params) {
      const updated = updateSession(params.id, {
        status: params.status as BoardStatus,
        lastSummary: params.summary,
        lastEvent: "manual_status_update",
      });
      if (!updated) return { content: [{ type: "text", text: `Unknown session id: ${params.id}` }], isError: true };
      appendEvent({ id: params.id, event: "manual_status_update", status: params.status, summary: params.summary });
      return { content: [{ type: "text", text: `Updated ${params.id} → ${params.status}.` }], details: updated };
    },
  });

  pi.on("session_start", async () => {
    markLifecycle("session_start", { status: "active" });
  });

  pi.on("agent_start", async () => {
    markLifecycle("agent_start", { status: "running" });
  });

  pi.on("agent_end", async () => {
    const id = boardId();
    markLifecycle("agent_end", { status: "ready_for_review" });
    if (id) {
      const session = readState().sessions.find((s) => s.id === id);
      const label = session ? `${session.role}: ${session.title}` : id;
      appendAlert(`${label} is ready for review.`);
      try {
        if (session?.tmuxSession && session.tmuxWindowIndex) {
          execFileSync("tmux", ["rename-window", "-t", `${session.tmuxSession}:${session.tmuxWindowIndex}`, `✓ ${session.tmuxWindowName || session.role}`]);
          execFileSync("tmux", ["display-message", `${label} is ready for review.`]);
        }
      } catch {
        // Non-fatal: tmux may not be available from this process.
      }
    }
  });

  pi.on("session_shutdown", async () => {
    markLifecycle("session_shutdown", { status: "closed" });
  });
}
