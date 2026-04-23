# Implement Manual Pass and Fix AI Turn Transition

## Context
The current implementation has two major issues regarding players being unable to move:
1. **AI Hang**: When the AI (White) has no valid moves, the game does not transition the turn back to the human player, leaving the game stuck.
2. **Player Agency**: When the human player (Black) has no valid moves, they have no way to trigger a "Pass" to continue the game. They are simply stuck.

The goal is to allow players to manually pass their turn and ensure the game continues automatically if the AI is stuck.

## Implementation Plan

### 1. Fix the AI Turn Transition
Modify `_on_ai_move()` in `scripts/main.gd` to call `switch_turn()` if the AI finds no valid moves. This ensures the turn correctly passes back to the human player.
- **File**: `scripts/main.gd`
- **Function**: `_on_ai_move()`

### 2. Add a Manual "Pass" Button
Implement a "Pass" button in the UI so the human player can manually skip their turn when they have no legal moves.
- **File**: `scripts/main.gd`
- **Modifications**:
    - In `_ready()`, instantiate a `Button` named `pass_button`.
    - Position the button near the bottom-right (using anchors and margins).
    - Connect its `pressed` signal to a new method `_on_pass_pressed()`.
    - Implement `_on_pass_pressed()` to call `switch_turn()`, with checks to prevent clicking while animating or during messages.

### 3. Handle Initial Turn Pass
Update `init_board()` to check if the starting player has valid moves. If they don't, automatically trigger the `switch_turn()` process so the game doesn't start in a stuck state.
- **File**: `scripts/main.gd`
- **Function**: `init_board()`

### 4. Refine `switch_turn` (Cleanup)
Ensure that `switch_turn()` is robust and uses the non-blocking timer approach we discussed previously to avoid race conditions with the UI message system.
- **File**: `scripts/main.gd`
- **Function**: `switch_turn()`

## Verification Plan
1. **Test AI Pass**: Set up a board state where the AI has no moves and verify the turn automatically switches back to Black.
2. **Test Manual Pass**: Play a game and find a state where Black has no moves. Verify the "Pass" button is clickable and that clicking it correctly triggers the "Pass!" message and switches the turn.
3. **Test Initial Pass**: Create a scenario where the board initialization results in Black having no moves (if possible via test setup) and verify the game automatically passes.
4. **Regression**: Verify that normal moves and scoring still function correctly.
