$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$build = Join-Path $root "build"
$place = Join-Path $build "AnvilSchemaBenchmarks.rbxlx"

New-Item -ItemType Directory -Force -Path $build | Out-Null

$rojo = Get-Command rojo -ErrorAction Stop
$runner = Get-Command run-in-roblox -ErrorAction Stop

& $rojo.Source build (Join-Path $root "default.project.json") --output $place
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$output = & $runner.Source --place $place --script (Join-Path $root "tools/RunSchemaRobloxBenchmark.server.luau") 2>&1
$runnerExit = $LASTEXITCODE
$output | ForEach-Object { Write-Host $_ }

if (($output -join "`n") -notmatch "Schema Roblox benchmark: \d+ iterations;") {
    exit $(if ($runnerExit -ne 0) { $runnerExit } else { 1 })
}

exit 0
