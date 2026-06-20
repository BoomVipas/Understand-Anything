# How to run Understand-Anything

Two things you can "run": the **dashboard** (a web app) and the **codebase analysis** (a Claude Code plugin).

## A) Run the dashboard — one command (works on a fresh clone, no admin)

**Windows (PowerShell):**
```powershell
.\run.ps1
```
**macOS / Linux:**
```bash
./run.sh
```

Then open **`http://127.0.0.1:5173/`** in your browser. Press Ctrl+C to stop.

This runs in **demo mode**: it serves a fully populated example knowledge graph (97 nodes), so you see
the dashboard working immediately — **no token needed**. The script auto-provisions `pnpm` (the repo's
build scripts call `pnpm` directly, so it must be on PATH — installed via corepack or, failing that,
`npm i -g pnpm`, neither needs admin), installs deps + builds on first run, then serves.

> Prerequisite: **Node.js 18+** (this box has v22). Get it from https://nodejs.org if missing.

First run installs/builds (a few minutes); later runs start in ~1 second.

### Why not `pnpm dev`?
`pnpm dev` starts a **live** server that serves a *real* analyzed project's graph (token-gated) and is
**empty until you run `/understand`** — opening it with no/stale token shows
*"Invalid knowledge graph: Missing or invalid project metadata"* (the app receives the token/`no graph`
error JSON instead of a graph). For just viewing the dashboard, use `run.ps1` (demo). For a real
project's graph, run `.\run.ps1 -Live` (Windows) / `./run.sh --live` after producing a graph via the
plugin (section B).

## B) Analyze YOUR codebase (Claude Code plugin)

The graph in (A) is demo data. To graph your *own* project, use it as a Claude Code plugin — run
these **in Claude Code**, inside the project you want to analyze:

```
/plugin marketplace add Egonex-AI/Understand-Anything
/plugin install understand-anything
/understand                 # multi-agent analysis -> .understand-anything/knowledge-graph.json
/understand-dashboard       # opens the dashboard on YOUR code
```

Heads-up: the first `/understand` analyzes the whole codebase and can use a lot of tokens
(incremental afterward — only changed files are re-analyzed).

Other platforms (Codex, Gemini CLI, Copilot, Cursor, OpenCode, …) install via `install.ps1` /
`install.sh` — see `README.md`.

## Troubleshooting
- **`'pnpm' is not recognized`** during build: pnpm isn't on PATH. `run.ps1`/`run.sh` fix this
  automatically; manual fix: `npm install -g pnpm@10.6.2`.
- **`corepack enable` fails with EPERM**: Node is installed under `C:\Program Files` (admin-only).
  That's fine — the run script falls back to a user-level `npm i -g pnpm`, which needs no admin.
- **Port 5173 in use**: another dashboard is already running; Vite will pick the next free port and
  print the new URL.
