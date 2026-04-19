# Absolute-Human Board — RoguelikeTD Step 8: Chapitres + Special Events
**Status:** completed
**Session:** 2026-04-19
**Previous Board:** archive/board-step7b-2026-04-19.md

## Intake Summary
- **Project:** C:\Users\VoidHoe\Desktop\RoguelikeTD\
- **Scope:** Step 8 — Structure en chapitres + boss wave + special events post-boss
- **Engine:** Godot 4.4.1 / GDScript
- **GDD reference:** `C:\Users\VoidHoe\.claude\plans\2026-04-18-roguelike-td-design.md`

### Ce qu'on construit
**Refactor wave data (hybride nodes + resources)**
- WaveEntry nodes SUPPRIMÉS → remplacés par `Array[EnemySpawnEntry]` (Resource) directement sur chaque WaveDefinition
- ChapterDefinition node regroupe les vagues d'un chapitre dans la scène
- WaveDefinition gagne `is_boss: bool` pour marquer la dernière vague
- Résultat : 33 nodes max, données ennemis dans l'Inspecteur (accordéon)

**Boss wave**
- Dernière vague d'un chapitre marquée `is_boss = true`
- Quand elle se termine : PAS de draft inter-vague → EventScreen à la place
- WaveController émet `boss_wave_cleared(chapter_num)` à la place de `wave_cleared`

**Special Events**
- Après chaque boss : 3 events tirés aléatoirement d'un pool de 6
- Le joueur en choisit 1 (gratuit), l'effet s'applique immédiatement
- EventScreen = même pattern que DraftScreen
- 4 types d'effets pour le MVP : GOLD, RELIC, HEAL, CHAOS

