class_name WaveController
extends Node

signal wave_started(wave_number: int, total_waves: int)
signal wave_cleared(wave_number: int)
signal boss_wave_cleared(chapter_number: int)
signal all_waves_cleared
signal enemy_spawned(enemy: EnemyBase)

const ENEMY_NAMES: Dictionary = {
	"res://scenes/enemies/skeleton/skeleton_warrior.tscn": "Guerrier",
	"res://scenes/enemies/skeleton/skeleton_rogue.tscn":   "Rogue",
	"res://scenes/enemies/skeleton/skeleton_knight.tscn":  "Chevalier",
	"res://scenes/enemies/skeleton/skeleton_bonelord.tscn":"Bonelord ☠",
}

var _waypoints: Array[Vector2] = []
var _container: Node
var _current_wave: int = -1
var _spawn_queue: Array[String] = []
var _spawn_interval: float = 1.5
var _spawn_timer: float = 0.0
var _alive: int = 0
var _is_running: bool = false

# Format : { "entries": [{"path": String, "count": int}],
#             "interval": float, "is_boss": bool, "chapter": int }
var _waves: Array = []
var _total_chapters: int = 0

func setup(waypoints: Array[Vector2], container: Node) -> void:
	_waypoints = waypoints
	_container = container
	_build_waves_from_children()

func _build_waves_from_children() -> void:
	_waves = []
	var chapter_idx := 0
	for chapter_node in get_children():
		if not chapter_node is ChapterDefinition:
			continue
		chapter_idx += 1
		for wave_node in chapter_node.get_children():
			if not wave_node is WaveDefinition:
				continue
			var entries: Array = []
			for entry in wave_node.get_children():
				if entry is WaveEntry and entry.scene_path != "":
					entries.append({ "path": entry.scene_path, "count": entry.count })
			_waves.append({
				"entries":  entries,
				"interval": wave_node.spawn_interval,
				"is_boss":  wave_node.is_boss,
				"chapter":  chapter_idx,
			})
	_total_chapters = chapter_idx

func get_total_waves() -> int:
	return _waves.size()

func get_current_wave() -> int:
	return _current_wave + 1

func get_current_chapter() -> int:
	if _current_wave < 0 or _waves.is_empty():
		return 0
	return _waves[_current_wave]["chapter"]

func get_total_chapters() -> int:
	return _total_chapters

func can_start_next_wave() -> bool:
	return not _is_running and _current_wave < _waves.size() - 1

func get_next_wave_preview() -> String:
	var next_idx := _current_wave + 1
	if next_idx >= _waves.size():
		return ""
	var parts: Array[String] = []
	for entry: Dictionary in _waves[next_idx]["entries"]:
		var ename: String = ENEMY_NAMES.get(entry["path"], "?")
		parts.append("%d× %s" % [entry["count"], ename])
	var suffix := "  ☠ BOSS" if _waves[next_idx]["is_boss"] else ""
	return "  ·  ".join(parts) + suffix

func start_next_wave() -> void:
	if not can_start_next_wave():
		return
	_current_wave += 1
	var wave_def: Dictionary = _waves[_current_wave]
	_spawn_interval = wave_def["interval"]
	_spawn_queue = _build_queue(wave_def["entries"])
	_spawn_timer = 0.0
	_alive = 0
	_is_running = true
	wave_started.emit(_current_wave + 1, _waves.size())

func _build_queue(enemy_list: Array) -> Array[String]:
	var queue: Array[String] = []
	for entry in enemy_list:
		for i in entry["count"]:
			queue.append(entry["path"])
	return queue

func _process(delta: float) -> void:
	if not _is_running or _spawn_queue.is_empty():
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_next()
		_spawn_timer = _spawn_interval

func _spawn_next() -> void:
	var scene_path: String = _spawn_queue.pop_front()
	var enemy: EnemyBase = load(scene_path).instantiate()
	_container.add_child(enemy)
	enemy.setup(_waypoints)
	_alive += 1
	enemy.died.connect(_on_enemy_removed)
	enemy.reached_base.connect(_on_enemy_removed)
	enemy_spawned.emit(enemy)

func _on_enemy_removed() -> void:
	_alive -= 1
	_check_wave_clear()

func _check_wave_clear() -> void:
	if not (_spawn_queue.is_empty() and _alive <= 0):
		return
	_is_running = false
	var wave_def: Dictionary = _waves[_current_wave]
	var is_last_wave := _current_wave >= _waves.size() - 1
	if wave_def["is_boss"]:
		boss_wave_cleared.emit(wave_def["chapter"])
		# all_waves_cleared sera émis par run_test après que le joueur ait choisi son event
		if not is_last_wave:
			pass  # d'autres vagues suivent, run_test montre l'EventScreen puis continue
	else:
		wave_cleared.emit(_current_wave + 1)
		if is_last_wave:
			all_waves_cleared.emit()
