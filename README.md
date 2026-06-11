# DTLmenu

**A graphical build launcher for the NetDTL Suite — Windows HTA application**
v 1.0.0 11-jun-2026 Didier DTL Morandi https://didiermorandi.com/netdtl/

DTLmenu is a Windows HTML Application (`.hta`) that replaces a plain VBScript menu with a dark-themed, terminal-style GUI. It lets you trigger PyInstaller builds for each Python tool in the NetDTL Suite with a single click, open output folders directly in Explorer, and verify your Python environment — all without touching the command line manually.

---

## Overview

The NetDTL Suite consists of four tools:

| Tool | Stack | Build method |
|------|-------|--------------|
| DTLknowsWhy | Python (+ CLI + Agent) | PyInstaller `.spec` files |
| DTLsaysWhat | Python | PyInstaller `--onefile` |
| GitDTL | Python / Tkinter | PyInstaller `.spec` file |
| NetDTL | PHP / MySQL | No build required |

DTLmenu covers all of them from a single window.

---

## Requirements

- Windows (any version with `mshta.exe` — included in all Windows releases since XP)
- Python installed and accessible via `python` in `PATH`
- PyInstaller installed (`pip install pyinstaller`)
- The NetDTL Suite source tree present on disk

No additional dependencies. DTLmenu is a single self-contained `.hta` file.

---

## Installation

Copy `DTLmenu.hta` anywhere on the machine — alongside the suite root folder works well. No installer, no registry entry, no virtual environment required.

---

## Usage

Double-click `DTLmenu.hta`. Windows will open it with `mshta.exe`.

> On some systems, Windows may display a security warning on first launch depending on the file's origin zone. If so, right-click the file, open Properties, and click **Unblock** at the bottom of the General tab.

### Setting the root directory

At the top of the window, set `ROOT_DIR` to the folder that contains the four tool subdirectories (`DTLKnowsWhy`, `DTLsaysWhat`, `NetDTL`, `GitDTL`). Click **apply** to propagate the path to all screens.

The default value matches the original development path:

```
C:\Users\Utilisateur\Documents\Mes sites Web\Secours catholique\outils
```

Change it once to match your local layout.

### Menu options

| Key | Action |
|-----|--------|
| 1 | Build DTLknowsWhy (main executable, CLI variant, and background Agent) |
| 2 | Build DTLsaysWhat (single-file console executable) |
| 3 | NetDTL — display path information (no build needed) |
| 4 | Build GitDTL |
| 5 | Build all Python tools in sequence |
| 6 | Open a `dist\` output folder in Windows Explorer |
| 7 | Verify Python and PyInstaller versions |
| 0 | Quit |

### How builds are executed

When you click **execute** on any build screen, DTLmenu:

1. Assembles the corresponding `cmd` commands, including dependency checks and PyInstaller invocations.
2. Writes a temporary `.cmd` script to `%TEMP%\DTLmenu_run.cmd`.
3. Launches it in a visible Command Prompt window (`cmd.exe`) so you can follow the output in real time.
4. On completion, the window pauses and waits for a keypress before closing.

If any `python` command exits with a non-zero code, the script stops and prints an error message.

---

## File structure

```
outils\
├── DTLmenu.hta
├── DTLKnowsWhy\
│   ├── DTLknowsWhy.spec
│   ├── DTLknowsWhy-CLI.spec
│   ├── agent\
│   │   └── DTLknowsWhy-Agent.spec
│   └── dist\
├── DTLsaysWhat\
│   ├── DTLsaysWhat.py
│   └── dist\
├── GitDTL\
│   ├── GitDTL.spec
│   └── dist\
└── NetDTL\
```

---

## Design notes

DTLmenu is built as an `.hta` rather than a plain `.html` file because HTML Applications run with elevated trust under `mshta.exe`, which grants access to `WScript.Shell` and `Scripting.FileSystemObject` — the two COM objects needed to write and execute `.cmd` scripts and to open Explorer windows.

The UI uses only IE-compatible CSS (no `flexbox`, no `grid`) to match the rendering engine embedded in `mshta.exe`. The dark terminal aesthetic — IBM-influenced monospace font, phosphor green accents, blue highlights — follows the visual identity of the wider NetDTL Suite, itself a tribute to DEC VT100 terminals and the culture of Digital Equipment Corporation (1957–1998).

---

## License

MIT — see the main NetDTL repository for the full license text.

Part of the **NetDTL Suite** — [didiermorandi.com/netdtl](https://didiermorandi.com/netdtl)