# Implementation Plan: AI Toggle, Difficulty, Flip Animation, Sound Effects

## Context

The game is fully playable but lacks player-facing configuration (always AI, fixed difficulty), has instant piece flips, and no audio feedback. These four features will make the game feel polished and give players meaningful choices.

## Implementation Order

1. **AI Toggle + Difficulty Selector** — shared UI container, no runtime flow changes
2. **Piece Flip Animation** — modifies cell drawing and async placement flow
3. **Sound Effects** — independent, wired into existing placement/game-over flow

---

## Feature 1+2: AI Toggle & Difficulty Selector

### Scene changes (`scenes/game_manager.tscn`)

Add a `SettingsHBox` (HBoxContainer) as the **first child** of `UIManager/MarginContainer/VBoxContainer`, above `ScoreLabel`. Contains:
- `AiToggleCheckBox` (CheckBox, text "AI Opponent", checked by default)
- `DifficultyLabel` (Label, text "Difficulty:")
- `DifficultySelector` (OptionButton, items: "Easy", "Medium", "Hard", default index 1)

Skip `scenes/ui_layer.tscn` — it's only referenced by the legacy `main.tscn` and not used by the active game.

### `scripts/ui_manager.gd`

- Add `@onready` refs for `settings_hbox`, `ai_toggle_checkbox`, `difficulty_selector`
- Add signals: `ai_toggle_changed(enabled: bool)`, `difficulty_changed(depth: int)`
- Add methods: `hide_settings()`, `show_settings()`
- Connect CheckBox `toggled` → emit `ai_toggle_changed`
- Connect OptionButton `item_selected` → map index 0→2, 1→4, 2→6, emit `difficulty_changed`
- In `_ready()`: populate OptionButton items if not already set

### `scripts/game_manager.gd`

- Add `var _ai_enabled: bool = true` (persists across restarts)
- Connect `ui_manager.ai_toggle_changed` → `_on_ai_toggle_changed(enabled)`
- Connect `ui_manager.difficulty_changed` → `_on_difficulty_changed(depth)` → updates `config.ai_depth`
- In `init_game()`: use `white_ai_enabled = _ai_enabled` instead of hardcoded `true`
- In `init_game()`: call `ui_manager.hide_settings()` at the end
- In `switch_turn()` game-over branch: call `ui_manager.show_settings()` after showing game-over

### Verification

- Settings visible at game start, hidden after first move
- Unchecking AI → White waits for player clicks
- Changing difficulty → AI plays at selected depth on restart
- Settings reappear at game-over screen

---

## Feature 3: Piece Flip Animation (~200ms)

### `scripts/board_cell.gd`

- Add `signal flip_finished`
- Add vars: `_is_flipping: bool`, `_flip_progress: float`, `_old_color`, `_new_color`, `_flip_tween: Tween`
- Modify `set_piece()`: start a Tween that lerps `_flip_progress` 0→1 over 0.2s, calling `queue_redraw()` each frame via `tween_method`. On completion, set `_piece_color = _new_color`, emit `flip_finished`.
- Modify `_draw()`: when `_is_flipping`, compute `scale = abs(sin(progress * π))` for a 3D-rotation effect (circle shrinks to edge-on, then grows). Lerp color from `_old_color` to `_new_color`.

### `scripts/board.gd`

- Add `signal animations_complete`
- Make `place_piece()` async: update `_state` synchronously first (critical for AI), then call `set_piece()` on animating cells, await `animations_complete`, then emit `piece_placed`/`valid_moves_changed`
- Track completion with counter: `_pending_animations` array, `_animations_done_count`, disconnect signals after completion

### `scripts/game_manager.gd`

- In `perform_move()`: replace `await get_tree().create_timer(0.5).timeout` with `await board.animations_complete` (since `place_piece` is now async)

### Verification

- Pieces shrink to a line and reappear with new color over ~200ms
- Multiple flips animate simultaneously
- Turn switches only after all animations finish
- AI still works (state updated before animation)

---

## Feature 4: Sound Effects

### Generate audio assets

Create `res://sounds/generate_sounds.gd` — an EditorScript that generates three `AudioStreamSample` resources programmatically:
- `click.tres` — 100ms percussive click (1000 Hz sine, fast decay)
- `flip.tres` — 200ms swoosh (800→300 Hz frequency sweep)
- `gameover.tres` — 500ms two-note chord (C5+G5, slow decay)

Run once via Godot editor's Script → Run Script menu.

### Scene changes (`scenes/game_manager.tscn`)

Add `SoundPlayer` (AudioStreamPlayer) as child of `GameManager`.

### `scripts/game_manager.gd`

- Add `preload()` constants for three sound resources
- Add `@onready var sound_player = $SoundPlayer`
- Add `_play_click()`, `_play_flip()`, `_play_gameover()` helpers
- Call `_play_click()` at start of `perform_move()`
- Call `_play_flip()` after `place_piece()` begins (concurrent with animation)
- Call `_play_gameover()` in game-over branch of `switch_turn()`

### Verification

- Click sound on piece placement
- Swoosh sound during flip animation
- Tone on game-over

---

## Files Modified

| File | Features |
|------|----------|
| `scenes/game_manager.tscn` | 1, 2, 4 — new UI nodes + SoundPlayer |
| `scripts/ui_manager.gd` | 1, 2 — settings refs, signals, show/hide |
| `scripts/game_manager.gd` | 1, 2, 3, 4 — toggle logic, async flow, sounds |
| `scripts/board.gd` | 3 — async place_piece, animation tracking |
| `scripts/board_cell.gd` | 3 — flip animation with Tween |
| `res://sounds/generate_sounds.gd` | 4 — NEW editor script |
| `res://sounds/click.tres` | 4 — NEW generated asset |
| `res://sounds/flip.tres` | 4 — NEW generated asset |
| `res://sounds/gameover.tres` | 4 — NEW generated asset |

## Testing Plan

1. Run game → verify settings panel visible
2. Change difficulty to Hard, check AI → play a few moves → verify AI plays
3. Restart, uncheck AI → verify both players can click
4. Make a move → verify flip animation plays smoothly
5. Verify click and flip sounds play
6. Play to game-over → verify game-over sound and settings reappear
7. Click Restart → verify clean game state with new settings
