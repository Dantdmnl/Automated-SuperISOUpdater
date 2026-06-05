# sisou-runner v2.2

## Highlights

- Added advanced runner JSON defaults via `-AdvancedConfigFile`.
- Added ISO discovery controls: `-IsoScanDepth`, `-IncludeIsoPattern`, and `-ExcludeIsoPattern`.
- Added optional ISO-9660 header validation with `-ValidateIsoHeaders`.
- Added an isolated managed SISOU venv so SISOU dependencies do not collide with the user's system Python packages.
- Aligned invocation with upstream SISOU: `ConfigFile` is passed as SISOU's positional `config_path`, not a non-existent `-c` flag.
- Added GnuPG pre-flight detection and interactive/automatic winget install support with `-InstallGpg`.
- Added a managed-vendored workaround for SISOU's eager Kali/torrent import when native `libtorrent` cannot load.
- Fixed Windows drive-root invocation (`F:\`, not `F:`) and repaired UTF-8 BOMs in SISOU TOML files before `tomllib` reads them.
- Improved dry-run behavior so it previews without Python, pip, winget, or managed-runtime side effects.
- Improved Ctrl+C cancellation: kills the active SISOU child process, avoids retries, saves cancelled state/report, and exits with code 130.
- Fixed escaped tqdm progress blocks such as `\u2588` rendering literally in the console.
- Added example runner/SISOU configs and offline integration checks.

## Added Files

- `Examples/runner-config.json`
- `Examples/sisou-config.toml`
- `Debug/test_integration.ps1`
- `SISOU-upstream-notes.md`

## Verification

Validated on Windows PowerShell 5.1 with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Debug\test_syntax.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File Debug\test_integration.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\sisou-runner.ps1 -Help
```

## Notes

- SISOU upstream currently requires Python 3.12+ in practice.
- GnuPG is recommended so SISOU can verify signatures for signed downloads.
- Some updater failures remain upstream/site-specific, such as Fedora mirror layout changes, Microsoft Sentinel rejection for Windows 11 downloads, and transient web server failures.
