# Architectural Refactoring: Decoupling the God Object

## Context
The current implementation of the Othello game relies on a single monolithic script, `scripts/main.gd`, which handles game state, board logic, AI decision-making, UI management, and rendering. This "God Object" pattern makes the codebase difficult to maintain, test, and extend.

The goal of this refactor is to decompose `main.gd` into specialized, decoupled components that communicate through signals and a central orchestrator, following the modular patterns seen in the `godot_mcp` plugin.

## Implementation Plan

### 1. Component Creation
I will create the following new specialized scripts and scenes:

#### A. The Board (Logic & State)
- **File**: `res://scripts/board.gd`
- **Responsibility**: Manages the 2D array, piece placement, and move validation (including piece flipping logic).
- **Key Signals**: `piece_placed(pos, player, flips)`, `valid_moves_changed(moves)`.

#### B. The AI Controller (Intelligence)
- **File**: `res://scripts/ai_controller.gd`
- **Responsibility**: Encapsulates the heuristic decision-making logic.
- **Key Signals**: `move_requested(move)`.

#### C. The UI Manager (Presentation)
- **File**: `res://scripts/ui_manager.gd` and `res://scenes/ui_layer.tscn`
- **Responsibility**: Manages all visual elements (score labels, turn labels, message overlays, buttons).
- **Key Signals**: (Listens to `GameManager` signals to update the view).

#### D. The Game Manager (Orchestration)
- **File**: `res://scripts/game_manager.gd`
- **Responsibility**: The central hub that coordinates the components. It handles the game loop, turn switching, and acts as the primary communication bridge between the Board, AI, and UI.

### 2. Scene Restructuring
- **Update `res://scenes/main.tscn`**: 
    - Replace the single `Control` node (main.gd) with a structured node tree:
        - `Main (GameManager)`
            - `Board (Board)`
            - `AIController (AIController)`
            - `UIManager (UIManager, instantiating `ui_layer.tscn`)`

### 3. Communication Flow
- **Turn Logic**: `GameManager` calls `Board.get_valid_moves()`. If empty, `GameManager` calls `UIManager.show_message("Pass!")` and triggers `switch_turn()`.
- **AI Logic**: `GameManager` detects it's the AI's turn $\rightarrow$ calls `AIController.choose_move()` $\rightarrow$ calls `Board.place_piece()`.
- **UI Updates**: `Board` emits `piece_placed` $\rightarrow$ `GameManager` receives it $\rightarrow$ `GameManager` tells `UIManager` to update the score and turn labels.

## Verification Plan
1. **Functional Regression**: Run the game and verify that:
    - Pieces can still be placed.
    - Flipping logic is correct.
    - AI still plays its turn.
    - The "Pass" button works.
    - Scoring and Turn Labels update correctly.
2. **Architectural Audit**: Ensure `Board` has no references to `UIManager` or `AIController`, and `AIController` only knows about the `Board`'s move possibilities.
3. **Error Check**: Monitor the Godot output log for any signal connection errors or null references during turn transitions.
