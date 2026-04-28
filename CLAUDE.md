# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**GodotOthello2** — A Reversi/Othello game in active development using Godot 4.6 (Forward Plus). The game is playable with full Reversi rules, AI opponent (Minimax with alpha-beta pruning), responsive UI, and round piece rendering. See `todo.md` for remaining work.

## Tech Stack

- **Engine**: Godot 4.6 (Forward Plus renderer, D3D12 on Windows)
- **Language**: GDScript (primary); .NET/C# assembly configured but no C# code yet
- **Physics**: Jolt Physics (3D)
- **Addon**: `godot_mcp` (MCP Pro v1.12.0) — AI-assisted development via WebSocket (ports 6505-6514), exposing 172+ editor/runtime tools

## Project Structure

```
project.godot               # Godot 4.6 project config
todo.md                     # Feature status and remaining work
addons/godot_mcp/           # MCP Pro addon — AI-assisted editor tools
  plugin.cfg / plugin.gd    # Entry point: EditorPlugin that starts WebSocket server
  command_router.gd         # Routes MCP commands to command handlers
  commands/                 # 20+ command modules (scene, physics, audio, export, etc.)
  mcp_*.service.gd          # 3 autoloaded services: screenshot, input, game inspector
  websocket_server.gd       # WebSocket server for MCP protocol
  ui/status_panel.tscn/gd   # Bottom-panel UI showing MCP status
  skills.md                 # Reference of available MCP commands for AI use
scenes/                     # Game scenes
  game_manager.tscn         # Main scene — GameManager root with Board, AIController, UIManager
  board_cell.tscn           # Cell scene — Button with round piece drawing
scripts/                    # Game scripts
  game_manager.gd           # Orchestrates game flow, turn switching, pass/game-over
  board.gd                  # Board state, cell management, piece placement, drawing
  board_cell.gd             # Cell rendering (round pieces, valid move indicators)
  ai_controller.gd          # Minimax AI with alpha-beta pruning, positional evaluation
  ui_manager.gd             # UI updates (score, turn, messages, button visibility)
  game_state.gd             # Standalone game state engine with undo for AI simulation
  game_constants.gd         # Centralized constants (EMPTY, BLACK, WHITE) autoload
  game_config.gd            # Custom Resource for board offset, cell size, colors, AI depth
```

## Autoloads (configured in project.godot)

- `GameConstants` — centralized EMPTY/BLACK/WHITE constants
- `MCPScreenshot` — captures in-game screenshots
- `MCPInputService` — handles input injection into the game
- `MCPGameInspector` — exposes game state for AI inspection

## Version Control

- **Git**: Managed via Git.
- **GitHub**: The project is stored in a remote GitHub repository.
- **Commit Policy**: All changes must be saved with informative, concise commit messages that describe the *why* of the change (e.g., `fix: resolve race condition in turn switching` instead of `update main.gd`).

## MCP Connection

The `godot_mcp` addon (MCP Pro v1.12.0) provides AI-assisted development through a WebSocket server that runs inside the Godot editor.

- **Protocol**: MCP (Model Context Protocol) over WebSocket
- **Ports**: 6505–6514 (auto-selected on startup)
- **Tools exposed**: 172+ editor and runtime tools (scene editing, physics, audio, export, testing, etc.)
- **How it works**: The addon's `websocket_server.gd` starts a local WebSocket server when the plugin is enabled. Claude Code connects to this server to send MCP commands, which the `command_router.gd` routes to the appropriate command handlers.
- **Autoloads**: Three MCP services are auto-loaded into every running game:
  - `MCPScreenshot` — captures in-game screenshots
  - `MCPInputService` — handles input injection into the game
  - `MCPGameInspector` — exposes game state for AI inspection
- **Status UI**: A bottom-panel status indicator (`ui/status_panel.tscn`) shows whether the MCP connection is active.
- **Skills reference**: Full command reference is available in `addons/godot_mcp/skills.md`.

> **Important**: Never edit `project.godot` directly — the Godot editor constantly overwrites it. Always use `set_project_setting` to change project settings.

## Godot Installation

- **Godot 4.6.2 Mono executable**: `/c/Users/ingeb/Godot/Godot_v4.6.2-stable_win64.exe`
- Launch the editor with: `Godot_v4.6.2-stable_win64.exe --editor --path <project_path>`
- Launch headless with: `Godot_v4.6.2-stable_win64.exe --path <project_path> --headless`

## Developing

- Open this project in **Godot 4.6 editor** (Forward Plus template).
- The `godot_mcp` addon auto-injects its autoloads into ProjectSettings when enabled in the editor.
- Run the project in the editor (F5) to test. Main scene is `scenes/game_manager.tscn`.
- Game is playable: Black plays first via cell clicks, White is controlled by AI.
- **UI layout**: GameManager uses anchor-based resizing. Board cells are fixed-size Buttons positioned absolutely within the board.
- **Pieces**: Drawn as circles in `board_cell.gd`'s `_draw()` method — no external textures yet.
