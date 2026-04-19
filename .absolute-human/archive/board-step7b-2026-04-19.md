# Absolute-Human Board — RoguelikeTD Step 7b: Hero Repositioning + Wave Preview
**Status:** completed
**Session:** 2026-04-19
**Previous Board:** archive/board-step7-2026-04-19.md

## Intake Summary
- **Project:** C:\Users\VoidHoe\Desktop\RoguelikeTD\
- **Scope:** Step 7b — Hero repositioning between slots + wave preview panel
- **Engine:** Godot 4.4.1 / GDScript
- **GDD reference:** `C:\Users\VoidHoe\.claude\plans\2026-04-18-roguelike-td-design.md`
- **Board:** Git-tracked

### What we're building
**Hero repositioning:** Currently, clicking an occupied slot deletes the hero.
Per GDD: "Reposition heroes freely (no cost)" between waves.
New behavior: click occupied slot → pick up (hero goes semi-transparent) → click empty slot → moves there. Click same slot or press ESC → cancel.

**Wave preview panel:** Before each wave, a small label in the HUD shows what enemies are coming: "Vague 2 : 3× Guerrier · 3× Rogue". Visible after draft choice resolves, hidden once wave starts. Gives the player the information they need to reposition heroes intelligently.

### Project conventions
- GDScript 4.x, snake_case files, PascalCase class_name
- TDD with GUT where applicable; UI logic verified by requirements checklist
- State managed in run_test.gd; WaveController owns wave definitions
- `_placed_heroes: Dictionary` maps slot_node → HeroBase
- `_slot_map: Dictionary` maps slot_node → PlacementSlot

## Task Graph

```
RTD-REP-001 (Hero Repositioning — run_test.gd) ──┐
                                                   ├──→ RTD-REP-003 (Code Review + Requirements)
RTD-REP-002 (Wave Preview — wavecontroller +      ──┘
             run_test.gd)
```

## Wave Assignments

| Wave | Tasks | Status |
|---|---|---|
| 1 | RTD-REP-001, RTD-REP-002 | ✅ done |
| 2 | RTD-REP-003 | ✅ done |

---

## Per-Task Execution Plans

### RTD-REP-001 — Hero Repositioning
**Wave:** 1 | **Files:** `scripts/run_test.gd`

**New state vars:**
```gdscript
var _reposition_source: Node2D = null   # slot_node hero was picked up from
var _reposition_hero: HeroBase = null   # the hero being repositioned
```

**Modified `_on_slot_clicked` logic:**
```
if _pending_placement not empty:
    → same as before (place new hero from shop)

if _is_wave_active:
    → return (no interaction during wave)

if _reposition_source != null:   # IN REPOSITION MODE
    if slot_node == _reposition_source:
        → cancel: restore alpha, clear state
    elif not target_slot.is_occupied:
        → place: reparent hero to target slot_node, update dicts, restore alpha, clear state
    else:
        → ignore (can't swap for now)
    return

if target_slot.is_occupied:
    → NEW: enter reposition mode
       hero.modulate.a = 0.5
       _reposition_source = slot_node
       _reposition_hero = hero
       _update_hud()
    → OLD delete behavior: REMOVED
```

**ESC to cancel reposition:**
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel") and _reposition_source != null:
        _cancel_reposition()
```

**`_cancel_reposition()`:**
```gdscript
func _cancel_reposition() -> void:
    if _reposition_hero:
        _reposition_hero.modulate.a = 1.0
    _reposition_source = null
    _reposition_hero = null
    _update_hud()
```

**HUD hint:**
In `_update_hud()`, when `_reposition_source != null`, show:
`"→ Clique un slot vide pour déplacer · Echap pour annuler"`

**Reparenting (Godot 4):** `hero.reparent(target_slot_node, true)` — keeps world position, then reset `hero.position = Vector2.ZERO`.

**Acceptance:**
- ☐ Click occupied slot between waves → hero goes 50% transparent, HUD shows hint
- ☐ Click empty slot → hero moves there, alpha restored
- ☐ Click same slot again → cancel, alpha restored
- ☐ ESC key → cancel, alpha restored
- ☐ Deleting a hero is no longer possible (old behavior removed)
- ☐ Cannot reposition during a wave

---

### RTD-REP-002 — Wave Preview
**Wave:** 1 | **Files:** `scripts/wave_controller.gd`, `scripts/run_test.gd`

**WaveController additions:**
```gdscript
const ENEMY_NAMES: Dictionary = {
    "res://scenes/enemies/skeleton/skeleton_warrior.tscn": "Guerrier",
    "res://scenes/enemies/skeleton/skeleton_rogue.tscn":   "Rogue",
    "res://scenes/enemies/skeleton/skeleton_knight.tscn":  "Chevalier",
    "res://scenes/enemies/skeleton/skeleton_bonelord.tscn":"Bonelord ☠",
}

func get_next_wave_preview() -> String:
    var next_idx := _current_wave + 1
    if next_idx >= WAVES.size():
        return ""
    var parts: Array[String] = []
    for entry in WAVES[next_idx]["enemies"]:
        var name: String = ENEMY_NAMES.get(entry["path"], "?")
        parts.append("%d× %s" % [entry["count"], name])
    return "  ·  ".join(parts)
```

**run_test.gd additions:**
- Add `_wave_preview_label: Label` (dynamic, added to HUD VBoxContainer in `_ready()`)
- Style: font_size 12, color light yellow (1.0, 0.95, 0.6)
- `_update_wave_preview()` called:
  - After `wave_cleared` (show next wave info)
  - After `wave_started` (hide — set text to "")
  - On `_ready()` (show wave 1 preview immediately)
- Text format: `"Vague 2 ▸ 3× Guerrier  ·  3× Rogue"` or `""` during wave

**Acceptance:**
- ☐ On game start, label shows composition of wave 1
- ☐ After wave clears, label updates to show next wave composition
- ☐ When wave starts, label clears (empty text)
- ☐ After final wave clears, label shows "" (no next wave)

---

### RTD-REP-003 — Code Review + Requirements Validation
**Wave:** 2 | **Dependencies:** RTD-REP-001, RTD-REP-002

**Code review checklist:**
- Type hints on all new signatures
- No orphaned nodes (reparent keeps hero in tree)
- Reposition state cleared when wave starts (`_on_wave_started`)
- Reposition state cleared when placement mode activates
- `_cancel_reposition()` safe to call if hero is null

**Requirements (full):**
- ☐ Hero repositioning works as described
- ☐ Wave preview shows correct info
- ☐ All Step 1-7 features still work (placement from shop, draft, gold, waves, game over, victory)
- ☐ No console errors

## Rollback Point
Recorded before execution. Current HEAD = working Step 7 state with orientation fix applied.