### MVP scope
- 1 chapitre, 5 vagues (Wave5/Bonelord = boss), 1 event post-boss
- Contenu (plus de chapitres, plus d'events) ajouté sans toucher au code

## Project Conventions
- GDScript 4.x, snake_case, PascalCase class_name
- TDD avec GUT là où c'est pertinent ; logique UI vérifiée par checklist
- Tout l'état de run dans run_test.gd ; WaveController gère le séquencement
- Pattern scène : un .tscn par composant UI (DraftScreen, ShopPanel → EventScreen)

## Task Graph

```
RTD-CH-001 (Wave data refactor + Chapter structure)
         │
         ▼
RTD-CH-002 (Event system : EventScreen + effets)
         │
         ▼
RTD-CH-003 (Code review + Requirements validation)
```

## Wave Assignments

| Wave | Task | Status |
|---|---|---|
| 1 | RTD-CH-001 | ✅ done |
| 2 | RTD-CH-002 | ✅ done |
| 3 | RTD-CH-003 | ✅ done |

---

## Per-Task Execution Plans

### RTD-CH-001 — Wave data refactor + Chapter structure
**Wave:** 1 | **Complexity:** M

**Fichiers créés :**
- `scripts/enemy_spawn_entry.gd`

**Fichiers modifiés :**
- `scripts/wave_definition.gd`
- `scripts/wave_controller.gd`
- `scripts/run_test.gd`
- `scenes/run_test.tscn`

#### enemy_spawn_entry.gd
```gdscript
class_name EnemySpawnEntry
extends Resource

@export_file("*.tscn") var scene_path: String = ""
@export var count: int = 1
```

#### wave_definition.gd — ajouts
```gdscript
@export var entries: Array[EnemySpawnEntry] = []
@export var is_boss: bool = false
```
(garde spawn_interval existant)

#### wave_controller.gd — refactor majeur
- Lire ChapterDefinition > WaveDefinition > entries (resources)
- Détecter `wave_def.is_boss` au moment du clear
- Si is_boss → émettre `boss_wave_cleared(chapter_num)` au lieu de `wave_cleared`
- Émettre quand même `wave_cleared` pour les vagues normales

Nouveaux signaux :
```gdscript
signal boss_wave_cleared(chapter_number: int)
```

Structure interne _waves_cache :
```gdscript
# { "entries": Array[{"path": String, "count": int}],
#   "interval": float, "is_boss": bool, "chapter": int }
```

`_build_waves_from_children()` lit :
```gdscript
for chapter_node in get_children():
    if chapter_node is ChapterDefinition:
        var chapter_num := chapter_idx + 1
        for wave_node in chapter_node.get_children():
            if wave_node is WaveDefinition:
                var entries = []
                for entry in wave_node.entries:
                    entries.append({...})
                _waves.append({..., "is_boss": wave_node.is_boss, "chapter": chapter_num})
```

`_check_wave_clear()` :
```gdscript
_is_running = false
if wave_def["is_boss"]:
    boss_wave_cleared.emit(wave_def["chapter"])
else:
    wave_cleared.emit(_current_wave + 1)
if _current_wave >= _waves.size() - 1:
    all_waves_cleared.emit()
```

#### run_test.gd
- Connecter `_wave_controller.boss_wave_cleared.connect(_on_boss_wave_cleared)`
- `_on_boss_wave_cleared(chapter_num)` → `_is_wave_active = false`, `_show_event_screen()`
- Ne PAS appeler `_show_wave_draft()` depuis boss clear

#### scenes/run_test.tscn
- Ajouter `chapter_definition.gd` comme ext_resource
- Ajouter `enemy_spawn_entry.gd` comme ext_resource
- Restructurer WaveController :
  - Ajouter `Chapter1` (ChapterDefinition) sous WaveController
  - Déplacer Wave1-4 sous Chapter1 (parent → WaveController/Chapter1)
  - Wave5 : `is_boss = true`, entries = [{knight×3}, {bonelord×1}]
  - Supprimer tous les nœuds WaveEntry existants
  - Ajouter sub_resources EnemySpawnEntry inline pour chaque vague
- Ajouter `enemy_spawn_entry.gd` comme ext_resource dans le header

#### chapter_definition.gd (nouveau)
```gdscript
class_name ChapterDefinition
extends Node

@export var chapter_name: String = "Chapitre 1"
```

**Acceptance RTD-CH-001 :**
- ☐ Les vagues se déroulent normalement (même comportement qu'avant)
- ☐ Les WaveEntry nodes ont disparu du panneau Scene
- ☐ Les données ennemis sont visibles dans l'Inspecteur de chaque WaveDefinition
- ☐ Wave5 émet `boss_wave_cleared` au lieu de `wave_cleared`
- ☐ Aucune erreur console

---

### RTD-CH-002 — Event system
**Wave:** 2 | **Complexity:** S | **Dépend de :** RTD-CH-001

**Fichiers créés :**
- `scripts/event_screen.gd`
- `scenes/ui/event_screen.tscn`

**Fichiers modifiés :**
- `scripts/run_test.gd`

#### Pool d'events (dans run_test.gd)
```gdscript
const EVENT_POOL: Array[Dictionary] = [
    {"name": "Trésor de Guerre",    "desc": "Reçois 50 or immédiatement.",
     "type": "gold",  "value": 50},
    {"name": "Fontaine de Vie",     "desc": "La base regagne 2 HP.",
     "type": "heal",  "value": 2},
    {"name": "Relique Ancienne",    "desc": "Reçois une relique aléatoire du pool.",
     "type": "relic"},
    {"name": "Pacte du Chaos",      "desc": "Reçois 60 or, mais la base perd 1 HP.",
     "type": "chaos", "gold": 60, "hp_cost": 1},
    {"name": "Bénédiction du Marchand", "desc": "Prochain héros acheté coûte 20 or de moins.",
     "type": "discount", "value": 20},
    {"name": "Âme des Anciens",     "desc": "Reçois immédiatement une relique et 20 or.",
     "type": "relic_gold", "gold": 20},
]
```

#### event_screen.gd — même pattern que draft_screen.gd
```gdscript
class_name EventScreen
extends CanvasLayer

signal event_chosen(type: String, data: Dictionary)

# setup(options: Array[Dictionary], title: String, subtitle: String)
# Affiche les cartes, émet event_chosen quand l'une est choisie, queue_free()
```

#### event_screen.tscn — même structure que draft_screen.tscn
- Layer 5, overlay sombre, panel centré, HBoxContainer de cartes
- Titre différent : "Événement Spécial" en rouge/orange vif

#### run_test.gd — ajouts
```gdscript
var _shop_discount: int = 0   # réduction sur prochain achat

func _show_event_screen() -> void:
    var pool := EVENT_POOL.duplicate()
    pool.shuffle()
    var options := pool.slice(0, 3)  # 3 events aléatoires
    var screen := EventScreenScene.instantiate()
    add_child(screen)
    screen.setup(options, "⚡ Événement Spécial ⚡", "Une force mystérieuse te propose un marché")
    screen.event_chosen.connect(_on_event_chosen)

func _on_event_chosen(type: String, data: Dictionary) -> void:
    match type:
        "gold":     player_base.add_gold(data["value"])
        "heal":     player_base.heal(data["value"])
        "relic":    _active_relics.append(_pick_random_relic()); _update_relic_label()
        "chaos":    player_base.add_gold(data["gold"]); player_base.take_damage(data["hp_cost"])
        "discount": _shop_discount += data["value"]
        "relic_gold": player_base.add_gold(data["gold"]); _active_relics.append(_pick_random_relic()); _update_relic_label()
    spawn_button.visible = true
    _update_hud()
```

`_pick_random_relic()` tire du RELIC_POOL en excluant les reliques déjà actives.

`player_base.heal(amount)` → nouveau dans player_base.gd :
```gdscript
func heal(amount: int) -> void:
    current_hp = min(current_hp + amount, max_hp)
    hp_changed.emit(current_hp, max_hp)
```

`_shop_discount` appliqué dans `_on_hero_bought` :
```gdscript
func _on_hero_bought(hero_data: Dictionary) -> void:
    var actual_cost := max(0, hero_data.cost - _shop_discount)
    if player_base.spend_gold(actual_cost):
        _shop_discount = 0   # consommé une fois
        _enter_placement_mode(hero_data)
```

**Acceptance RTD-CH-002 :**
- ☐ Après Wave5 (boss) : EventScreen apparaît (pas le DraftScreen)
- ☐ 3 events aléatoires affichés parmi les 6
- ☐ Choisir "Trésor de Guerre" → or augmente
- ☐ Choisir "Fontaine de Vie" → HP base augmente (plafonné à max_hp)
- ☐ Choisir "Relique Ancienne" → relique ajoutée au label
- ☐ Choisir "Pacte du Chaos" → or +60, HP -1
- ☐ Après le choix → bouton "Lancer la vague" visible (mais plus de vague → victoire)
- ☐ Vagues normales → DraftScreen comme avant (pas d'EventScreen)

---

### RTD-CH-003 — Code Review + Requirements
**Wave:** 3 | **Complexity:** S | **Dépend de :** RTD-CH-002

- Type hints complets
- `_shop_discount` remis à 0 si une vague démarre sans achat (pas de carry-over indéfini)
- `heal()` clampé à max_hp
- `_pick_random_relic()` gère le cas pool vide (retourne une relique par défaut)
- Checklist requirements complète (étapes 1-7 toujours fonctionnelles)

## Rollback Point
HEAD = Step 7b completed (repositionnement + wave preview)
