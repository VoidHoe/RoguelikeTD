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
| 1 | RTD-META-001, RTD-META-002, RTD-META-003 | ✅ done |
| 2 | RTD-META-004, RTD-META-005 | ✅ done |
| 3 | RTD-META-006, RTD-META-007 | ✅ done |
| 4 | RTD-META-008, RTD-META-009 | ✅ done |
| 5 | RTD-META-010 | pending |

---

## Per-Task Status

### RTD-META-001 — SaveManager expansion
**Wave:** 1 | **Status:** ✅ done
**Fichiers:** `scripts/save_manager.gd`
- get_gems / add_gems / spend_gems ✅
- get_hero_upgrade / set_hero_upgrade ✅
- update_challenge_progress ✅
- _default_data() avec toutes les nouvelles clés ✅
- data.merge(parsed, true) pour rétrocompatibilité ✅

### RTD-META-002 — ChallengeTracker
**Wave:** 1 | **Status:** ✅ done
**Fichiers créés:** `scripts/challenge_tracker.gd`
- record_damage / record_kill ✅
- get_lifetime_delta() → dictionnaire d'incréments ✅
- evaluate_challenges() → Arcanist / Reaper / Longshot ✅

### RTD-META-003 — EnemyBase DoT + Slow
**Wave:** 1 | **Status:** ✅ done
**Fichiers:** `scripts/enemy_base.gd`
- apply_dot(dps, duration, dmg_type) ✅
- apply_slow(factor, duration) + Botte de vent ×0.8 ✅
- last_dmg_type mis à jour dans take_damage() ✅
- Relic bonuses Amulette de feu +25%, Lame aiguisée +20% ✅

### RTD-META-004 — Hero upgrade effects
**Wave:** 2 | **Status:** ✅ done
**Fichiers:** `scripts/hero_base.gd`, `scripts/projectile.gd`
- _apply_permanent_upgrades() lit le save au _ready() ✅
- Bladedancer: crit L3, bleed DoT L6 ✅
- Pyromancer: burn DoT L3, AoE L6 ✅
- Stormshard: slow L3, chain L6 ✅
- L10 periodic abilities (tourbillon/déluge/tempête) ✅
- Projectile: dot_dps, aoe_radius, chain_remaining, slow_chance ✅

### RTD-META-005 — Gem economy + RunEnd
**Wave:** 2 | **Status:** ✅ done
**Fichiers:** `scripts/run_test.gd`
- _calculate_gems(is_victory) → waves×5 + 50 si victoire ✅
- SaveManager.add_gems() en fin de run ✅
- update_challenge_progress + evaluate_challenges ✅
- "💎 +X gemmes (total : Y)" affiché dans l'écran de fin ✅

### RTD-META-006 — MetaShop UI
**Wave:** 3 | **Status:** ✅ done
**Fichiers créés:** `scripts/meta_shop.gd`

#### Plan détaillé
**Scène** : CanvasLayer (layer=10) → Panel centré 900×600
- GemsLabel "💎 X gems" en haut à droite
- TabContainer : un onglet par héros (Bladedancer | Pyromancer | Stormshard)
- Par onglet : 3 lignes stat (Dégâts / Portée / Vitesse)
  - Chaque ligne : Label nom + Label "Niv. X" + Label "Coût : Yg" + Button "Acheter"
- Section Paliers : 3 cartes (L3 / L6 / L10) avec description et état (🔒 Niv.X requis / ✅ Débloqué)
- Button "Fermer" en bas
- Coût upgrade : `(level + 1) * 10` gems

**Script** :
```gdscript
class_name MetaShop
extends CanvasLayer
signal closed
func _refresh_ui() → void   # lire save, update tous labels et boutons
func _on_upgrade_pressed(hero, stat) → void  # spend_gems + set_hero_upgrade + refresh
func _on_close_pressed() → void  # emit closed + queue_free
```

**Acceptance** :
- ✅ Ouvre depuis MainMenu
- ✅ Affiche gems et niveaux corrects au démarrage
- ✅ Acheter décrémente gems et incrémente niveau
- ✅ Bouton grisé si gems insuffisants ou niveau 10
- ✅ Paliers affichés locked/unlocked selon niveau damage

### RTD-META-007 — MainMenu
**Wave:** 3 | **Status:** ✅ done
**Fichiers créés:** `scripts/main_menu.gd`, `scenes/main_menu.tscn`

#### Plan détaillé
**Scène** : Node2D → fond coloré/noir + VBoxContainer centré
- Label "☠ Roguelike TD" (grand, titre)
- Label "💎 X gems"
- Button "▶ Jouer" → `get_tree().change_scene_to_file("res://scenes/maps/run_test.tscn")`
- Button "⚗ Forge des Héros" → instancie MetaShop en enfant, connecte `closed` → `_update_gems_label`

**Script** :
```gdscript
class_name MainMenu
extends Node2D
func _ready() → void  # _update_gems_label()
func _update_gems_label() → void  # gems_label.text = "💎 %d" % SaveManager.get_gems()
func _on_play_pressed() → void  # change_scene_to_file run_test
func _on_forge_pressed() → void  # instancier MetaShop
```

**Project Settings** : changer la scène de démarrage pour `scenes/main_menu.tscn`

**Acceptance** :
- ✅ Jeu démarre sur main menu
- ✅ Gems affichés et mis à jour après fermeture Forge
- ✅ Jouer lance la run
- ✅ Forge ouvre MetaShop

### RTD-META-008 — Code Review
**Wave:** 4 | **Status:** ✅ done

**Bugs réels corrigés :**
- `enemy_base.gd:60` — DoT fractionnaire tronqué à 0 chaque frame @60fps → ajout `_dot_accum` pour accumulation correcte
- `projectile.gd:83` — chain projectile n'héritait pas `aoe_radius` → ajout `chain_proj.aoe_radius = aoe_radius`

**Faux positifs du reviewer (non corrigés) :**
- `run_test.gd:518` — `save["total_runs"]` est déjà incrémenté en mémoire avant l'affichage, pas de bug
- `meta_shop.gd:198` — `spend_gems` déjà dans un `if`, pas de bug
- Gem loss rewards — spec intentionnelle : waves×5 toujours, +50 si victoire

### RTD-META-009 — Requirements Validation
**Wave:** 4 | **Status:** ✅ done

**Spec GDD vérifiée :**
- ✅ gems = waves×5 + 50 si victoire → `run_test.gd:422`
- ✅ MetaShop coût `(level+1)*10` → `meta_shop.gd:196`
- ✅ Paliers L3/L6/L10 par héros conformes au GDD → `meta_shop.gd:MILESTONES`
- ✅ MainMenu démarre le jeu via `change_scene_to_file` → `main_menu.gd:65`
- ✅ Gems persistées via SaveManager JSON → `save_manager.gd`

### RTD-META-010 — Full Verification
**Wave:** 5 | **Status:** pending
