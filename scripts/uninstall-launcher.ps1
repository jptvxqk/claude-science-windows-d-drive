param(
    [string]$Root = "D:\ClaudeScience",
    [switch]$RemoveData
)

$launcher = Join-Path $Root "ClaudeScience-D.exe"
$desktop = [Environment]::GetFolderPath("Desktop")
$startMenu = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"

Remove-Item (Join-Path $desktop "Claude Science.lnk") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $startMenu "Claude Science.lnk") -Force -ErrorAction SilentlyContinue
Remove-Item $launcher -Force -ErrorAction SilentlyContinue

Write-Host "Custom launcher and shortcuts removed."

if ($RemoveData) {
    Write-Warning "Removing $Root also deletes the relocated Claude Science state, Conda environments, logs, and credentials stored there."
    Remove-Item $Root -Recurse -Force
    Write-Host "Relocated data removed."
}
else {
    Write-Host "Relocated data was left untouched at: $Root"
}
