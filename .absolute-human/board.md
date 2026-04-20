# Absolute-Human Board — RoguelikeTD Step 10: Race Orc
**Status:** ✅ DONE
**Session:** 2026-04-20
**Previous Board:** archive/board-step9-2026-04-20.md

## Intake Summary
- **Project:** E:\TDV2\RoguelikeTD\
- **Scope:** Step 10 — Race ennemie Orc : sprites PixelLab MCP + 4 scènes Godot + intégration vagues
- **Engine:** Godot 4.4.1, GDScript
- **GDD:** E:\TDV2\2026-04-18-roguelike-td-design.md

### Ce qu'on construit
- **PixelLab MCP** — configuré via `.mcp.json` ✅
- **4 types d'unités Orc** — sprites générés par PixelLab (walk 4 directions, 8 frames) ✅
- **4 scènes `.tscn`** — dans `scenes/enemies/orc/` ✅
- **Intégration** — wave_controller.gd + map1_normal.tscn ✅

### Stats Orc (GDD-aligned)
| Unité | HP | Armure | Vitesse | Gold | Élite | weaknesses | resistances |
|---|---|---|---|---|---|---|---|
| Orc Warrior | 80 | 0.15 | 28 | 12 | non | 12 | 3 |
| Worg | 45 | 0.05 | 58 | 10 | non | 4 | 3 |
| Orc Berserker | 220 | 0.15 | 32 | 30 | oui | 12 | 3 |
| Warchief | 650 | 0.20 | 16 | 90 | oui | 12 | 3 |

## Rollback Point
`6fb1dc1` Merge pull request #2 (état stable avant Step 10)

## Wave Assignments — TOUTES COMPLÉTÉES

| Wave | Tasks | Status |
|---|---|---|
| 1 | RTD-ORC-001 | ✅ done |
| 2 | RTD-ORC-002, 003, 004, 005 | ✅ done |
| 3 | RTD-ORC-006, 007, 008, 009 | ✅ done |
| 4 | RTD-ORC-010 | ✅ done |
| 5 | RTD-ORC-011, RTD-ORC-012 | ✅ done |
| 6 | RTD-ORC-013 | ✅ done — 43/43 checks |

---

## Per-Task Status

### RTD-ORC-001 — Configurer PixelLab MCP ✅
- `.mcp.json` + `.gitignore` mis à jour

### RTD-ORC-002 — Orc Warrior sprites ✅
- 32 frames dans `assets/characters/enemies/orc/orc_warrior_iso/`

### RTD-ORC-003 — Worg sprites ✅
- 32 frames dans `assets/characters/enemies/orc/worg_iso/`
- Mapping cardinal→diagonal : north→NE, east→SE, south→SW, west→NW

### RTD-ORC-004 — Orc Berserker sprites ✅
- 32 frames dans `assets/characters/enemies/orc/orc_berserker_iso/`

### RTD-ORC-005 — Warchief sprites ✅
- 32 frames dans `assets/characters/enemies/orc/orc_warchief_iso/`

### RTD-ORC-006 — orc_warrior.tscn ✅
- HP=80, armor=0.15, speed=28, gold=12, weaknesses=12, resistances=3

### RTD-ORC-007 — worg.tscn ✅
- HP=45, armor=0.05, speed=58, gold=10, weaknesses=4, resistances=3

### RTD-ORC-008 — orc_berserker.tscn ✅
- HP=220, armor=0.15, speed=32, gold=30, is_elite=true, weaknesses=12, resistances=3

### RTD-ORC-009 — orc_warchief.tscn ✅
- HP=650, armor=0.20, speed=16, gold=90, is_elite=true, weaknesses=12, resistances=3

### RTD-ORC-010 — Intégration ✅
- `wave_controller.gd` : 4 entrées ENEMY_NAMES ajoutées
- `map1_normal.tscn` : Wave3 +1 OrcWarrior, Wave4 +2 OrcWarrior +2 Worg, Wave5_Boss +1 Berserker +1 Warchief

### RTD-ORC-011 — Code Review ✅
- Toutes les scènes conformes au modèle skeleton
- Stats cohérentes avec le GDD
- Chemins de textures corrects

### RTD-ORC-012 — Requirements Validation ✅
- 43/43 checks automatisés : 0 failures

### RTD-ORC-013 — Full Verification ✅
- 128/128 sprites PNG présents
- 4 scènes .tscn valides
- Intégration vagues correcte
- wave_controller ENEMY_NAMES complet
