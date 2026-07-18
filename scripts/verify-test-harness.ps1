$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$failureSpec = Join-Path $root "test/unit/HarnessFailure.spec.luau"
$testCommand = Join-Path $PSScriptRoot "test.ps1"

Set-Content -Path $failureSpec -Encoding Ascii -Value @'
return function()
    describe("Harness", function()
        it("reports failure through process exit status", function()
            error("intentional harness failure")
        end)
    end)
end
'@

try {
    & $testCommand
    $testExit = $LASTEXITCODE
} finally {
    Remove-Item -Force $failureSpec -ErrorAction SilentlyContinue
}

if ($testExit -eq 0) {
    throw "Test harness returned zero for a failing TestEZ spec."
}

Write-Host "Test harness returned nonzero for a failing TestEZ spec."
