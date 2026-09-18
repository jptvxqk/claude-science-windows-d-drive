param(
    [string]$Root = "D:\ClaudeScience"
)

$profile = Join-Path $Root "UserProfile"
$dConda = Join-Path $profile ".claude-science\conda"
$cConda = Join-Path $HOME ".claude-science\conda"
$cli = Join-Path $env:LOCALAPPDATA "Programs\ClaudeScience\claude-science.com"

Write-Host "C-drive Conda present: $(Test-Path $cConda)"
Write-Host "D-drive Conda present: $(Test-Path $dConda)"
Write-Host "Alternate AppData Local present: $(Test-Path (Join-Path $profile 'AppData\Local'))"
Write-Host "Alternate AppData Roaming present: $(Test-Path (Join-Path $profile 'AppData\Roaming'))"

if (Test-Path $cli) {
    $oldProfile = $env:USERPROFILE
    try {
        $env:USERPROFILE = $profile
        Write-Host ""
        Write-Host "Claude Science status:"
        & $cli status
    }
    finally {
        $env:USERPROFILE = $oldProfile
    }
}

if (Test-Path $dConda) {
    $py = Get-ChildItem (Join-Path $dConda "envs") -Recurse -Filter python.exe -File -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName

    if ($py) {
        Write-Host ""
        Write-Host "Hard links for one environment python.exe:"
        & fsutil hardlink list $py
    }
}
