# GodotOthello2 - Feature Status

## Implemented

- **Game board**: 8x8 Reversi/Othello grid with cell-based input (Button scenes)
- **Game logic**: Full Reversi rules — turn switching, piece flipping, valid move calculation
- **GameState**: Standalone game state engine with move apply/undo for AI simulation
- **AI opponent**: Minimax with alpha-beta pruning, positional evaluation (corners/edges/mobility), configurable depth, move ordering
- **Two-player local mode**: "AI Opponent" checkbox toggles between AI and human White player
- **Difficulty selector**: Dropdown (Easy/Medium/Hard → depth 2/4/6), visible at game start, persists across restarts
- **Piece flip animation**: 200ms 3D rotation effect — circle shrinks edge-on, color lerps from old to new
- **Sound effects**: Procedurally generated click (placement), swoosh (flip), and chord (game-over) via `AudioStreamPlayer`
- **Modular architecture**: Board, AIController, UIManager, GameManager separated into distinct nodes and scripts
- **UI scene**: Responsive layout using Godot containers with score, turn, message, restart, pass, and settings panel
- **Round pieces**: Circular piece rendering with subtle shadow
- **Valid move indicators**: Green translucent dots on legal cells
- **Pass handling**: Auto-pass when a player has no moves; game-over detection when neither can move
- **Restart**: Full game reset, clears game-over message, restores settings panel
- **GameConfig resource**: Configurable board offset, cell size, colors, and AI depth via `.tres`
- **Game constants**: Centralized EMPTY/BLACK/WHITE constants in autoloaded GameConstants
- **Sprite-based pieces** — Replace drawn circles with textured disc PNGs (radial gradients, highlights, drop shadows). Animate flip via TextureRect scale (shrink to edge-on, swap texture at midpoint, grow back).
- **Turn visibility** — Ensure UI renders before AI plays so turn changes are visible to the player.
- **Settings menu** — Preset board themes (Classic Green, Dark Mode, Ocean Blue, Wood) selectable via dropdown in SettingsHBox. Persists across restarts via ConfigFile.
- **Game history / replay system** — Records all moves during gameplay. After game-over, "Replay" button appears. Click to enter replay mode showing initial 4-piece position with Prev/Next/Exit controls and step counter (e.g. "3/12"). Rebuilds board from initial state forward using `apply_move()`. Cell clicks disabled during replay. Exit returns to game-over screen.

## Remaining

- [ ] Export builds (Windows, Linux, Web)
