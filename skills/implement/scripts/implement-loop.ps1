#Requires -Version 7.0
# Unattended multi-milestone driver for /implement: one fresh headless Claude session per milestone, so no session
# carries one milestone's context into the next. Sessions hand off only through git, the docs and a small state file.
#   pwsh -NoProfile -File implement-loop.ps1 [-Scope all|next|<id>..<id>] [-MaxIterations 20] [-Model <model>]
#   pwsh -NoProfile -File implement-loop.ps1 -Stop      # stop cleanly after the current milestone
# Run from the repo root. Files live in .implement/loop/ (self-ignored, so the tree stays clean):
#   loop.log (one line per event) · state.json (written by each session) · run-<n>.jsonl (each session's stream)
param(
    [string] $Scope = 'all',
    [int] $MaxIterations = 20,
    [int] $MaxLimitWaits = 12,
    [string] $Model,
    [switch] $Stop
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$dir = '.implement/loop'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
if (-not (Test-Path "$dir/.gitignore")) { Set-Content -NoNewline -Path "$dir/.gitignore" -Value "*`n" }
$log = "$dir/loop.log"; $state = "$dir/state.json"; $lock = "$dir/loop.lock"; $stopFile = "$dir/stop"

function Write-Log([string] $msg) {
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg"
    Add-Content -Path $log -Value $line -Encoding utf8
    Write-Host $line
}

if ($Stop) { New-Item -ItemType File -Force -Path $stopFile | Out-Null; Write-Log 'STOP requested — the loop ends after the current milestone'; exit 0 }

if (Test-Path $lock) {
    $other = Get-Content $lock -ErrorAction SilentlyContinue
    if ($other -and (Get-Process -Id ([int]$other) -ErrorAction SilentlyContinue)) { Write-Host "implement-loop: already running (pid $other)"; exit 2 }
}
Set-Content -Path $lock -Value $PID
Remove-Item $stopFile -ErrorAction SilentlyContinue

$failures = 0; $limitWaits = 0; $code = 0
try {
    Write-Log "START scope=$Scope max=$MaxIterations"
    # break/continue inside a PowerShell switch act on the switch, so the loop is labeled
    :iter for ($i = 1; $i -le $MaxIterations; $i++) {
        if (Test-Path $stopFile) { Write-Log 'STOPPED on request'; break }
        Remove-Item $state -ErrorAction SilentlyContinue
        $run = "$dir/run-$i.jsonl"
        $claudeArgs = @('-p', "/implement $Scope --unattended", '--output-format', 'stream-json', '--verbose',
                  '--permission-prompts', 'none', '--strict-mcp-config', '--name', "implement loop $i")
        if ($Model) { $claudeArgs += @('--model', $Model) }
        Write-Log "RUN $i — claude -p '/implement $Scope --unattended' → $run"
        $global:LASTEXITCODE = 0
        & claude @claudeArgs *> $run
        $exit = $LASTEXITCODE

        if (-not (Test-Path $state)) {
            # No state file: the session died before finishing. A usage limit waits; anything else counts as a failure.
            if (Select-String -Path $run -Pattern 'usage limit|rate limit|limit reached|429' -Quiet) {
                if (++$limitWaits -gt $MaxLimitWaits) { Write-Log "STOP — usage limit persisted through $MaxLimitWaits waits"; $code = 1; break }
                Write-Log "LIMIT — no state file; waiting 30 min (wait $limitWaits/$MaxLimitWaits)"; Start-Sleep -Seconds 1800; $i--; continue
            }
            if (++$failures -ge 2) { Write-Log "STOP — two sessions in a row ended without a state file (last exit $exit, see $run)"; $code = 1; break }
            Write-Log "FAIL — session exited $exit without a state file; retrying once (see $run)"; continue
        }

        $s = Get-Content $state -Raw | ConvertFrom-Json
        $failures = 0
        $line = "$($s.milestone) $($s.result)$(if ($s.sha) { " $($s.sha)" }) — $($s.summary)"
        switch ($s.result) {
            { $_ -in 'landed', 'awaiting-check' } { Write-Log "DONE $line"; continue iter }
            'limit' {
                if (++$limitWaits -gt $MaxLimitWaits) { Write-Log "STOP — usage limit persisted through $MaxLimitWaits waits"; $code = 1; break iter }
                $until = if ($s.resetAt) { [datetime]$s.resetAt } else { (Get-Date).AddMinutes(30) }
                $secs = [math]::Max(60, [int]($until - (Get-Date)).TotalSeconds + 60)
                Write-Log "LIMIT $line — sleeping until $($until.ToString('HH:mm'))"; Start-Sleep -Seconds $secs; $i--; continue iter
            }
            'all-done' { Write-Log "ALL DONE $line"; break iter }
            default { Write-Log "NEEDS YOU ($($s.result)) $line$(if ($s.needsUser) { ' · ' + ($s.needsUser -join '; ') })"; $code = 3; break iter }
        }
        if ($i -eq $MaxIterations) { Write-Log "STOP — reached $MaxIterations iterations"; $code = 1 }
    }
}
finally {
    Remove-Item $lock -ErrorAction SilentlyContinue
    Write-Log "END exit=$code — /implement status shows where things stand"
}
exit $code
