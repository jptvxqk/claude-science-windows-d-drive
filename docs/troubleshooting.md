# Troubleshooting

These notes are based on the Windows 11 / Claude Science 0.1.49 test that led to this repository.

## Claude Science refuses a junction or symlink

Observed behavior: redirecting the default .claude-science directory with a junction caused Claude Science to refuse the path because secret-bearing state would be redirected through a reparse point.

Recommendation: do not redirect the whole state directory with mklink, a junction, or a symlink. Use the process-local USERPROFILE method instead.

## --data-dir moves state but Conda still appears on C:

Observed behavior: primary state could be directed to D: with --data-dir while a large home-derived Conda directory was still created under the normal Windows user profile.

Recommendation: launch Claude Science with USERPROFILE set only for the Claude Science child process.

## Do not set USERPROFILE globally

Changing USERPROFILE globally can affect unrelated Windows applications, shell folders, credentials, and application configuration.

The launcher in this repository only changes USERPROFILE in the environment inherited by Claude Science.

## SHGetKnownFolderPath failed / win32 error 3

This occurred when the alternate profile existed but its AppData folders did not.

Create both:

    D:\ClaudeScience\UserProfile\AppData\Local
    D:\ClaudeScience\UserProfile\AppData\Roaming

The install script does this automatically.

## Browser does not open

The daemon may still be healthy.

Run:

    $oldProfile = $env:USERPROFILE
    $env:USERPROFILE = "D:\ClaudeScience\UserProfile"
    & "$env:LOCALAPPDATA\Programs\ClaudeScience\claude-science.com" status
    & "$env:LOCALAPPDATA\Programs\ClaudeScience\claude-science.com" url
    $env:USERPROFILE = $oldProfile

If status reports running=true and url prints a localhost link, the local service is running.

The launcher obtains a fresh URL and opens it separately because browser launching from the alternate profile did not work reliably in testing.

## Login link expired

Claude Science login URLs are one-time/short-lived links. Generate a fresh one:

    $oldProfile = $env:USERPROFILE
    $env:USERPROFILE = "D:\ClaudeScience\UserProfile"
    & "$env:LOCALAPPDATA\Programs\ClaudeScience\claude-science.com" url
    $env:USERPROFILE = $oldProfile

Do not bookmark a nonce URL.

## Authorization failed: Pro or Max subscription required

This is an account/subscription issue, not a D-drive relocation failure. The local daemon can be healthy even when account authorization is rejected.

## Two taskbar icons

The custom launcher starts Claude Science and then opens the localhost UI as a Chrome app window. Windows can treat the launcher and Chrome app window as different taskbar applications.

Recommendation: launch from Windows Search / Start instead of pinning the custom launcher to the taskbar.

## Conda folder looks almost twice as large as expected

Simple recursive file-size sums count hard-linked files more than once.

Check one environment executable:

    $py = Get-ChildItem "D:\ClaudeScience\UserProfile\.claude-science\conda\envs" -Recurse -Filter python.exe -File | Select-Object -First 1 -ExpandProperty FullName
    fsutil hardlink list "$py"

If the same file is listed under both pkgs and envs, it is sharing disk blocks.

## ketcher-chemistry MODULE_NOT_FOUND

One test showed a bundled ketcher-chemistry MCP warm-up failure because a server.js module was missing from the runtime tree. The daemon still reported running=true and sandbox_active=true.

Treat this as a separate Claude Science runtime/MCP issue. Do not use it as evidence that D-drive relocation failed.

## Re-check that Conda did not return to C:

    Test-Path "$HOME\.claude-science\conda"
    Test-Path "D:\ClaudeScience\UserProfile\.claude-science\conda"

Expected:

    False
    True


## Environment build fails with 0xC0000022 / STATUS_ACCESS_DENIED

Observed symptom: Claude Science reported that one or more environments failed to build, and the Windows sandbox log included 0xC0000022 (STATUS_ACCESS_DENIED).

In the tested setup, the failure was caused by sandbox access to runtime/environment files rather than by the D-drive relocation itself. After repairing the relevant ACL inheritance, sandbox launches for the MCP environment succeeded again.

Important: after repairing permissions, the old Claude Science daemon may still keep the previous failed-build state. In one observed case, it had already failed repeatedly and stopped retrying, so the UI continued to show the old failure even though the filesystem permissions were fixed.

Recommended recovery sequence:

1. Close the Claude Science UI.
2. Stop the daemon explicitly under the relocated profile.
3. Re-check or repair ACL inheritance on the current runtime directory if the log still shows 0xC0000022.
4. Start Claude Science again through the D-drive launcher.
5. Re-open Settings / Environments or Connectors and allow the environment build to retry.

To stop the relocated daemon:

    $env:USERPROFILE = 'D:\ClaudeScience\UserProfile'
    & "$env:LOCALAPPDATA\Programs\ClaudeScience\claude-science.com" stop

Closing only the window or browser tab is not a full restart.

## Old error remains visible after permissions were fixed

If the UI still reports the same environment failure after an ACL repair, first check whether the daemon process is actually new.

A stale background daemon can preserve a previous retry budget / failed-build state. In the recovered test, permissions were already correct and Python/R/Node could launch in the sandbox, but the old daemon had stopped retrying after repeated failures. Only a true stop followed by a fresh launch caused the connector environments to rebuild.

Use:

    $env:USERPROFILE = 'D:\ClaudeScience\UserProfile'
    & "$env:LOCALAPPDATA\Programs\ClaudeScience\claude-science.com" stop

Then start Claude Science again from the custom launcher.

## Runtime update breaks sandbox access

If Claude Science is updated and the problem returns, inspect the new:

    D:\ClaudeScience\UserProfile\.claude-science\runtime\<version>

directory.

The tested recovery involved restoring permission inheritance on the new runtime tree. Because ACL changes are security-sensitive, back up the existing ACLs first. See scripts/repair-runtime-acl.ps1 and docs/connector-environment-recovery.md.

## How to tell that connector recovery actually worked

Do not rely only on the disappearance of a toast notification.

Useful checks in the recovered test were:

- the daemon was a fresh process;
- sandbox execution of the MCP Python environment worked;
- Python with numpy/pandas imported successfully;
- R launched successfully;
- Node launched successfully;
- bundled connector status recovered to 20/20 READY.

If only one of these passes, keep investigating instead of assuming the environment is fully repaired.
