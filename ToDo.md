# Project Roadmap & Improvements

This document tracks the long-term goals for refactoring and improving the Godot Othello project.

## 🏗️ Architectural Refactoring (Decoupling)
Currently, `main.gd` acts as a "God Object"—it handles game logic, AI, UI creation, input, and even low-level drawing.
- [ ] **Split responsibilities into specialized nodes**:
    - [ ] **Board Node**: Handles the 2D array, piece placement, and move validation.
    - [ ] **AIController Node**: Contains the heuristic and decision-making logic.
    - [ ] **UIManager Node**: Manages labels, buttons, and score display.
    - [ ] **GameManager (Main)**: Orchestrates the communication between the other three.

## 🎨 UI & Input Enhancements
- [ ] **Use Godot's Scene System for UI**: Move procedural UI creation from `_ready()` to a dedicated `.tscn` file to leverage the Godot Editor for layouts and themes.
- [ ] **Transition to a Cell-Based Input Model**: Replace manual coordinate math in `_input()` by making each cell a small `Button` or `Area2D` node, using Godot's built-in signal system.

## 🧠 Intelligence & Gameplay
- [ ] **Strengthen the AI**: Implement a **Minimax algorithm with Alpha-Beta pruning** to allow the AI to look ahead multiple moves.

## ⚙️ Engine & Rendering Optimization
- [ ] **Configuration via Resources**: Move hardcoded constants (like `BOARD_OFFSET`, `CELL_SIZE`, and colors) into a custom `Resource` class (e.g., `GameConfig.gd`) to allow easy tweaking via `.tres` files.
- [ ] **Improved Drawing via TileMap**: Replace the low-level `_draw()` implementation with a `TileMapLayer` to use actual sprites for pieces and textures, improving visual polish.
