# Plan: Stabilize the Game Loop

## Context
The current game loop in `GameManager.gd` has inconsistent turn-switching, especially when transitioning from player moves to AI turns. The `animating` and `message_ready` flags, which are intended to prevent invalid user input during transitions or animations, are not consistently set during the entire turn lifecycle. This creates windows where a player can attempt a move while the AI is thinking or during a turn transition.

The primary vulnerability is in `call_ai_turn`, where a 0.5s "thinking" delay occurs while `animating` is `false`, allowing user input to trigger a move during the AI's turn.

## Objective
Ensure that the `animating` flag covers the entire duration of a turn, from the moment a move is made until the next player (human or AI) is ready to receive input.

## Proposed Approach

### 1. Implementation Strategy

I will modify `res://scripts/game_manager.gd` to ensure the `animating` flag is held throughout the entire state transition.

#### A. Update `perform_move`
*   The `animating = false` assignment will be moved to the end of the function, *after* `await switch_turn()`. This ensures that the "busy" state is maintained throughout the entire turn transition, including the subsequent turn's setup.

#### B. Update `switch_turn`
*   Set `animating = true` at the start of the function.
*   Ensure `animating = false` is called at every exit path:
    *   **Game Over**: When the game ends.
    *   **Pass**: After the "Pass!" message is displayed and the player is switched.
    *   **Normal Turn**: After the turn is swapped and (if applicable) the AI turn is initiated.

This will effectively cover the "AI thinking" window in `call_ai_turn` because `switch_turn` will be holding the `animating` flag while it awaits the AI.

### 2. Files to be Modified
- `res://scripts/game_manager.gd`

### 3. Verification Plan
- **Manual Testing**: Use `simulate_mouse_click` in the running game during the identified "thinking" windows (the 0.5s after a move and the 0.5s during AI decision) to verify that input is ignored.
- **Runtime Inspection**: Use `execute_game_script` to monitor `animating` and `message_ready` values throughout a full turn cycle to confirm there are no gaps.
- **AI Turn Verification**: Verify that the AI can still make moves and that the game loop continues correctly.
