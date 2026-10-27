# Connector environment recovery on Windows

This document records a real recovery path observed on the D-drive setup when Claude Science reported environment failures and bundled connectors would not start.

Tested context:

- Windows 11
- Claude Science using a process-local USERPROFILE on D:
- Claude Science state under D:\ClaudeScience\UserProfile\.claude-science
- Failure included Windows sandbox exit 0xC0000022 (STATUS_ACCESS_DENIED)

## What the failure looked like

The UI reported an environment build failure. The connector environment was named claude-science-mcp.

The important detail was not the toast itself, but the sandbox/runtime behavior underneath it. The old daemon had already failed multiple times and stopped retrying, so the UI continued to show a stale failed state even after filesystem permissions had been repaired.

## What fixed the tested setup

The successful recovery had two separate parts:

1. Repair filesystem permission inheritance for the affected Claude Science runtime tree.
2. Fully stop the old daemon and start a new one so environment setup and connector initialization were retried.

Repairing ACLs without replacing the stale daemon was not sufficient in the observed case.

## Safe ACL workflow

ACL changes are security-sensitive. Back up the current ACLs before changing inheritance.

Use the helper:

    .\scripts\repair-runtime-acl.ps1

By default it locates the newest runtime directory under:

    D:\ClaudeScience\UserProfile\.claude-science\runtime

and saves an ACL backup under D:\ClaudeScience before enabling inheritance on that runtime tree.

The script does not delete ACL entries or grant broad Everyone permissions. It only backs up the current ACLs and enables inherited permissions recursively.

If the runtime path is different, pass it explicitly:

    .\scripts\repair-runtime-acl.ps1 -RuntimeDir "D:\ClaudeScience\UserProfile\.claude-science\runtime\<version>"

## Fully restart the daemon

Closing the browser tab or app-style window is not a full restart.

Use:

    .\scripts\restart-claude-science.ps1

or manually:

    $old = $env:USERPROFILE
    $env:USERPROFILE = "D:\ClaudeScience\UserProfile"
    & "$env:LOCALAPPDATA\Programs\ClaudeScience\claude-science.com" stop
    $env:USERPROFILE = $old

Then start Claude Science from the D-drive launcher again.

## Validation after recovery

In the recovered test, the following checks all passed:

- MCP-environment Python started in the sandbox.
- Python could import numpy and pandas.
- R started in the sandbox.
- Node started in the sandbox.
- All 20 bundled connectors reported READY.

This is stronger evidence than simply seeing the environment notification disappear.

## If the issue returns after an update

Claude Science updates can create a new runtime\<version> directory.

If 0xC0000022 returns after an update:

1. Confirm the daemon is using the expected D-drive profile.
2. Check the newest runtime directory.
3. Back up its ACLs.
4. Restore/enable inheritance on the new runtime tree.
5. Stop the old daemon completely.
6. Start a fresh daemon and let the environment build retry.

Keep the ACL backup until the repaired runtime has been validated.

## What not to do

- Do not globally change USERPROFILE.
- Do not grant Everyone full control as a shortcut.
- Do not assume closing the UI stops the daemon.
- Do not repeatedly reinstall Conda before checking whether the sandbox is simply being denied access.
- Do not treat a stale UI error as proof that the repair failed; first verify whether a new daemon actually retried the environment build.

## Scope

This documents an observed workaround, not an official Anthropic procedure. Future Claude Science releases may change runtime layout, sandbox policy, connector count, or environment behavior.
