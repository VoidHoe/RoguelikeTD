class_name SaveManager
extends RefCounted

## Gestion de la sauvegarde locale (user://save_data.json).
## Utilise uniquement des fonctions statiques — pas besoin d'instancier.
##
## Structure du fichier :
##   total_runs  : int   — nombre total de runs joués
##   total_wins  : int   — nombre de victoires
##   best_score  : int   — meilleur score toutes maps confondues

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
	}
