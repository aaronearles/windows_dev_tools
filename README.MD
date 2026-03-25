# Dev Tools Setup Scripts

Automates installation and updates for a standard dev toolset on Windows via winget.

## Tools Managed

| Tool        | winget ID                    | Notes                                    |
|-------------|------------------------------|------------------------------------------|
| PowerShell  | Microsoft.PowerShell         |                                          |
| VS Code     | Microsoft.VisualStudioCode   |                                          |
| Git         | Git.Git                      |                                          |
| Azure CLI   | Microsoft.AzureCLI           |                                          |
| Terraform   | Hashicorp.Terraform          |                                          |
| OpenTofu    | OpenTofu.Tofu                |                                          |
| OpenSSL     | ShiningLight.OpenSSL.Light   | PATH automatically prepended             |
| nano        | GNU.nano                     |                                          |
| cURL        | cURL.cURL                    |                                          |
| SOPS        | SecretsOPerationS.SOPS       |                                          |

## Scripts

### `Install-DevTools.ps1`
One-time setup for a new machine. Installs all tools silently via winget.
- VS Code is installed as a system-wide install (`--scope machine`)
- OpenSSL's bin directory is prepended to the system PATH automatically (winget's silent install skips the PATH checkbox, and bundled versions from tools like ServiceNow agent can otherwise take precedence)
- Safe to re-run — already-installed tools are skipped without error

### `Setup-UpdateTask.ps1`
Registers a Windows Scheduled Task (`AutoUpdate-DevTools`) that silently upgrades
all tools every Monday at 9am.
- Safe to re-run — updates the existing task if already registered
- Automatically resolves the full winget path to avoid PATH issues in the task environment
- Uses `StartWhenAvailable` so if the machine is off on Monday it runs on next boot
- Fires a test run immediately after registering and reports the result

## Usage

Both scripts require an elevated (admin) PowerShell session.

```powershell
# Step 1 — install tools
.\Install-DevTools.ps1

# Step 2 — register the update task
.\Setup-UpdateTask.ps1
```

## Adding More Tools

1. Find the winget ID: `winget search <toolname>`
2. Add the ID to the `$tools` array in `Install-DevTools.ps1`
3. Add the same ID to the `$packages` array in `Setup-UpdateTask.ps1`
4. Re-run `Setup-UpdateTask.ps1` to update the scheduled task