$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$consumer = Join-Path $root "examples/consumer"
$build = Join-Path $root "build"
$place = Join-Path $build "AnvilConsumerSmoke.rbxlx"

New-Item -ItemType Directory -Force -Path $build | Out-Null

$wally = Get-Command wally -ErrorAction Stop
$rojo = Get-Command rojo -ErrorAction Stop
$runner = Get-Command run-in-roblox -ErrorAction Stop

Push-Location $consumer
try {
    & $wally.Source install
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}

& $rojo.Source build (Join-Path $consumer "default.project.json") --output $place
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$output = & $runner.Source --place $place --script (Join-Path $consumer "src/Smoke.server.luau") 2>&1
$runnerExit = $LASTEXITCODE
$output | ForEach-Object { Write-Host $_ }

if (($output -join "`n") -notmatch "Anvil consumer smoke: passed") {
    exit $(if ($runnerExit -ne 0) { $runnerExit } else { 1 })
}

exit 0
