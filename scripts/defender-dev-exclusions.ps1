#Requires -Version 7.0
#Requires -RunAsAdministrator
# Adds Microsoft Defender exclusions for development folders, so parallel agent builds stop paying real-time scans
# on every bin/obj write and NuGet cache read. Machine setup — not deployed by sync.sh. Run in an elevated pwsh:
#   pwsh -NoProfile -File scripts/defender-dev-exclusions.ps1 -WhatIf          # show what would change
#   pwsh -NoProfile -File scripts/defender-dev-exclusions.ps1                  # add the path exclusions
#   pwsh -NoProfile -File scripts/defender-dev-exclusions.ps1 -Processes       # also exclude dotnet/MSBuild/compiler processes
#   pwsh -NoProfile -File scripts/defender-dev-exclusions.ps1 -Remove          # undo (the same paths/processes)
# Trade-off: nothing in an excluded path (or opened by an excluded process) is scanned in real time, including packages
# you download into the NuGet cache. Keep the list to folders you build in. A Dev Drive (ReFS volume with Defender
# performance mode) is the safer alternative: it scans asynchronously instead of not at all.
[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]] $Paths = @(
        'C:\dev'
        (Join-Path $env:USERPROFILE '.nuget\packages')
        (Join-Path $env:LOCALAPPDATA 'NuGet')                   # http-cache, plugins-cache
        (Join-Path $env:USERPROFILE '.dotnet\tools')
    ),
    [switch] $Processes,
    [switch] $Remove
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Process exclusions are broad (every file those processes open), so they are opt-in.
$procs = 'dotnet.exe', 'MSBuild.exe', 'VBCSCompiler.exe', 'testhost.exe'

$pref = Get-MpPreference
$haveP = @($pref.ExclusionPath | Where-Object { $_ })
$haveX = @($pref.ExclusionProcess | Where-Object { $_ })
if ($haveP -contains 'N/A: Must be an administrator to view exclusions') { throw 'Run this from an elevated (administrator) pwsh.' }

$wantP = @($Paths | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') })
$wantX = if ($Processes) { $procs } else { @() }

foreach ($p in $wantP) {
    $present = $haveP -contains $p
    if ($Remove) {
        if (-not $present) { Write-Host "  skip    $p (not excluded)"; continue }
        if ($PSCmdlet.ShouldProcess($p, 'Remove Defender path exclusion')) { Remove-MpPreference -ExclusionPath $p; Write-Host "  removed $p" }
    } else {
        if ($present) { Write-Host "  ok      $p (already excluded)"; continue }
        if (-not (Test-Path -LiteralPath $p)) { Write-Host "  skip    $p (doesn't exist)"; continue }
        if ($PSCmdlet.ShouldProcess($p, 'Add Defender path exclusion')) { Add-MpPreference -ExclusionPath $p; Write-Host "  added   $p" }
    }
}
foreach ($x in $wantX) {
    $present = $haveX -contains $x
    if ($Remove) {
        if (-not $present) { Write-Host "  skip    $x (not excluded)"; continue }
        if ($PSCmdlet.ShouldProcess($x, 'Remove Defender process exclusion')) { Remove-MpPreference -ExclusionProcess $x; Write-Host "  removed $x" }
    } else {
        if ($present) { Write-Host "  ok      $x (already excluded)"; continue }
        if ($PSCmdlet.ShouldProcess($x, 'Add Defender process exclusion')) { Add-MpPreference -ExclusionProcess $x; Write-Host "  added   $x" }
    }
}

# Tamper protection or an organization policy can silently ignore local changes — confirm they took.
if (-not $WhatIfPreference) {
    $now = Get-MpPreference
    $missing = if ($Remove) { @($wantP + $wantX | Where-Object { $now.ExclusionPath -contains $_ -or $now.ExclusionProcess -contains $_ }) }
               else { @($wantP | Where-Object { (Test-Path -LiteralPath $_) -and $now.ExclusionPath -notcontains $_ }) + @($wantX | Where-Object { $now.ExclusionProcess -notcontains $_ }) }
    if ($missing.Count) { Write-Warning "Not applied (policy or tamper protection?): $($missing -join ', ')"; exit 1 }
    Write-Host 'Done. Defender exclusions are in effect immediately.'
}
