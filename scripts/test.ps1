$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$build = Join-Path $root "build"
$place = Join-Path $build "AnvilTests.rbxlx"

New-Item -ItemType Directory -Force -Path $build | Out-Null

$rojo = Get-Command rojo -ErrorAction Stop
$runner = Get-Command run-in-roblox -ErrorAction Stop

& $rojo.Source build (Join-Path $root "test.project.json") --output $place
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$output = & $runner.Source --place $place --script (Join-Path $root "tools/RunTests.server.luau") 2>&1
$runnerExit = $LASTEXITCODE
$output | ForEach-Object { Write-Host $_ }

$testOutput = $output -join "`n"
$summary = [regex]::Match($testOutput, "(\d+) passed, (\d+) failed, (\d+) skipped")
if (-not $summary.Success -or $testOutput -match "Errors reported by tests:")
{
    exit $(if ($runnerExit -ne 0) { $runnerExit } else { 1 })
}

if ([int]$summary.Groups[2].Value -gt 0) {
    exit 1
}

exit 0
