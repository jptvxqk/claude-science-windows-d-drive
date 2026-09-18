param(
    [string]$Root = "D:\ClaudeScience"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot "launcher\ClaudeScienceLauncher.cs"
$launcher = Join-Path $Root "ClaudeScience-D.exe"
$profile = Join-Path $Root "UserProfile"
$officialExe = Join-Path $env:LOCALAPPDATA "Programs\ClaudeScience\claude-science.exe"

if (-not (Test-Path $officialExe)) {
    throw "Claude Science was not found at: $officialExe. Install the official Windows build first."
}

New-Item -ItemType Directory -Force $Root | Out-Null
New-Item -ItemType Directory -Force (Join-Path $profile "AppData\Local") | Out-Null
New-Item -ItemType Directory -Force (Join-Path $profile "AppData\Roaming") | Out-Null

if (Test-Path $launcher) {
    Get-Process | Where-Object { $_.Path -eq $launcher } | Stop-Process -Force -ErrorAction SilentlyContinue
    Remove-Item $launcher -Force
}

$code = Get-Content $source -Raw
Add-Type -TypeDefinition $code -OutputAssembly $launcher -OutputType WindowsApplication

$desktop = [Environment]::GetFolderPath("Desktop")
$startMenu = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$ws = New-Object -ComObject WScript.Shell

foreach ($link in @(
    (Join-Path $desktop "Claude Science.lnk"),
    (Join-Path $startMenu "Claude Science.lnk")
)) {
    $sc = $ws.CreateShortcut($link)
    $sc.TargetPath = $launcher
    $sc.WorkingDirectory = $Root
    $sc.IconLocation = "$officialExe,0"
    $sc.Save()
}

Write-Host "Launcher installed: $launcher"
Write-Host "Alternate profile: $profile"
Write-Host "Search for 'Claude Science' from the Windows Start menu to launch it."
Write-Warning "Taskbar pinning may show two icons because the launcher and Chrome app window are separate Windows applications."
