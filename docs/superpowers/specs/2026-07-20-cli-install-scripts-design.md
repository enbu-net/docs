# CLI Install Scripts Design

**Date:** 2026-07-20  
**Status:** Approved

## Overview

Add `install.sh` (macOS / Linux) and `install.ps1` (Windows) to `public/` so users can install the enbu CLI with a one-liner. Update the docs Getting Started page to show these commands.

## Goals

- Zero-friction install: one command, no manual PATH setup
- Always installs the latest release via GitHub API
- `$ENBU_INSTALL_DIR` / `$env:ENBU_INSTALL_DIR` overrides the install directory
- No root / sudo required by default

## Files

| File | Purpose |
|------|---------|
| `public/install.sh` | macOS + Linux installer |
| `public/install.ps1` | Windows PowerShell installer |
| `src/content/docs/docs/index.md` | Updated Getting Started docs |

## `install.sh` Logic

1. Resolve install directory:
   - Use `$ENBU_INSTALL_DIR` if set
   - Else use `/usr/local/bin` if writable
   - Else use `~/.local/bin` (create if missing)
2. Fetch latest version from `https://api.github.com/repos/enbu-net/enbu/releases/latest`
3. Detect OS (`uname -s`: `Darwin` → `darwin`, `Linux` → `linux`) and ARCH (`uname -m`: `arm64`/`aarch64` → `arm64`, else → `amd64`)
4. Download `enbu_<version>_<os>_<arch>.tar.gz` from GitHub Releases
5. Extract binary, copy to install dir, remove temp files
6. PATH update (if install dir not already in PATH):
   - Append `export PATH="<dir>:$PATH"` to `~/.zshrc`, `~/.bashrc`, `~/.profile` as detected
   - Export into current session immediately
   - Print message: "Restart your shell or run: source ~/.zshrc"

## `install.ps1` Logic

1. Resolve install directory:
   - Use `$env:ENBU_INSTALL_DIR` if set
   - Else use `$env:LOCALAPPDATA\enbu\bin` (no admin rights needed)
2. Fetch latest version from GitHub API
3. Download `enbu_<version>_windows_amd64.zip`
4. Extract `enbu.exe`, move to install dir
5. PATH update (if install dir not in PATH):
   - Add to user-scope PATH via `[Environment]::SetEnvironmentVariable`
   - Update current session's `$env:PATH` immediately
   - Print message: "Open a new terminal to use enbu"

## Docs Update (`index.md`)

Replace the current `go install` install section with:

```markdown
## Install the CLI

**macOS / Linux**

```sh
curl -fsSL https://enbu.net/install.sh | sh
```

**Windows (PowerShell)**

```powershell
irm https://enbu.net/install.ps1 | iex
```

Alternatively, install with Go:

```sh
go install github.com/yashikota/enbu@latest
```
```

## Out of Scope

- ARM Windows support (not in current releases)
- Package manager integrations (Scoop, winget) — separate task
- Version pinning via script argument — GitHub API always returns latest
