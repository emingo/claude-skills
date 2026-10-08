#Requires -Version 7.0
# Foreground wait for swarm workers, so an unattended coordinator never ends its turn while one is running:
# a headless session that sits idle waiting for a background agent exits after about ten minutes and takes the agent with it.
#   pwsh -NoProfile -File wait-workers.ps1 [-Minutes 9] [-Handled WP41.1,WP41.2]
# Run from the repo root. Returns as soon as a worker not in -Handled has finished — its committed report says
# done, blocked or partial and its worktree is clean — or when the time is up. One line per agent worktree:
#   FINISHED|RUNNING <WP> | <status> | <branch> | <sha> | <worktree path>
param(
    [int] $Minutes = 9,
    [string[]] $Handled = @()
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$Handled = @($Handled | ForEach-Object { $_ -split ',' } | Where-Object { $_ })

function Get-Workers {
    $paths = @(git worktree list --porcelain | Where-Object { $_ -like 'worktree *' } | ForEach-Object { $_.Substring(9) } | Where-Object { $_ -match '[\\/]\.claude[\\/]worktrees[\\/]agent-' })
    foreach ($p in $paths) {
        $reports = @(git -C $p ls-tree --name-only HEAD .implement/reports/ 2>$null | Where-Object { $_ -like '*.md' })
        if (-not $reports) { [pscustomobject]@{ WP = '?'; Status = 'no report yet'; Path = $p; Finished = $false }; continue }
        foreach ($r in $reports) {
            $wp = [IO.Path]::GetFileNameWithoutExtension($r)
            $line = @(git -C $p show "HEAD:$r" 2>$null | Where-Object { $_ -match '^\*\*Status:\*\*' } | Select-Object -First 1)
            $status = if ($line) { ($line[0] -replace '^\*\*Status:\*\*\s*', '').Trim() } else { 'unknown' }
            $clean = -not (git -C $p status --porcelain)
            [pscustomobject]@{ WP = $wp; Status = $status; Path = $p; Finished = ($clean -and $status -match '^(done|blocked|partial)\b') }
        }
    }
}

function Write-Workers($workers) {
    foreach ($w in $workers) {
        $state = if ($w.Finished) { 'FINISHED' } else { 'RUNNING' }
        "$state $($w.WP) | $($w.Status) | $(git -C $w.Path branch --show-current) | $(git -C $w.Path rev-parse --short HEAD) | $($w.Path)"
    }
}

$deadline = (Get-Date).AddMinutes($Minutes)
do {
    $workers = @(Get-Workers | Where-Object { $_.WP -notin $Handled })
    if (-not $workers) { 'NO WORKERS: no agent worktree is waiting to be handled'; exit 0 }
    if ($workers | Where-Object Finished) { Write-Workers $workers; exit 0 }
    Start-Sleep -Seconds 15
} while ((Get-Date) -lt $deadline)
Write-Workers $workers
"TIMEOUT after $Minutes min: run this again; never end the turn while a worker is running"
