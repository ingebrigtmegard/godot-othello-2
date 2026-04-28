# Implementation Plan: Settings Menu — Preset Board Themes

## Context

The game currently has hardcoded board colors (green background, dark green grid). Players want the ability to customize the board's visual appearance. This plan adds a **preset theme selector** to the existing `SettingsHBox`, offering four named themes that change the board background and grid line colors. Piece rendering stays unchanged (PNG textures already have proper colors).

## Theme Definitions

| Theme | Board Background | Grid Lines |
|-------|------------------|------------|
| Classic Green (default) | `Color(0.1, 0.35, 0.15)` | `Color(0.05, 0.2, 0.05)` |
| Dark Mode | `Color(0.15, 0.15, 0.2)` | `Color(0.08, 0.08, 0.12)` |
| Ocean Blue | `Color(0.05, 0.2, 0.35)` | `Color(0.03, 0.12, 0.2)` |
| Wood | `Color(0.35, 0.22, 0.08)` | `Color(0.22, 0.14, 0.05)` |

## Files Modified

| File | Change |
|------|--------|
| `scripts/game_config.gd` | Add `board_bg_color` and `grid_color` exports |
| `scripts/board.gd` | Replace hardcoded colors with instance vars; add `apply_theme()` method |
| `scripts/board_cell.gd` | No changes (piece textures are PNGs with baked-in colors) |
| `scripts/ui_manager.gd` | Add `_THEMES` constant, `theme_changed` signal, UI refs, persistence via ConfigFile |
| `scripts/game_manager.gd` | Connect `theme_changed`; wire to `board.apply_theme()` |
| `scenes/game_manager.tscn` | Add `ThemeLabel` + `ThemeSelector` under `SettingsHBox` |

## Implementation Steps

### 1. `scripts/game_config.gd` — Add board color exports

Add two properties after `white_color`:
```gdscript
@export var board_bg_color: Color = Color(0.1, 0.35, 0.15)
@export var grid_color: Color = Color(0.05, 0.2, 0.05)
```

### 2. `scripts/board.gd` — Make colors configurable

- Add instance vars: `var board_bg_color`, `var grid_color` (default to Classic Green)
- In `_ready()`: read from `config` if present
- In `_draw()`: replace hardcoded `Color(0.1, 0.35, 0.15)` → `board_bg_color`, hardcoded `Color(0.05, 0.2, 0.05)` → `grid_color`
- Add `func apply_theme(bg_color, gr_color)`: update both vars and `queue_redraw()`

### 3. `scripts/ui_manager.gd` — Theme selector with persistence

- Add `_THEMES` constant — array of 4 Dictionaries: `{"name": "...", "bg": Color(...), "grid": Color(...)}`
- Add `signal theme_changed(bg_color: Color, grid_color: Color)`
- Add `@onready` refs for `theme_label`, `theme_selector`
- `_populate_theme_selector()`: add items from `_THEMES`
- `_load_saved_theme()` → `ConfigFile` read from `user://settings.cfg` (section `"settings"`, key `"theme_index"`, default `0`)
- `_save_theme(index)` → `ConfigFile` write to `user://settings.cfg`
- `_apply_theme(index)`: lookup theme, emit `theme_changed`, set dropdown selection, save index
- In `_ready()`: call `_populate_theme_selector()`, then `call_deferred("_apply_initial_theme")` to avoid signal timing issues
- Connect `theme_selector.item_selected` → `_apply_theme(index)`

### 4. `scripts/game_manager.gd` — Wire theme to board

- In `_ready()`: connect `ui_manager.theme_changed` → `_on_theme_changed(bg, gr)`
- `_on_theme_changed()`: update `config` if present, call `board.apply_theme(bg, gr)`

### 5. `scenes/game_manager.tscn` — Add UI nodes

Add to `SettingsHBox` (after `DifficultySelector`):
- `ThemeLabel` (Label, text "Theme:", `layout_mode=2`, `size_flags_horizontal=3`)
- `ThemeSelector` (OptionButton, `layout_mode=2`, `size_flags_horizontal=3`)

## Signal Timing

`UIManager._ready()` runs before `GameManager._ready()` (Godot depth-first). The initial theme must be applied with `call_deferred()` in ui_manager so the `theme_changed` signal fires AFTER game_manager has connected to it.

## Persistence

Theme index saved to `user://settings.cfg` via `ConfigFile`. Persists across full application restarts. Survives game restarts within the same session automatically since `board.apply_theme()` updates instance vars.

## Verification

1. **Default start**: Board shows Classic Green colors; dropdown shows "Classic Green"
2. **Theme change at game-over**: Select "Dark Mode" → board immediately redraws with dark gray
3. **Mid-game change**: After some pieces placed, change theme → board colors update, pieces unchanged
4. **Persistence**: Close and relaunch → previously selected theme is active
5. **Restart preserves theme**: Click Restart with "Wood" active → new game uses Wood colors
6. **All four themes**: Cycle through all themes, verify distinct colors
