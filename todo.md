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

- [ ] Sound effects (piece placement, flips, game-over)
- [ ] Piece flip animation (smooth transition when pieces change color)
- [ ] Difficulty selector / AI depth UI control
- [ ] Two-player local mode toggle (disable AI for White)
- [ ] Game history / replay system
- [ ] Settings menu (board colors, theme)
- [ ] Export builds (Windows, Linux, Web)
- [ ] Sprite-based pieces (replace drawn circles with texture assets for polish)
