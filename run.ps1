#requires -Version 5
<#
  Understand-Anything — one-command runner for the interactive dashboard (Windows).
  Works from a fresh clone, NO admin required.

      .\run.ps1            # build (if needed) + serve the DEMO dashboard (populated graph, no token)
      .\run.ps1 -Live      # serve a LIVE project's graph instead (needs /understand output; token-gated)
      .\run.ps1 -Reset     # force a clean reinstall + rebuild first

  Demo mode (default) opens a fully populated graph immediately — open the printed URL in a browser.
  Press Ctrl+C to stop.
#>
param([switch]$Reset, [switch]$Live)

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot
$PNPM_VER = '10.6.2'
$Dash = Join-Path $PSScriptRoot 'understand-anything-plugin\packages\dashboard'

function Have($c) { [bool](Get-Command $c -ErrorAction SilentlyContinue) }

if (-not (Have node)) { throw "Node.js 18+ is required. Install from https://nodejs.org and re-run." }

# The repo's build scripts call `pnpm` directly, so pnpm must be ON PATH. Provision without admin:
# try corepack, then fall back to a user-global npm install.
if (-not (Have pnpm)) {
    Write-Host "-> pnpm not found; provisioning (no admin needed)..."
    try { corepack enable 2>$null; corepack prepare "pnpm@$PNPM_VER" --activate 2>$null } catch {}
    if (-not (Have pnpm)) { npm install -g "pnpm@$PNPM_VER" }
}
if (-not (Have pnpm)) { throw "Could not provision pnpm. Install it manually: npm install -g pnpm@$PNPM_VER" }
Write-Host "OK pnpm $(pnpm -v)"

if ($Reset) {
    Write-Host "-> Reset: removing node_modules + build output..."
    Remove-Item -Recurse -Force "$PSScriptRoot\node_modules", "$Dash\dist" -ErrorAction SilentlyContinue
}

if (-not (Test-Path "$PSScriptRoot\node_modules")) {
    Write-Host "-> Installing dependencies (first run, can take a few minutes)..."
    pnpm install
}
if (-not (Test-Path "$PSScriptRoot\understand-anything-plugin\packages\core\dist")) {
    Write-Host "-> Building core (first run)..."
    pnpm --filter "@understand-anything/core" build
}

if ($Live) {
    # LIVE mode: serve a real analyzed project's graph (.understand-anything/knowledge-graph.json).
    # Token-gated; open the URL it prints that contains ?token=. Empty until you run /understand.
    Write-Host "`n-> LIVE mode. Open the printed URL (the one with ?token=). Ctrl+C to stop.`n"
    pnpm -C $Dash dev
}
else {
    # DEMO mode (default): build the demo bundle (root base, no token, bundled 97-node graph) once,
    # then serve it. This is what shows a populated dashboard out of the box.
    if (-not (Test-Path "$Dash\dist\.uademo")) {
        Write-Host "-> Building demo dashboard (first run)..."
        pnpm -C $Dash exec vite build --config vite.config.demo.ts --base=/
        New-Item -ItemType File -Path "$Dash\dist\.uademo" -Force | Out-Null
    }
    Write-Host "`n==================================================================="
    Write-Host "  Dashboard (demo): open the 'Local:' URL printed below"
    Write-Host "  (usually http://127.0.0.1:5173/). Ctrl+C to stop."
    Write-Host "  Demo graph. To graph YOUR code, see HOW_TO_RUN.md (Claude Code plugin)."
    Write-Host "===================================================================`n"
    pnpm -C $Dash exec vite preview --base=/ --port 5173
}
