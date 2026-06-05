# sisou-runner

## Version

**Current Version:** 2.2

## Changelog

| Version | Highlights |
|---------|------------|
| 2.2     | Advanced runner JSON config defaults; ISO scan include/exclude/depth controls; optional ISO-9660 header validation; faster large-collection status lookups; upstream SISOU compatibility fixes; isolated managed SISOU venv; GnuPG pre-flight and install prompt; clean dry-run behavior; improved Ctrl+C cancellation; progress bar rendering fixes; example configs and integration checks |
| 2.1     | Full PowerShell 5.1 compatibility; interactive launch menu; pause-at-exit / back-to-menu for "Run with PowerShell" (Windows 10 + 11); black console background normalisation; real-time sisou log tailing with traceback surfacing; improved dry-run output; user-friendly error messages; SISOU limitation docs; smart update pairing (removed+added → updated); pip PATH warning suppressed; Windows Store Python stubs skipped |
| 2.0     | Major overhaul: privacy-safe JSON report, robust Ventoy detection, SHA-256 hashing, retry logic, Ctrl+C handler |

## Project Todo List

- [x] Major overhaul and rename
- [x] Advanced logging and privacy reporting
- [x] Automatic Python runtime management
- [x] Robust Ventoy detection
- [x] SHA-256 hashing for ISOs
- [x] Improved documentation and GDPR compliance
- [x] Version tracking in script and logs
- [x] User-friendly error messages
- [x] Improve dry-run output
- [x] Command-line help for all parameters
- [x] Document SISOU limitations
- [x] Interactive launch menu with pause-at-exit and back-to-menu
- [x] Real-time log tailing with traceback surfacing
- [x] Black console background for consistent appearance
- [x] Expand advanced config options
- [x] Integration tests and example configs
- [x] Optimize for large ISO collections
- [ ] Refactor for modularity
- [x] Support additional ISO validation
- [ ] Cross-platform support
- [ ] Ensure compatibility with SISOU upstream

## Overview

sisou-runner is a robust PowerShell wrapper for SuperISOUpdater (SISOU), automating ISO updates on Ventoy USB drives. It manages Python runtime setup, Ventoy drive detection, ISO integrity checks, retry logic, and privacy-safe reporting.

## Prerequisites

