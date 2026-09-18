# Claude Science on Windows with data on another drive

Unofficial Windows launcher and setup notes for running Claude Science while keeping its large Conda/runtime state on a secondary drive such as D:.

Tested with Claude Science 0.1.49 on Windows 11.

## Why this exists

On Windows, Claude Science stores substantial state under:

    %USERPROFILE%\.claude-science

The Conda environment can consume several GB. In testing, the built-in --data-dir flag moved primary state but did not prevent all home-derived Conda state from being created under the normal Windows user profile.

The workaround documented here launches Claude Science with a process-local USERPROFILE pointing to another drive. No global Windows profile change is required.

## Tested layout

    C:\Users\<USERNAME>\AppData\Local\Programs\ClaudeScience\
        claude-science.exe
        claude-science.com

    D:\ClaudeScience\
        UserProfile\
            AppData\Local\
            AppData\Roaming\
            .claude-science\
                conda\
                runtime\
                logs\
                ...
        ClaudeScience-D.exe

The Claude Science program itself remains on C: and is small compared with the Conda/runtime data.

## What was verified

- Claude Science daemon starts successfully.
- status reports the D-drive data directory.
- Windows sandbox can become active.
- Conda is created under the D-drive fake profile.
- C:\Users\<USERNAME>\.claude-science\conda remains absent.
- Conda package/environment hard links work when the environment is created directly on D:.
- A fresh one-time local login URL can be generated with claude-science url.
- The UI can be opened as a standalone Chrome app window.

## Important limitations

- This is unofficial and may stop working in future Claude Science releases.
- Full long-duration Python/R/MCP workloads were not yet validated in this test because Claude Science requires a Pro or Max subscription for authorization.
- Tray/taskbar behavior may differ from the default installation.
- Pinning the custom launcher to the taskbar can produce two icons because the launcher and browser app window are different Windows applications.
- A bundled MCP component named ketcher-chemistry showed a missing-module error in one test environment. That issue was separate from D-drive relocation and did not prevent the daemon from running.
- Do not globally change USERPROFILE for Windows.

## Why not use a junction or symlink?

Claude Science 0.1.49 explicitly refused a symlink/junction for the default .claude-science state because it may contain secrets. A junction from:

    C:\Users\<USERNAME>\.claude-science

to another drive therefore did not work.

## Why not only use --data-dir?

In testing:

    claude-science serve --data-dir "D:\ClaudeScience\.claude-science"

moved the primary state directory, but a large Conda installation could still appear under:

    C:\Users\<USERNAME>\.claude-science\conda

The process-local USERPROFILE approach prevented that.

## Quick setup

### 1. Install Claude Science normally

Install the official Windows build first.

The examples assume the default per-user location:

    C:\Users\<USERNAME>\AppData\Local\Programs\ClaudeScience

### 2. Create the alternate profile

Run in PowerShell:

    New-Item -ItemType Directory -Force "D:\ClaudeScience\UserProfile\AppData\Local","D:\ClaudeScience\UserProfile\AppData\Roaming" | Out-Null

Creating both AppData directories is important. Without them, Windows sandbox initialization may fail with SHGetKnownFolderPath errors.

### 3. Build the launcher

From this repository:

    Set-ExecutionPolicy -Scope Process Bypass
    .\scripts\install-launcher.ps1

The script builds:

    D:\ClaudeScience\ClaudeScience-D.exe

and creates Start Menu/Desktop shortcuts.

### 4. Verify relocation

Run:

    .\scripts\verify-installation.ps1

Expected core result:

    C-drive Conda present: False
    D-drive Conda present: True

## Manual verification

    Test-Path "$HOME\.claude-science\conda"
    Test-Path "D:\ClaudeScience\UserProfile\.claude-science\conda"

To inspect daemon state under the alternate profile:

    $oldProfile = $env:USERPROFILE
    $env:USERPROFILE = "D:\ClaudeScience\UserProfile"
    & "$env:LOCALAPPDATA\Programs\ClaudeScience\claude-science.com" status
    $env:USERPROFILE = $oldProfile

A healthy result should include running=true, port=8000, sandbox_active=true, and a data_dir under D:\ClaudeScience\UserProfile\.claude-science.

## Hard-link check

Conda can report a large logical size because files under pkgs and envs may be hard-linked.

    $py = Get-ChildItem "D:\ClaudeScience\UserProfile\.claude-science\conda\envs" -Recurse -Filter python.exe -File | Select-Object -First 1 -ExpandProperty FullName
    fsutil hardlink list "$py"

Seeing paths under both conda\pkgs and conda\envs indicates the same underlying file is shared.

## Repository contents

    launcher/
      ClaudeScienceLauncher.cs

    scripts/
      install-launcher.ps1
      verify-installation.ps1
      uninstall-launcher.ps1

    docs/
      troubleshooting.md

## Security note

The workaround changes USERPROFILE only for the Claude Science child process. It does not modify the global Windows user profile.

Do not commit Claude Science state directories, OAuth tokens, encryption keys, logs, or Conda environments to Git.

## License

MIT.

## Disclaimer

This project is not affiliated with or endorsed by Anthropic. Claude and Claude Science are trademarks of their respective owner.
