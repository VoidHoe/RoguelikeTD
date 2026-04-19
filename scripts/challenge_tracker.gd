# ChallengeTracker: Accumulates per-run damage and kill stats by damage type,
# then evaluates hero challenge unlock conditions at end of run.
# Create a new instance each run to reset accumulators.

class_name ChallengeTracker
extends RefCounted

# Per-run accumulators (reset each run by creating a new instance)
var damage_by_type: Dictionary = {}  # dmg_type_int -> total_damage_int
var kills_total: int = 0
var kills_by_type: Dictionary = {}   # dmg_type_int -> kill_count_int


func record_damage(amount: int, dmg_type: int) -> void:
	damage_by_type[dmg_type] = damage_by_type.get(dmg_type, 0) + amount


func record_kill(dmg_type: int) -> void:
	kills_total += 1
	kills_by_type[dmg_type] = kills_by_type.get(dmg_type, 0) + 1


func get_lifetime_delta() -> Dictionary:
	# Returns increments to add to save_data["challenge_progress"].
	# Keys match the save schema used by the challenge system.
	return {
		"fire_damage_lifetime":     damage_by_type.get(DamageTypes.Type.FEU, 0),
		"slashing_damage_lifetime": damage_by_type.get(DamageTypes.Type.TRANCHANT, 0),
		"electric_damage_lifetime": damage_by_type.get(DamageTypes.Type.ELECTRIQUE, 0),
		"total_kills_lifetime":     kills_total,
	}


func evaluate_challenges(save_data: Dictionary) -> Array[String]:
	# Returns a list of hero names whose challenge unlock condition is now met.
	# Call this AFTER applying get_lifetime_delta() to save_data["challenge_progress"].
	var progress: Dictionary = save_data.get("challenge_progress", {})
	var unlock_state: Dictionary = save_data.get("hero_unlock_state", {})
	var newly_unlocked: Array[String] = []

	# Arcanist: deal 5000 fire damage across all runs
	if not unlock_state.get("Arcanist", false):
		if progress.get("fire_damage_lifetime", 0) >= 5000:
			newly_unlocked.append("Arcanist")

	# Reaper: deal 3000 slashing damage across all runs
	if not unlock_state.get("Reaper", false):
		if progress.get("slashing_damage_lifetime", 0) >= 3000:
			newly_unlocked.append("Reaper")

	# Longshot: achieve 200 total kills across all runs
	if not unlock_state.get("Longshot", false):
		if progress.get("total_kills_lifetime", 0) >= 200:
			newly_unlocked.append("Longshot")

	return newly_unlocked
