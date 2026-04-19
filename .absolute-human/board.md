# Absolute-Human Board — RoguelikeTD Step 9: Meta-Progression Complète
**Status:** in-progress
**Session:** 2026-04-19
**Previous Board:** archive/board-step8-2026-04-19.md

## Intake Summary
- **Project:** C:\Users\VoidHoe\Desktop\RoguelikeTD\
- **Scope:** Step 9 — Meta-progression : gems, challenges, upgrades permanents + abilities de palier, meta shop, main menu
- **Engine:** Godot 4.4.1, GDScript
- **GDD:** C:\Users\VoidHoe\.claude\plans\2026-04-18-roguelike-td-design.md

### Ce qu'on construit
- **SaveManager étendu** — gems, hero_upgrade_levels, hero_unlock_state, challenge_progress
- **ChallengeTracker** — suivi in-run de damage/kills par type → évalue challenges en fin de run
- **EnemyBase DoT + Slow** — apply_dot() et apply_slow() pour les abilities de palier
- **Hero upgrade effects** — stats + abilities de palier par héros (L3/L6/L10)
- **Gem economy** — waves×5 + 50 si victoire
- **MetaShop UI** — CanvasLayer, tabs par héros, acheter upgrades/débloquer paliers
- **MainMenu** — scène d'accueil avec Jouer + Forge + gems affichés

### Hero milestone abilities (approuvées)
- Bladedancer L3: crit 20% | L6: bleed DoT 3dps 3s | L10: tourbillon AoE toutes 8s
- Pyromancer L3: burn DoT 2dps 4s | L6: explosion AoE radius 50px | L10: déluge 3 projectiles toutes 12s
- Stormshard L3: slow 50% 1.5s (25% chance) | L6: chain +1 rebond | L10: tempête all-in-range toutes 15s

## Project Conventions
- GDScript 4.x, snake_case, PascalCase class_name
- SaveManager = static methods, RefCounted, JSON local
- Pattern UI : CanvasLayer instancié dynamiquement
- hero_base.gd script partagé — abilities via match hero_name (pas de subclass)

## Rollback Point
`8e8232d` feat: Steps 2-9 — enemy movement, waves, chapters, draft, events, score, meta-progression

## Task Graph

```
RTD-META-001        RTD-META-002         RTD-META-003
(SaveManager)   (ChallengeTracker)    (EnemyBase DoT/Slow)
      │                 │                      │
      └────────┬─────────┘                     │
               ▼                               ▼
    RTD-META-004 (HeroUpgradeEffects) ←────────┘
    RTD-META-005 (GemEconomy + RunEnd)
               │
       ┌───────┴───────┐
       ▼               ▼
RTD-META-006      RTD-META-007
(MetaShop UI)     (MainMenu)
       │               │
       └───────┬────────┘
               ▼
    RTD-META-008 (Code Review)
    RTD-META-009 (Requirements)
               ▼
    RTD-META-010 (Full Verification)
```

## Wave Assignments

| Wave | Tasks | Status |
|---|---|---|
| 1 | RTD-META-001, RTD-META-002, RTD-META-003 | 🔄 in-progress |
| 2 | RTD-META-004, RTD-META-005 | pending |
| 3 | RTD-META-006, RTD-META-007 | pending |
| 4 | RTD-META-008, RTD-META-009 | pending |
| 5 | RTD-META-010 | pending |

---

## Per-Task Status

### RTD-META-001 — SaveManager expansion
**Wave:** 1 | **Status:** 🔄 in-progress
**Fichiers:** `scripts/save_manager.gd`

### RTD-META-002 — ChallengeTracker
**Wave:** 1 | **Status:** 🔄 in-progress
**Fichiers créés:** `scripts/challenge_tracker.gd`

### RTD-META-003 — EnemyBase DoT + Slow
**Wave:** 1 | **Status:** 🔄 in-progress
**Fichiers:** `scripts/enemy_base.gd`

### RTD-META-004 — Hero upgrade effects
**Wave:** 2 | **Status:** pending
**Fichiers:** `scripts/hero_base.gd`, `scripts/projectile.gd`

### RTD-META-005 — Gem economy + RunEnd
**Wave:** 2 | **Status:** pending
**Fichiers:** `scripts/run_test.gd`

### RTD-META-006 — MetaShop UI
**Wave:** 3 | **Status:** pending
**Fichiers créés:** `scripts/meta_shop.gd`, `scenes/ui/meta_shop.tscn`

### RTD-META-007 — MainMenu
**Wave:** 3 | **Status:** pending
**Fichiers créés:** `scripts/main_menu.gd`, `scenes/main_menu.tscn`

### RTD-META-008 — Code Review
**Wave:** 4 | **Status:** pending

### RTD-META-009 — Requirements Validation
**Wave:** 4 | **Status:** pending

### RTD-META-010 — Full Verification
**Wave:** 5 | **Status:** pending
