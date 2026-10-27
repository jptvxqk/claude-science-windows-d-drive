param(
    [string]$Root = "D:\ClaudeScience"
)

$ErrorActionPreference = "Stop"

$profile = Join-Path $Root "UserProfile"
$cli = Join-Path $env:LOCALAPPDATA "Programs\ClaudeScience\claude-science.com"
$launcher = Join-Path $Root "ClaudeScience-D.exe"

if (-not (Test-Path $cli)) {
    throw "Claude Science CLI not found: $cli"
}

$oldProfile = $env:USERPROFILE
try {
    $env:USERPROFILE = $profile
    Write-Host "Stopping Claude Science daemon for relocated profile..."
    & $cli stop
}
finally {
    $env:USERPROFILE = $oldProfile
}

Start-Sleep -Seconds 2

if (Test-Path $launcher) {
    Write-Host "Starting D-drive launcher..."
    Start-Process $launcher
}
else {
    Write-Warning "Custom launcher not found: $launcher"
    Write-Host "Start Claude Science manually from the Start menu shortcut."
}
