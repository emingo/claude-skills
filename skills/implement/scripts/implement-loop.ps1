#Requires -Version 7.0
# Unattended multi-milestone driver for /implement: one fresh headless Claude session per milestone, so no session
# carries one milestone's context into the next. Sessions hand off only through git, the docs and a small state file.
#   pwsh -NoProfile -File implement-loop.ps1 [-Scope all|next|<id>..<id>] [-MaxIterations 20] [-Model opus]
# -Model is the coordinator's model; workers and reviewers get theirs per work package.
#   pwsh -NoProfile -File implement-loop.ps1 -Stop      # stop cleanly after the current milestone
# Run from the repo root. Files live in .implement/loop/ (self-ignored, so the tree stays clean):
#   loop.log (one line per event) · state.json (written by each session) · run-<n>.jsonl (each session's stream)
param(
    [string] $Scope = 'all',
    [int] $MaxIterations = 20,
    [int] $MaxLimitWaits = 12,
    [string] $Model = 'opus',
    [switch] $Stop
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$dir = '.implement/loop'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
if (-not (Test-Path "$dir/.gitignore")) { Set-Content -NoNewline -Path "$dir/.gitignore" -Value "*`n" }
$log = "$dir/loop.log"; $state = "$dir/state.json"; $lock = "$dir/loop.lock"; $stopFile = "$dir/stop"

# A state-file field, or $null when the session left it out (StrictMode would throw on a missing property).
function Get-Field($obj, [string] $name) { $p = $obj.PSObject.Properties[$name]; if ($p) { $p.Value } else { $null } }
# True when the session's final stream-json "result" event reports a usage/rate limit. Only that event is inspected:
# grepping the whole transcript would match token counts, shas and code.
function Test-LimitEnd([string] $path) {
    $last = Get-Content $path -ErrorAction SilentlyContinue | Where-Object { $_ -match '"type"\s*:\s*"result"' } | Select-Object -Last 1
    if (-not $last) { return $false }
    try { $r = $last | ConvertFrom-Json } catch { return $false }
    $text = "$(Get-Field $r 'subtype') $(Get-Field $r 'result') $(Get-Field $r 'error')"
    [bool]((Get-Field $r 'is_error') -and $text -match '(usage|rate|session) limit|limit reached|resets? at')
}

# Cost per model from the session's final "result" event, e.g. " · cost claude-sonnet-5-5 $1.41, claude-opus-5-5 $0.80".
function Get-ModelCost([string] $path) {
    $last = Get-Content $path -ErrorAction SilentlyContinue | Where-Object { $_ -match '"type"\s*:\s*"result"' } | Select-Object -Last 1
    if (-not $last) { return '' }
    try {
        $usage = Get-Field ($last | ConvertFrom-Json) 'modelUsage'
        if (-not $usage) { return '' }
        $inv = [cultureinfo]::InvariantCulture
        $parts = $usage.PSObject.Properties | ForEach-Object { "$($_.Name) `$$(([double](Get-Field $_.Value 'costUSD')).ToString('0.00', $inv))" }
        if ($parts) { ' · cost ' + ($parts -join ', ') } else { '' }
    } catch { '' }
}

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
# A scope that names one milestone is finished once that milestone lands — no second session just to say so.
$single = $Scope -match '^[A-Za-z]+\d+[a-z]?$'
try {
    Write-Log "START scope=$Scope max=$MaxIterations model=$Model"
    # break/continue inside a PowerShell switch act on the switch, so the loop is labeled
    :iter for ($i = 1; $i -le $MaxIterations; $i++) {
        if (Test-Path $stopFile) { Write-Log 'STOPPED on request'; break }
        Remove-Item $state -ErrorAction SilentlyContinue
        $run = "$dir/run-$i.jsonl"
        $claudeArgs = @('-p', "/implement $Scope --unattended", '--output-format', 'stream-json', '--verbose',
                  '--permission-prompts', 'none', '--strict-mcp-config', '--name', "implement loop $i")
        if ($Model) { $claudeArgs += @('--model', $Model) }
        Write-Log "RUN $i — claude -p '/implement $Scope --unattended' --model $Model → $run"
        $head = (git rev-parse HEAD 2>$null)
        $global:LASTEXITCODE = 0
        & claude @claudeArgs *> $run
        $exit = $LASTEXITCODE

        if (-not (Test-Path $state)) {
            # No state file: the session died before finishing. A usage limit waits; anything else counts as a failure.
            if (Test-LimitEnd $run) {
                if (++$limitWaits -gt $MaxLimitWaits) { Write-Log "STOP — usage limit persisted through $MaxLimitWaits waits"; $code = 1; break }
                Write-Log "LIMIT — no state file; waiting 30 min (wait $limitWaits/$MaxLimitWaits)"; Start-Sleep -Seconds 1800; $i--; continue
            }
            # A session that died after committing work was interrupted, not broken: the next one resumes from git.
            $now = (git rev-parse HEAD 2>$null)
            if ($now -and $head -and $now -ne $head) { $failures = 0; Write-Log "INTERRUPTED — session exited $exit without a state file after making progress ($($head.Substring(0, 7))..$($now.Substring(0, 7))); resuming (see $run)"; continue }
            if (++$failures -ge 2) { Write-Log "STOP — two sessions in a row ended without a state file (last exit $exit, see $run)"; $code = 1; break }
            Write-Log "FAIL — session exited $exit without a state file; retrying once (see $run)"; continue
        }

        $s = Get-Content $state -Raw | ConvertFrom-Json
        $failures = 0
        $result = Get-Field $s 'result'; $sha = Get-Field $s 'sha'; $needs = Get-Field $s 'needsUser'; $resetAt = Get-Field $s 'resetAt'
        $line = "$(Get-Field $s 'milestone') $result$(if ($sha) { " $sha" }) — $(Get-Field $s 'summary')"
        switch ($result) {
            { $_ -in 'landed', 'awaiting-check' } { Write-Log "DONE $line$(Get-ModelCost $run)"; if ($single) { Write-Log "ALL DONE — scope $Scope is one milestone"; break iter }; continue iter }
            'limit' {
                if (++$limitWaits -gt $MaxLimitWaits) { Write-Log "STOP — usage limit persisted through $MaxLimitWaits waits"; $code = 1; break iter }
                # Compare in UTC: ConvertFrom-Json turns an ISO "…Z" time into a UTC DateTime, and DateTime math ignores Kind.
                $until = if ($resetAt) { ([datetime]$resetAt).ToUniversalTime() } else { [datetime]::UtcNow.AddMinutes(30) }
                $secs = [math]::Max(60, [int]($until - [datetime]::UtcNow).TotalSeconds + 60)
                Write-Log "LIMIT $line — sleeping until $($until.ToLocalTime().ToString('HH:mm'))"; Start-Sleep -Seconds $secs; $i--; continue iter
            }
            'all-done' { Write-Log "ALL DONE $line"; break iter }
            default { Write-Log "NEEDS YOU ($result) $line$(if ($needs) { ' · ' + ($needs -join '; ') })"; $code = 3; break iter }
        }
    }
    if ($i -gt $MaxIterations) { Write-Log "STOP — reached $MaxIterations iterations"; $code = 1 }
}
finally {
    Remove-Item $lock -ErrorAction SilentlyContinue
    Write-Log "END exit=$code — /implement status shows where things stand"
}
exit $code
