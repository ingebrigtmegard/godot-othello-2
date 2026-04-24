# Plan: Refine AI Heuristics

## Context
The current AI heuristic in `res://scripts/ai_controller.gd` is functional but relatively simplistic, relying on a few hardcoded positional rules and a low-weight mobility component. This limits the AI's ability to make strategic long-term decisions, especially in mid-game transitions.

## Objective
Improve the AI's strategic depth by implementing a more nuanced heuristic evaluation function.

## Proposed Approach

### 1. Implementation Strategy

#### A. Implement a Positional Weight Matrix
*   Replace the `if/elif` conditional logic in `_evaluate` with a pre-calculated 8x8 weight matrix.
*   This matrix will provide fine-grained values for every cell on the board, allowing for much more precise control over positional advantage.
*   **Weights will include:**
    *   **Corners**: High positive values.
    *   **Corner-adjacent (X-squares)**: Significant negative values.
    *   **Edges**: Moderate positive values.
    *   **Rest of board**: Neutral or slight values.

#### B. Add a Stability Component
*   Introduce a "stability" check to reward pieces that are difficult for the opponent to flip.
*   **Stability Criteria:**
    *   **Corner pieces**: Extremely high stability bonus.
    *   **Edge pieces**: Moderate stability bonus if they are part of a continuous line of the same color along the edge.

#### C. Refine Mobility Weighting
*   Increase the weight of the mobility component to make the AI more proactive in maintaining its options and restricting the opponent's.

### 2. Files to be Modified
- `res://scripts/ai_controller.gd`

### 3. Verification Plan
- **Functional Test**: Ensure the AI still makes valid moves and the game loop remains stable.
- **Strategic Test**: Play several games against the AI and observe if it plays more "positionally aware" moves (e.g., fighting for corners and edges, avoiding X-squares).
- **Performance Test**: Ensure the added complexity in `_evaluate` doesn't significantly degrade the AI's search speed.
