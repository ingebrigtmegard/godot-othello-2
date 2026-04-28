# GodotOthello2 - Feature Status

## Implemented

- **Game board**: 8x8 Reversi/Othello grid with cell-based input (Button scenes)
- **Game logic**: Full Reversi rules — turn switching, piece flipping, valid move calculation
- **GameState**: Standalone game state engine with move apply/undo for AI simulation
- **AI opponent**: Minimax with alpha-beta pruning, positional evaluation (corners/edges/mobility), configurable depth, move ordering
- **Modular architecture**: Board, AIController, UIManager, GameManager separated into distinct nodes and scripts
- **UI scene**: Responsive layout using Godot containers (MarginContainer, VBoxContainer, HBoxContainer) with score, turn, message, restart, and pass buttons
- **Round pieces**: Circular piece rendering with subtle shadow
- **Valid move indicators**: Green translucent dots on legal cells
- **Pass handling**: Auto-pass when a player has no moves; game-over detection when neither can move
- **Restart**: Full game reset, clears game-over message
- **GameConfig resource**: Configurable board offset, cell size, colors, and AI depth via `.tres`
- **Game constants**: Centralized EMPTY/BLACK/WHITE constants in autoloaded GameConstants

## Remaining

### High Priority (next to implement)

- [ ] **Two-player local mode** — Add a toggle (button or setting) to disable AI for White, letting a second player control White via cell clicks
- [ ] **Difficulty selector** — Add a dropdown (Easy/Medium/Hard) in the UI that maps to AI depth values (2/4/6). Persist choice across restarts.
- [ ] **Piece flip animation** — Smooth color interpolation (~200ms) when pieces change color during a flip, instead of instant snap
- [ ] **Sound effects** — Add audio feedback for piece placement, piece flips, and game-over announcement. Wire up via `AudioStreamPlayer` nodes on bus.

### Lower Priority

- [ ] Game history / replay system
- [ ] Settings menu (board colors, theme)
- [ ] Export builds (Windows, Linux, Web)
- [ ] Sprite-based pieces (replace drawn circles with texture assets for polish)
