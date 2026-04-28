# Implementation Plan: Sprite-Based Pieces

## Context

The game currently draws pieces as flat colored circles via `_draw()` in `board_cell.gd`. Replacing these with textured disc sprites (gradients, highlights, shadows) will dramatically improve visual polish. The flip animation (3D rotation effect) and valid-move indicators need to be preserved.

## Approach

Generate two piece textures (black and white disc PNGs) programmatically with Python, then replace the `_draw()` circle drawing with a `TextureRect` that swaps textures. The flip animation will scale the TextureRect (shrinking for edge-on effect) and swap textures at midpoint.

## Step 1: Generate piece textures

Use Python to create two 100x100 PNG files in `res://assets/`:

- **`piece_black.png`** — Dark disc with radial gradient (dark gray center to near-black edge), subtle top-left highlight, and soft drop shadow
- **`piece_white.png`** — Off-white disc with radial gradient (white center to light-gray edge), subtle top-left highlight, and soft drop shadow

Both will have transparent corners (alpha channel) so they render as circles on any background.

## Step 2: Update `scenes/board_cell.tscn`

Replace the existing `PieceVisual` ColorRect with a `TextureRect` named `PieceVisual`:
- Centered (same anchors: 0.5/0.5, offsets ±25)
- `expand` flags on both axes
- `mouse_filter = IGNORE`
- No texture assigned initially (set from script)

## Step 3: Modify `scripts/board_cell.gd`

**Preload textures at top of script:**
```gdscript
const BLACK_PIECE = preload("res://assets/piece_black.png")
const WHITE_PIECE = preload("res://assets/piece_white.png")
```

**Remove draw-based piece rendering from `_draw()`:** Keep only the valid-move indicator circles. The piece itself is now the `PieceVisual` TextureRect.

**Modify `set_piece()`:** Still accepts `(player, color)` for backward compatibility but uses player to select texture. Start flip animation on the TextureRect's scale and swap texture at midpoint.

**Flip animation via Tween on TextureRect:**
1. Tween scale from `Vector2(1,1)` → `Vector2(0.05, 1)` over 100ms (shrink to edge-on)
2. At midpoint callback: swap texture to target color
3. Tween scale from `Vector2(0.05, 1)` → `Vector2(1,1)` over 100ms (grow back)
4. Emit `flip_finished` when done

**Hide piece when player is EMPTY (0):** Set `PieceVisual.visible = false`

## Step 4: Modify `scripts/board.gd`

No changes needed. `place_piece()` calls `cell.set_piece(player, color)` which remains the same interface. The color parameter is ignored internally but kept for API compatibility.

## Step 5: Clean up

Remove the unused `_piece_color`, `_old_color`, `_new_color` variables and the color-related drawing code from `board_cell.gd`.

## Files Modified

| File | Change |
|------|--------|
| `assets/piece_black.png` | NEW — generated black disc texture |
| `assets/piece_white.png` | NEW — generated white disc texture |
| `scenes/board_cell.tscn` | Replace ColorRect with TextureRect |
| `scripts/board_cell.gd` | Texture-based rendering, scale-based flip animation |

## Verification

1. Run game — pieces should look like textured discs with gradients and highlights
2. Make a move — flip animation should shrink piece to edge-on, swap color, grow back
3. Valid move indicators should still show as green translucent dots
4. Game-over and restart should work with new textures
