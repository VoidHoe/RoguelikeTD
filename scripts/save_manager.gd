class_name SaveManager
extends RefCounted

## Gestion de la sauvegarde locale (user://save_data.json).
## Utilise uniquement des fonctions statiques — pas besoin d'instancier.
##
## Structure du fichier :
##   total_runs              : int        — nombre total de runs joués
##   total_wins              : int        — nombre de victoires
##   best_score              : int        — meilleur score toutes maps confondues
##   gems                    : int        — monnaie méta persistante
##   hero_upgrade_levels     : Dictionary — niveaux d'amélioration par héros/stat
##   hero_unlock_state       : Dictionary — si le héros est déverrouillé
##   challenge_progress      : Dictionary — compteurs de défis cumulatifs

const SAVE_PATH := "user://save_data.json"

static func load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_data()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return _default_data()
	var text := f.get_as_text()
	f = null  # ferme le fichier
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return _default_data()
	# Fusionne avec les valeurs par défaut pour éviter les clés manquantes
	var data := _default_data()
	data.merge(parsed, true)
	return data

static func save_data(data: Dictionary) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: impossible d'ouvrir " + SAVE_PATH)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f = null

static func _default_data() -> Dictionary:
	return {
		"total_runs": 0,
		"total_wins": 0,
		"best_score": 0,
		"gems": 0,
		"hero_upgrade_levels": {
			"Bladedancer": {"damage": 0, "range": 0, "speed": 0},
			"Pyromancer":  {"damage": 0, "range": 0, "speed": 0},
			"Stormshard":  {"damage": 0, "range": 0, "speed": 0},
		},
		"hero_unlock_state": {
			"Bladedancer": true,
			"Pyromancer":  true,
			"Stormshard":  true,
		},
		"challenge_progress": {
			"fire_damage_lifetime":      0,
			"slashing_damage_lifetime":  0,
			"electric_damage_lifetime":  0,
			"total_kills_lifetime":      0,
		},
	}

# ---------------------------------------------------------------------------
# Gem economy
# ---------------------------------------------------------------------------

static func get_gems() -> int:
	return load_data().get("gems", 0)

static func add_gems(amount: int) -> void:
	var data := load_data()
	data["gems"] = data.get("gems", 0) + amount
	save_data(data)

## Returns true if the purchase succeeded, false if not enough gems.
static func spend_gems(amount: int) -> bool:
	var data := load_data()
	var current: int = data.get("gems", 0)
	if current < amount:
		return false
	data["gems"] = current - amount
	save_data(data)
	return true

# ---------------------------------------------------------------------------
# Hero upgrade tracking
# ---------------------------------------------------------------------------

static func get_hero_upgrade(hero_name: String, stat: String) -> int:
	var data := load_data()
	var levels: Dictionary = data.get("hero_upgrade_levels", {})
	var hero_levels: Dictionary = levels.get(hero_name, {})
	return hero_levels.get(stat, 0)

static func set_hero_upgrade(hero_name: String, stat: String, level: int) -> void:
	var data := load_data()
	if not data.has("hero_upgrade_levels"):
		data["hero_upgrade_levels"] = {}
	if not data["hero_upgrade_levels"].has(hero_name):
		data["hero_upgrade_levels"][hero_name] = {}
	data["hero_upgrade_levels"][hero_name][stat] = level
	save_data(data)

# ---------------------------------------------------------------------------
# Hero unlock state
# ---------------------------------------------------------------------------

static func set_hero_unlocked(hero_name: String, unlocked: bool) -> void:
	var data := load_data()
	if not data.has("hero_unlock_state"):
		data["hero_unlock_state"] = {}
	data["hero_unlock_state"][hero_name] = unlocked
	save_data(data)

static func is_hero_unlocked(hero_name: String) -> bool:
	var data := load_data()
	var unlock_state: Dictionary = data.get("hero_unlock_state", {})
	return unlock_state.get(hero_name, false)

# ---------------------------------------------------------------------------
# Challenge progress
# ---------------------------------------------------------------------------

## Adds delta values to the matching challenge_progress counters.
## delta example: {"fire_damage_lifetime": 120, "total_kills_lifetime": 3}
static func update_challenge_progress(delta: Dictionary) -> void:
	var data := load_data()
	if not data.has("challenge_progress"):
		data["challenge_progress"] = {}
	for key in delta:
		var current: int = data["challenge_progress"].get(key, 0)
		data["challenge_progress"][key] = current + delta[key]
	save_data(data)
