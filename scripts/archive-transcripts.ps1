#Requires -Version 7.0
# Mirrors Claude Code's session transcripts into an archive folder, so they outlive the retention sweep
# (cleanupPeriodDays): every projects/<project>/<session>.jsonl with its subagents/ and tool-results/ folders.
# Copies new and changed files only and never deletes, so a transcript the sweep removed stays in the archive.
#   pwsh -NoProfile -File archive-transcripts.ps1 [-Archive <folder>]     # run once
#   pwsh -NoProfile -File archive-transcripts.ps1 -Register [-At 13:00]   # daily scheduled task for this user
#   pwsh -NoProfile -File archive-transcripts.ps1 -Unregister
# Machine setup, not config: sync.sh never deploys it. Each run appends one line to <Archive>\archive.log.
param(
    [string] $Archive = (Join-Path $HOME 'claude-transcript-archive'),
    [switch] $Register,
    [string] $At = '13:00',
    [switch] $Unregister
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$task = 'Claude transcript archive'

if ($Unregister) { Unregister-ScheduledTask -TaskName $task -Confirm:$false; "removed the scheduled task '$task'"; exit 0 }
if ($Register) {
    $action = New-ScheduledTaskAction -Execute (Get-Command pwsh).Source -Argument "-NoProfile -WindowStyle Hidden -File `"$PSCommandPath`" -Archive `"$Archive`""
    $trigger = New-ScheduledTaskTrigger -Daily -At $At
    # StartWhenAvailable: a run missed because the machine was off happens at the next logon instead of being skipped.
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)
    Register-ScheduledTask -TaskName $task -Action $action -Trigger $trigger -Settings $settings -Description 'Copies Claude Code session transcripts to an archive that is never cleaned up.' -Force | Out-Null
    "registered '$task': daily at $At, archive $Archive"
    exit 0
}

$root = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
$source = Join-Path $root 'projects'
if (-not (Test-Path $source)) { throw "archive-transcripts: no transcripts at $source" }
$target = Join-Path $Archive 'projects'
New-Item -ItemType Directory -Force -Path $target | Out-Null

# /E subfolders · /XO skip files the archive already has in the same or a newer version · no /PURGE or /MIR, ever.
$out = robocopy $source $target /E /XO /R:1 /W:1 /NP /NFL /NDL /NJH
$rc = $LASTEXITCODE
$copied = ($out | Where-Object { $_ -match '^\s*Files\s*:' } | Select-Object -First 1) -replace '\s+', ' '
$line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') robocopy exit $rc ·$copied"
Add-Content -Path (Join-Path $Archive 'archive.log') -Value $line -Encoding utf8
$line
# robocopy: 0-7 are success (bit 0 = files copied), 8 and above mean something failed to copy.
if ($rc -ge 8) { exit 1 }
exit 0