- **Windows** with PowerShell 5.1 or later (PowerShell 7+ recommended for parallel hashing)
- **Python 3.12 or later** if using a system Python. SISOU's package metadata is looser, but upstream documentation and current source require Python 3.12+ syntax.
- **Microsoft Visual C++ 2015-2022 Redistributable x64** may be required for SISOU's `libtorrent` dependency on Windows.
- **GnuPG / gpg.exe** for SISOU signature verification. The runner can detect GnuPG and offer winget installation.
- **Ventoy** installed on your USB drive ([Ventoy project](https://github.com/ventoy/Ventoy))
- **Internet access** for Python/SISOU installation (unless using offline options)
- **PowerShell Execution Policy**: The script requires the execution policy to be set to `RemoteSigned` or less restrictive. To set this, run:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

> **PowerShell 5.1 note:** The script is fully compatible with the Windows-built-in PowerShell 5.1. The only feature that requires PS 7+ is parallel SHA-256 hashing (`-VerifyHashes`); on PS 5.1 hashing runs sequentially.

## Features

- Automatic Python 3.12+ runtime detection and installation (system, managed, or via winget)
- Installs and upgrades SuperISOUpdater (SISOU) as needed
- Reliable Ventoy USB drive detection (multiple strategies)
- Optional SHA-256 hashing for ISOs
- Structured logging and privacy-safe JSON reporting
- Handles Ctrl+C gracefully, cleans up child processes
- Supports dry-run mode, retry logic, and custom SISOU arguments
- Advanced error handling and reporting

## Usage

Run the script in PowerShell:

```powershell
pwsh -File sisou-runner.ps1
```

### Common Options

- `-Drive <letter>`: Specify Ventoy drive letter (auto-detected if omitted)
- `-ConfigFile <path>`: Path to a SISOU `sisou.toml` file, passed as SISOU's positional `config_path`
- `-AdvancedConfigFile <path>`: Path to a sisou-runner JSON defaults file
- `-LogLevel <level>`: SISOU log verbosity (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- `-LogDir <path>`: Directory for logs (default: %ProgramData%\SISOU\logs)
- `-RetryCount <n>`: Number of retry attempts on failure (default: 2)
- `-TimeoutSeconds <n>`: Timeout per SISOU run (default: 3600)
- `-HashThrottle <n>`: Parallel SHA-256 threads (default: 4)
- `-IsoScanDepth <n>`: Maximum folder depth for ISO discovery (`-1` scans all folders)
- `-IncludeIsoPattern <patterns>`: Wildcard ISO filename include filter(s)
- `-ExcludeIsoPattern <patterns>`: Wildcard ISO filename exclude filter(s)
- `-VerifyHashes`: Compute SHA-256 for ISOs before/after
- `-ValidateIsoHeaders`: Check for readable ISO-9660 `CD001` descriptors before live runs
- `-SkipPipUpgrade`: Skip SISOU upgrade step
- `-InstallGpg`: Install GnuPG with winget if `gpg.exe` is missing
- `-SkipGpgCheck`: Skip GnuPG pre-flight; SISOU may skip signature checks
- `-DryRun`: Preview actions without running SISOU
- `-NonInteractive`: No prompts; fail fast if input is missing
- `-UseWinget`: Force winget/system Python
- `-Help`: Print usage and exit
- `-- <args>`: Extra arguments forwarded to SISOU

#### Example: Full Automated Run

```powershell
pwsh -File sisou-runner.ps1 -LogLevel INFO -RetryCount 3 -VerifyHashes -- --my-sisou-flag
```

#### Example: Dry Run

```powershell
pwsh -File sisou-runner.ps1 -DryRun
```

#### Example: Custom Config

```powershell
pwsh -File sisou-runner.ps1 -ConfigFile "C:\path\to\config.toml"
```

#### Example: Runner Defaults File

```powershell
pwsh -File sisou-runner.ps1 -AdvancedConfigFile .\Examples\runner-config.json
```

Command-line parameters override values from `-AdvancedConfigFile`, so you can keep team defaults in JSON and still run one-off overrides such as:

```powershell
pwsh -File sisou-runner.ps1 -AdvancedConfigFile .\Examples\runner-config.json -DryRun -LogLevel DEBUG
```

See `sisou-runner.ps1` for full parameter list and examples.

## Examples & Checks

- `Examples\runner-config.json`: sisou-runner defaults for retries, scan filters, hashing, and validation.
- `Examples\sisou-config.toml`: starter SISOU config passed through `-ConfigFile`.
- `Debug\test_syntax.ps1`: parser and quality checks.
- `Debug\test_integration.ps1`: offline integration checks for examples, runner parameters, and ISO header validation.

## Logging & Reports

- Logs are written to `%ProgramData%\SISOU\logs` (or custom directory)
- JSON reports are privacy-safe (no full paths or usernames)

## SISOU Known Limitations

sisou-runner wraps [SuperISOUpdater (SISOU)](https://github.com/JoshuaVandaele/SuperISOUpdater). Some limitations are inherent to SISOU itself:

- **Network errors** (UltimateBootCD, Fedora): transient; the runner will retry automatically.
- **GnuPG missing**: SISOU downloads can continue, but signature verification is skipped for signed downloads. Install `GnuPG.GnuPG` or `GnuPG.Gpg4win` with winget.
- **Kali / libtorrent on Windows**: SISOU imports the Kali torrent updater at startup. If native `libtorrent` DLL loading fails, the managed runner venv disables Kali so other ISOs can still be updated. Repair/install the Microsoft Visual C++ Redistributable x64 to restore Kali support.
- **Microsoft Windows ISOs**: the Windows 11 updater can be rejected by Microsoft Sentinel in some regions. This is a Microsoft-side restriction, not a bug in the runner.
- **ShredOS**: uses a non-numeric version scheme; SISOU cannot compare versions and will log an error.
- **Fedora**: version detection breaks when getfedora.org changes its page layout upstream.
- **Unknown ISOs**: SISOU only manages ISOs it has a module for. Custom or unrecognised ISOs are left untouched.
- **Proxy support**: SISOU has no built-in proxy setting. Set `HTTPS_PROXY` / `HTTP_PROXY` in your environment before running the script.
- **Partial downloads**: if a download is interrupted the partial file may remain on the drive with a `.part` extension; re-run the script to resume.

See `SISOU-upstream-notes.md` for researched notes about SISOU's current CLI, Python version reality, and native torrent dependency behavior.

## Troubleshooting

- **Execution Policy Error**: If you see a policy error, set the execution policy as described above.
- **Python Not Found**: The script will attempt to install Python automatically. If this fails, ensure you have internet access or install Python 3.12+ manually.
- **Ventoy Not Detected**: Make sure your USB drive is plugged in and Ventoy is properly installed.
- **Permission Issues**: Run PowerShell as Administrator if you encounter access errors.

## Credits

- [Joshua Vandaële](https://github.com/JoshuaVandaele) for [SuperISOUpdater](https://github.com/JoshuaVandaele/SuperISOUpdater)
- [Ventoy project](https://github.com/ventoy/Ventoy)

## License

See repository for license details.
