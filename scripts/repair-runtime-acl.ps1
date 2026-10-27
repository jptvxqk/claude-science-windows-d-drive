param(
    [string]$Root = "D:\ClaudeScience",
    [string]$RuntimeDir
)

$ErrorActionPreference = "Stop"

if (-not $RuntimeDir) {
    $runtimeRoot = Join-Path $Root "UserProfile\.claude-science\runtime"

    if (-not (Test-Path $runtimeRoot)) {
        throw "Runtime root not found: $runtimeRoot"
    }

    $RuntimeDir = Get-ChildItem $runtimeRoot -Directory |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}

if (-not $RuntimeDir -or -not (Test-Path $RuntimeDir)) {
    throw "Runtime directory not found."
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = Join-Path $Root "acl-backup-runtime-$stamp.txt"

Write-Host "Runtime directory: $RuntimeDir"
Write-Host "Saving ACL backup: $backup"

Push-Location (Split-Path $RuntimeDir -Parent)
try {
    $leaf = Split-Path $RuntimeDir -Leaf
    & icacls $leaf /save $backup /t /c | Out-Host
}
finally {
    Pop-Location
}

Write-Host ""
Write-Warning "Enabling inherited ACLs recursively on the selected runtime tree."
& icacls $RuntimeDir /inheritance:e /t /c | Out-Host

Write-Host ""
Write-Host "ACL repair completed."
Write-Host "Keep this backup until the runtime and connectors are verified:"
Write-Host $backup
Write-Host ""
Write-Host "Next: fully stop and restart Claude Science so failed environment builds are retried."
