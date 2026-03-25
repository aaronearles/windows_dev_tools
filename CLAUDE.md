# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository automates Windows dev tool installation and updates via winget. It consists of two PowerShell scripts that work together to install and maintain a standard developer toolset.

## Architecture

- **Install-DevTools.ps1**: One-time setup script that installs all tools via winget
  - Installs: PowerShell, VS Code (system-wide), Git, Azure CLI, Terraform, OpenTofu, OpenSSL, nano, cURL, SOPS
  - VS Code specifically uses `--scope machine` for system install
  - OpenSSL bin directory is prepended to Machine PATH after installation (silent install skips PATH checkbox; prepending ensures it takes precedence over bundled versions like ServiceNow agent)
  - Exit code -1978335189 indicates already installed (treated as success)

- **Setup-UpdateTask.ps1**: Creates a Windows Scheduled Task (`AutoUpdate-DevTools`)
  - Runs every Monday at 9am
  - Resolves full winget path to avoid PATH issues in task environment
  - Uses `StartWhenAvailable` to run on next boot if machine was off
  - Fires test run immediately after registration to verify functionality

## Platform Requirements

- **Windows only** - uses winget and Windows Task Scheduler
- **Administrator privileges required** - both scripts use `#Requires -RunAsAdministrator`
- **WSL/Linux environment note**: This code is meant to be run in Windows PowerShell, not from WSL

## Testing Scripts

Both scripts must be tested in an elevated PowerShell session on Windows:

```powershell
# Run in Windows (not WSL)
.\Install-DevTools.ps1
.\Setup-UpdateTask.ps1
```

The setup script tests itself automatically and reports the result. To verify the scheduled task manually:
```powershell
Get-ScheduledTask -TaskName "AutoUpdate-DevTools"
Get-ScheduledTaskInfo -TaskName "AutoUpdate-DevTools"
```

## Adding New Tools

When adding a new tool, it must be added to BOTH scripts:

1. Find the winget package ID: `winget search <toolname>`
2. Add to `$tools` array in `Install-DevTools.ps1`:
   ```powershell
   @{ Name = "ToolName"; Id = "Publisher.PackageId" }
   ```
3. Add the same ID to `$packages` array in `Setup-UpdateTask.ps1`
4. Add to the tools table in README.MD
5. Test with `.\Install-DevTools.ps1` then re-run `.\Setup-UpdateTask.ps1` to update the task

## Special Handling

- **VS Code** requires `--scope machine` to ensure system-wide installation (handled in Install-DevTools.ps1 only, not needed for upgrades)
- **OpenSSL** bin directory (`C:\Program Files\OpenSSL-Win64\bin`) is prepended to Machine PATH after installation. This ensures the winget-installed version takes precedence over bundled versions (e.g., ServiceNow agent). The PATH fix only runs if the directory exists and isn't already in PATH.
- **Scheduled task** wraps winget in `powershell.exe -NonInteractive` to inherit the auto-elevated session and suppress UAC prompts. Uses the real winget binary resolved from `$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*\winget.exe` — the `WindowsApps\winget.exe` alias returned by `Get-Command` is a reparse point that only works in interactive sessions and fails in scheduled tasks.
- **Safe to re-run**: Both scripts handle existing installations/tasks gracefully
