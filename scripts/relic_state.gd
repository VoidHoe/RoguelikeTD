## RelicState — Autoload singleton.
## Contient la liste des reliques actives pour la run en cours.
## Mis à jour par run_test.gd ; consulté par enemy_base.gd et hero_base.gd.
extends Node

var active_relics: Array[Dictionary] = []

## Retourne true si la relique portant ce nom est active.
func has_relic(relic_name: String) -> bool:
	for r: Dictionary in active_relics:
		if r.get("name", "") == relic_name:
			return true
	return false

## Réinitialise en début de run.
func reset() -> void:
	active_relics.clear()
