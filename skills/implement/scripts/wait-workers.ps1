#Requires -Version 7.0
# Foreground wait for swarm workers, so an unattended coordinator never ends its turn while one is running:
# a headless session that sits idle waiting for a background agent exits after about ten minutes and takes the agent with it.
#   pwsh -NoProfile -File wait-workers.ps1 [-Minutes 9] [-Handled agent-a1b2,agent-c3d4]
# Run from the repo root. -Handled names the agent worktrees (their folder names) already dealt with: merged, failed,
# blocked, or superseded by a retry. Returns as soon as another worker has finished, or when the time is up.
# One line per agent worktree not in -Handled:
#   FINISHED|RUNNING <worktree folder> | <WP> | <status> | <branch> | <sha> | idle <n>m | <worktree path>
# Finished means: no uncommitted tracked changes, and the committed report says `done` on the worker's final commit
# ("… (<M> <WPx.y>)"), or `blocked`/`partial` on a commit of its own. A report inherited from an earlier attempt
# (HEAD is a merge or a revert) never counts. `idle` is the time since the worktree's last commit.
param(
    [int] $Minutes = 9,
    [string[]] $Handled = @()
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$Handled = @($Handled | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })

function Get-Workers {
    $paths = @(git worktree list --porcelain | Where-Object { $_ -like 'worktree *' } | ForEach-Object { $_.Substring(9) } | Where-Object { $_ -match '[\\/]\.claude[\\/]worktrees[\\/]agent-' })
    foreach ($p in $paths) {
        $key = Split-Path $p -Leaf
        if ($key -in $Handled) { continue }
        $subject = git -C $p log -1 --format=%s 2>$null
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $p)) { [pscustomobject]@{ Key = $key; WP = '?'; Status = 'unreadable worktree'; Path = $p; Finished = $false; Idle = -1 }; continue }
        $idle = [int](((Get-Date) - [DateTimeOffset]::FromUnixTimeSeconds([long](git -C $p log -1 --format=%ct)).LocalDateTime).TotalMinutes)
        $clean = -not (git -C $p status --porcelain --untracked-files=no)
        $reports = @(git -C $p ls-tree --name-only HEAD .implement/reports/ 2>$null | Where-Object { $_ -like '*.md' })
        if (-not $reports) { [pscustomobject]@{ Key = $key; WP = '?'; Status = 'no report yet'; Path = $p; Finished = $false; Idle = $idle }; continue }
        $inherited = $subject -match '^(Merge|Revert) '
        foreach ($r in $reports) {
            $line = @(git -C $p show "HEAD:$r" 2>$null | Where-Object { $_ -match '^\*\*Status:\*\*' } | Select-Object -First 1)
            $status = if ($line) { ($line[0] -replace '^\*\*Status:\*\*\s*', '').Trim() } else { 'unknown' }
            $final = $subject -notmatch '^WIP ' -and $subject -match '\(\S+ WP[\w.]+\)$'
            $finished = $clean -and -not $inherited -and (($status -match '^done\b' -and $final) -or $status -match '^(blocked|partial)\b')
            [pscustomobject]@{ Key = $key; WP = [IO.Path]::GetFileNameWithoutExtension($r); Status = $status; Path = $p; Finished = $finished; Idle = $idle }
        }
    }
}

function Write-Workers($workers) {
    foreach ($w in $workers) {
        $state = if ($w.Finished) { 'FINISHED' } else { 'RUNNING' }
        "$state $($w.Key) | $($w.WP) | $($w.Status) | $(git -C $w.Path branch --show-current 2>$null) | $(git -C $w.Path rev-parse --short HEAD 2>$null) | idle $($w.Idle)m | $($w.Path)"
    }
}

$start = Get-Date
$deadline = $start.AddMinutes($Minutes)
do {
    $workers = @(Get-Workers)
    if ($workers | Where-Object Finished) { Write-Workers $workers; exit 0 }
    # A worker launched a moment ago has no worktree yet: give it a minute before saying there is nothing to wait for.
    if (-not $workers -and ((Get-Date) - $start).TotalSeconds -ge 60) { break }
    Start-Sleep -Seconds 15
} while ((Get-Date) -lt $deadline)
if (-not $workers) { 'NO WORKERS: no agent worktree outside -Handled. Nothing is running, or the launch failed.'; exit 0 }
Write-Workers $workers
"TIMEOUT after $Minutes min: run this again. Never end the turn while a worker is running."
