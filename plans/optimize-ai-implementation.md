# Plan: Optimize AI Implementation

## Context
The current AI implementation in `res://scripts/ai_controller.gd` uses Minimax with Alpha-Beta pruning. However, it is highly inefficient because it instantiates a new `GameState` object for every single node in the search tree. This leads to excessive memory allocation and garbage collection overhead, which limits the effective search depth. Additionally, it lacks move ordering, meaning the Alpha-Beta pruning is not performing at its full potential.

## Objective
Optimize the AI to allow for greater search depth and better performance by implementing state backtracking and move ordering.

## Proposed Approach

### 1. Implementation Strategy

#### A. Implement State Backtracking in `GameState`
* Modify `res://scripts/game_state.gd` to support an `undo_move` operation.
* When `apply_move` is called, the `GameState` must track not just the piece placed, but also the previous state of all pieces that were flipped.
* Add an `undo_move(move: Dictionary, player: int)` method that restores the board to its state before the move was applied.

#### B. Refactor `AIController` to use a single `GameState`
* Modify `res://scripts/ai_controller.gd` to maintain a single `sim_state` instance.
* In the minimax loop, instead of `GameState.new()`, use `sim_state.apply_move(m, player)` followed by `sim_state.undo_move(m, player)` after the recursive call returns.

#### C. Implement Move Ordering
* In `res://scripts/ai_controller.gd`, before iterating through moves in `_minimax`, sort the `moves` array.
* Use a simple heuristic for sorting (e.g., moves that land on corners or edges first) to increase the likelihood of early pruning.

### 2. Files to be Modified
- `res://scripts/game_state.gd`
- `res://scripts/ai_controller.gd`

### 3. Verification Plan
- **Functional Test**: Ensure the AI still makes valid moves and the game loop remains stable.
- **Performance Test**: Use `execute_game_script` to monitor the time taken for an AI turn at a fixed depth. The optimized version should be significantly faster and use less memory.
- **Regression Test**: Verify that the `undo_move` logic correctly restores the board state, especially in complex flip scenarios.
