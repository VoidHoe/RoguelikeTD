extends Node2D

@onready var iso_map: IsometricMap = $IsometricMap
@onready var hero_board: HeroBoard = $HeroBoard
@onready var hud_label: Label = $HUD/VBoxContainer/PlacedLabel
@onready var base_hp_label: Label = $HUD/VBoxContainer/BaseHPLabel
@onready var slot_markers: Node2D = $IsometricMap/SlotMarkers
@onready var player_base: PlayerBase = $PlayerBase
@onready var enemy_container: Node2D = $IsometricMap/Enemies
@onready var enemy_path: Path2D = $IsometricMap/Path2D
@onready var spawn_button: Button = $HUD/VBoxContainer/Button
@onready var _wave_controller: WaveController = $WaveController
@onready var _wave_preview_label: Label = $HUD/VBoxContainer/WavePreviewLabel
@onready var _relic_label: Label = $HUD/VBoxContainer/RelicLabel

const DraftScreenScene  := preload("res://scenes/ui/draft_screen.tscn")
const ShopPanelScene    := preload("res://scenes/ui/shop_panel.tscn")
const EventScreenScene  := preload("res://scenes/ui/event_screen.tscn")

const HERO_POOL: Array[Dictionary] = [
	{"id": "bladedancer", "name": "Bladedancer", "scene": "res://scenes/heroes/bladedancer.tscn",
	 "cost": 50, "desc": "Tranchant · DPS rapide, saignement"},
	{"id": "pyromancer",  "name": "Pyromancer",  "scene": "res://scenes/heroes/pyromancer.tscn",
	 "cost": 65, "desc": "Feu · AoE explosif, zone de brûlure"},
	{"id": "stormshard",  "name": "Stormshard",  "scene": "res://scenes/heroes/stormshard.tscn",
	 "cost": 55, "desc": "Électrique · Chaîne entre ennemis"},
]

const EVENT_POOL: Array[Dictionary] = [
	{"name": "Trésor de Guerre",        "desc": "Reçois 50 or immédiatement.",
	 "type": "gold",     "value": 50},
	{"name": "Fontaine de Vie",          "desc": "La base regagne 2 HP (jusqu'au maximum).",
	 "type": "heal",     "value": 2},
	{"name": "Relique Ancienne",         "desc": "Reçois une relique aléatoire du pool.",
	 "type": "relic"},
	{"name": "Pacte du Chaos",           "desc": "Reçois 60 or… mais la base perd 1 HP.",
	 "type": "chaos",    "gold": 60,  "hp_cost": 1},
	{"name": "Bénédiction du Marchand",  "desc": "Prochain héros acheté coûte 20 or de moins.",
	 "type": "discount", "value": 20},
	{"name": "Âme des Anciens",          "desc": "Reçois une relique ET 20 or.",
	 "type": "relic_gold", "gold": 20},
]

const RELIC_POOL: Array[Dictionary] = [
	{"name": "Amulette de feu",   "desc": "+25 % dégâts de Feu"},
	{"name": "Pierre de tonnerre","desc": "+10 % vitesse d'attaque globale"},
	{"name": "Crâne maudit",      "desc": "+15 or par Elite tué"},
	{"name": "Bouclier spectral", "desc": "La base encaisse 1 dégât de plus sans mourir"},
	{"name": "Lame aiguisée",     "desc": "+20 % dégâts Tranchant"},
	{"name": "Botte de vent",     "desc": "Les ennemis lents sont encore plus lents"},
]

# ─── state ───────────────────────────────────────────────────────────────────
var _placed_heroes: Dictionary = {}
var _slot_map: Dictionary = {}
var _waypoints: Array[Vector2] = []

var _active_relics: Array[Dictionary] = []
var _pending_placement: Dictionary = {}
# IDs of every hero already claimed (starting draft OR wave unlock) — never re-proposed
var _claimed_hero_ids: Array[String] = []

var _is_wave_active: bool = false

var _reposition_source: Node2D = null   # slot_node d'où le héros a été soulevé
var _reposition_hero: HeroBase = null   # le héros en cours de repositionnement

var _shop_discount: int = 0   # réduction appliquée au prochain achat (event Marchand)

var _shop_panel: ShopPanel = null
var _draft_screen: DraftScreen = null
var _challenge_tracker: ChallengeTracker = ChallengeTracker.new()

# ─── setup ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	for i: int in enemy_path.curve.get_point_count():
		_waypoints.append(enemy_path.curve.get_point_position(i))

	player_base.hp_changed.connect(func(_c: int, _m: int) -> void: _update_hud())
	player_base.gold_changed.connect(func(_g: int) -> void: _update_hud())
	player_base.game_over.connect(_show_game_over)

	_wave_controller.setup(_waypoints, enemy_container)
	_wave_controller.wave_started.connect(_on_wave_started)
	_wave_controller.wave_cleared.connect(_on_wave_cleared)
	_wave_controller.boss_wave_cleared.connect(_on_boss_wave_cleared)
	_wave_controller.all_waves_cleared.connect(_on_all_waves_cleared)
	_wave_controller.enemy_spawned.connect(func(enemy: EnemyBase) -> void:
		enemy.reached_base.connect(func() -> void: player_base.take_damage(1))
		enemy.died.connect(func() -> void:
			player_base.add_gold(enemy.gold_reward)
			_challenge_tracker.record_kill(enemy.last_dmg_type)
		)
		enemy.damage_taken.connect(func(amt: int, typ: int) -> void:
			_challenge_tracker.record_damage(amt, typ)
		)
	)

	var children := slot_markers.get_children()
	for slot_node: Node2D in children:
		var slot := PlacementSlot.new()
		slot.grid_position = Vector2i.ZERO
		add_child(slot)
		hero_board.register_slot(slot)
		_slot_map[slot_node] = slot
		var area := slot_node.get_node_or_null("Area2D") as Area2D
		if area:
			var captured := slot_node
			area.input_event.connect(func(_vp: Node, event: InputEvent, _idx: int) -> void:
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_on_slot_clicked(captured)
			)

	_shop_panel = ShopPanelScene.instantiate()
	add_child(_shop_panel)
	_shop_panel.hero_bought.connect(_on_hero_bought)

	spawn_button.visible = false
	_update_hud()
	_update_wave_preview()
	_show_starting_draft()

# ─── draft screen ─────────────────────────────────────────────────────────────
func _show_starting_draft() -> void:
	var pool := HERO_POOL.duplicate()
	pool.shuffle()
	var options: Array[Dictionary] = []
	for h in pool:
		options.append({"type": "hero_unlock", "data": h})

	_draft_screen = DraftScreenScene.instantiate()
	add_child(_draft_screen)
	_draft_screen.setup(options, "★  Choix de départ  ★", "Sélectionne ton premier héros — gratuit")
	_draft_screen.option_chosen.connect(_on_starting_draft_chosen)

func _show_wave_draft() -> void:
	var options := _generate_wave_draft_options()

	_draft_screen = DraftScreenScene.instantiate()
	add_child(_draft_screen)
	_draft_screen.setup(options, "Choix entre les vagues", "Choisis une option (toujours gratuit)")
	_draft_screen.option_chosen.connect(_on_wave_draft_chosen)

func _on_starting_draft_chosen(type: String, data: Dictionary) -> void:
	_draft_screen = null  # DraftScreen calls queue_free() on itself after emitting
	if type == "hero_unlock":
		_claimed_hero_ids.append(data.id)
		_shop_panel.add_hero(data)  # must be purchased from shop, not placed for free
	_update_hud()

func _on_wave_draft_chosen(type: String, data: Dictionary) -> void:
	_draft_screen = null
	match type:
		"hero_unlock":
			_claimed_hero_ids.append(data.id)
			_shop_panel.add_hero(data)
			spawn_button.visible = true
		"relic":
			_active_relics.append(data)
			_update_relic_label()
			spawn_button.visible = true
	_update_hud()

func _on_hero_bought(hero_data: Dictionary) -> void:
	var actual_cost: int = max(0, int(hero_data.cost) - _shop_discount)
	if player_base.spend_gold(actual_cost):
		_shop_discount = 0   # la remise est consommée à l'achat
		_enter_placement_mode(hero_data)

func _generate_wave_draft_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []

	var candidates := HERO_POOL.filter(func(h: Dictionary) -> bool:
		return not _claimed_hero_ids.has(h.id)
	)
	if not candidates.is_empty():
		candidates.shuffle()
		options.append({"type": "hero_unlock", "data": candidates[0], "show_cost": true})

	var relics := RELIC_POOL.duplicate()
	relics.shuffle()
	var idx := 0
	while options.size() < 3 and idx < relics.size():
		options.append({"type": "relic", "data": relics[idx]})
		idx += 1

	options.shuffle()
	return options

func _enter_placement_mode(hero_data: Dictionary) -> void:
	_pending_placement = hero_data
	_update_hud()

func _cancel_reposition() -> void:
	if _reposition_hero:
		_reposition_hero.modulate.a = 1.0
	_reposition_source = null
	_reposition_hero = null
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _reposition_source != null:
		_cancel_reposition()

# ─── slot interaction ─────────────────────────────────────────────────────────
func _on_slot_clicked(slot_node: Node2D) -> void:
	var target_slot: PlacementSlot = _slot_map.get(slot_node, null)
	if target_slot == null:
		return

	if not _pending_placement.is_empty():
		if target_slot.is_occupied:
			return
		var packed := load(_pending_placement.scene) as PackedScene
		if packed == null:
			push_error("Hero scene not found: " + _pending_placement.scene)
			_pending_placement = {}
			return
		var hero: HeroBase = packed.instantiate()
		hero.position = Vector2.ZERO
		hero.z_index = 1
		slot_node.add_child(hero)
		hero.setup(_waypoints, iso_map)
		_placed_heroes[slot_node] = hero
		hero_board.place_hero_at(target_slot, hero)
		_pending_placement = {}
		_update_hud()
		if not _is_wave_active and _draft_screen == null:
			spawn_button.visible = true
		return

	if _is_wave_active:
		return

	# ─── MODE REPOSITIONNEMENT ───────────────────────────────────────────────
	if _reposition_source != null:
		if slot_node == _reposition_source:
			_cancel_reposition()
		elif not target_slot.is_occupied:
			# Déplacer le héros vers le nouveau slot
			var src_slot: PlacementSlot = _slot_map.get(_reposition_source, null)
			_reposition_hero.reparent(slot_node, true)
			_reposition_hero.position = Vector2.ZERO
			_reposition_hero.modulate.a = 1.0
			_placed_heroes.erase(_reposition_source)
			_placed_heroes[slot_node] = _reposition_hero
			if src_slot:
				hero_board.remove_hero_at(src_slot)
			hero_board.place_hero_at(target_slot, _reposition_hero)
			_reposition_source = null
			_reposition_hero = null
			_update_hud()
		# Si slot occupé différent : ignorer (pas de swap pour l'instant)
		return

	# ─── PICK UP POUR REPOSITIONNEMENT ───────────────────────────────────────
	if target_slot.is_occupied:
		var hero := _placed_heroes.get(slot_node) as HeroBase
		if hero:
			hero.modulate.a = 0.5
			_reposition_source = slot_node
			_reposition_hero = hero
			_update_hud()

# ─── spawn button ─────────────────────────────────────────────────────────────
func _on_spawn_button_pressed() -> void:
	_wave_controller.start_next_wave()

# ─── wave events ─────────────────────────────────────────────────────────────
func _on_wave_started(_wave_number: int, _total: int) -> void:
	_cancel_reposition()
	_is_wave_active = true
	_pending_placement = {}
	spawn_button.visible = false
	_update_hud()
	_wave_preview_label.text = ""

func _on_wave_cleared(_wave_number: int) -> void:
	_is_wave_active = false
	_update_hud()
	_update_wave_preview()
	_show_wave_draft()

func _on_boss_wave_cleared(_chapter_number: int) -> void:
	_is_wave_active = false
	_update_hud()
	_update_wave_preview()
	_show_event_screen()

func _show_event_screen() -> void:
	var pool := EVENT_POOL.duplicate()
	pool.shuffle()
	var options: Array[Dictionary] = []
	for evt in pool.slice(0, 3):
		options.append(evt)
	var screen := EventScreenScene.instantiate() as EventScreen
	add_child(screen)
	screen.setup(options, "⚡  Événement Spécial  ⚡", "Une force mystérieuse te propose un marché")
	screen.event_chosen.connect(_on_event_chosen)

func _on_event_chosen(type: String, data: Dictionary) -> void:
	match type:
		"gold":
			player_base.add_gold(data["value"])
		"heal":
			player_base.heal(data["value"])
		"relic":
			var r := _pick_random_relic()
			if r:
				_active_relics.append(r)
				_update_relic_label()
		"chaos":
			player_base.add_gold(data["gold"])
			player_base.take_damage(data["hp_cost"])
		"discount":
			_shop_discount += data["value"]
		"relic_gold":
			player_base.add_gold(data["gold"])
			var r := _pick_random_relic()
			if r:
				_active_relics.append(r)
				_update_relic_label()
	if not _wave_controller.can_start_next_wave():
		_show_victory()
		return
	spawn_button.visible = true
	_update_hud()

func _pick_random_relic() -> Dictionary:
	var available := RELIC_POOL.filter(func(r: Dictionary) -> bool:
		return not _active_relics.any(func(a: Dictionary) -> bool: return a.name == r.name)
	)
	if available.is_empty():
		available = RELIC_POOL.duplicate()
	available.shuffle()
	return available[0]

func _on_all_waves_cleared() -> void:
	_show_victory()

# ─── HUD ──────────────────────────────────────────────────────────────────────
func _update_relic_label() -> void:
	if _relic_label == null:
		return
	if _active_relics.is_empty():
		_relic_label.text = ""
		return
	var parts: Array[String] = []
	for r in _active_relics:
		parts.append(r.name)
	_relic_label.text = "Reliques : " + "  ·  ".join(parts)

func _update_wave_preview() -> void:
	if _wave_preview_label == null or _wave_controller == null:
		return
	var preview := _wave_controller.get_next_wave_preview()
	if preview.is_empty():
		_wave_preview_label.text = ""
	else:
		var next_wave_num := _wave_controller.get_current_wave() + 1
		_wave_preview_label.text = "Vague %d ▸ %s" % [next_wave_num, preview]

func _update_hud() -> void:
	var total := hero_board.get_slot_count()
	var placed := hero_board.get_occupied_slots().size()
	var wave_cur := _wave_controller.get_current_wave() if _wave_controller else 0
	var wave_tot := _wave_controller.get_total_waves() if _wave_controller else 0
	var chap_cur := _wave_controller.get_current_chapter() if _wave_controller else 0
	var chap_tot := _wave_controller.get_total_chapters() if _wave_controller else 0
	var progress_text: String
	if wave_cur > 0:
		progress_text = "Ch.%d/%d · Vague %d/%d" % [chap_cur, chap_tot, wave_cur, wave_tot]
	else:
		progress_text = "Prêt"
	var placement_hint := ""
	if not _pending_placement.is_empty():
		placement_hint = "\n→ Clique un slot pour placer : " + _pending_placement.name
	elif _reposition_source != null:
		placement_hint = "\n→ Clique un slot vide pour déplacer · Echap pour annuler"
	hud_label.text = "Héros : %d / %d  |  %s  |  Or : %d%s" % [placed, total, progress_text, player_base.gold, placement_hint]
	base_hp_label.text = "Base HP : %d / %d" % [player_base.current_hp, player_base.max_hp]
	spawn_button.disabled = not _pending_placement.is_empty()
	_shop_panel.refresh(player_base.gold, _is_wave_active)

# ─── score & sauvegarde ───────────────────────────────────────────────────────
func _calculate_gems(is_victory: bool) -> int:
	return _wave_controller.get_current_wave() * 5 + (50 if is_victory else 0)

func _calculate_score(is_victory: bool) -> int:
	var waves_cleared := _wave_controller.get_current_wave()
	var score := waves_cleared * 100
	score += player_base.current_hp * 50
	score += _active_relics.size() * 200
	score += player_base.gold
	if is_victory:
		score = int(score * 2.0)   # bonus victoire ×2
	return score

# ─── end screens ──────────────────────────────────────────────────────────────
func _show_victory() -> void:
	_show_run_end(true)

func _show_game_over() -> void:
	_show_run_end(false)

func _show_run_end(is_victory: bool) -> void:
	_wave_controller.set_process(false)

	# ── Calcul du score et mise à jour de la sauvegarde ──
	var score := _calculate_score(is_victory)
	var gems_earned := _calculate_gems(is_victory)

	var save := SaveManager.load_data()
	save["total_runs"] = save.get("total_runs", 0) + 1
	if is_victory:
		save["total_wins"] = save.get("total_wins", 0) + 1
	var prev_best: int = save.get("best_score", 0)
	var is_new_record := score > prev_best
	if is_new_record:
		save["best_score"] = score
	SaveManager.save_data(save)

	# ── Gems + challenge progress ──
	SaveManager.add_gems(gems_earned)
	SaveManager.update_challenge_progress(_challenge_tracker.get_lifetime_delta())
	var save_post := SaveManager.load_data()
	var newly_unlocked := _challenge_tracker.evaluate_challenges(save_post)
	for hero_name in newly_unlocked:
		SaveManager.set_hero_unlocked(hero_name, true)
	var total_gems := SaveManager.get_gems()

	var vp := get_viewport().get_visible_rect().size

	# ── Construction de l'écran ──
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	# Fond sombre
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	canvas.add_child(overlay)

	# Titre principal (VICTOIRE / GAME OVER)
	var title_color  := Color(0.95, 0.80, 0.10) if is_victory else Color(0.85, 0.04, 0.04)
	var shadow_color := Color(0.60, 0.45, 0.00) if is_victory else Color(0.20, 0.00, 0.00)
	var title := Label.new()
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	title.text = "VICTOIRE" if is_victory else "GAME OVER"
	title.add_theme_font_size_override("font_size", 120)
	title.add_theme_color_override("font_color", title_color)
	title.add_theme_color_override("font_shadow_color", shadow_color)
	title.add_theme_constant_override("shadow_offset_x", 8)
	title.add_theme_constant_override("shadow_offset_y", 8)
	title.pivot_offset = vp / 2.0
	title.scale = Vector2(1.4, 1.4)
	title.modulate.a = 0.0
	canvas.add_child(title)

	# Panneau de résumé (positionné sous le titre)
	var record_line := "★  Nouveau record !" if is_new_record else ("Meilleur score : %d" % prev_best)
	var relic_names: Array[String] = []
	for r in _active_relics:
		relic_names.append(r.name)
	var relic_line := "  ·  ".join(relic_names) if not relic_names.is_empty() else "Aucune"
	var wave_cur := _wave_controller.get_current_wave()
	var wave_tot := _wave_controller.get_total_waves()

	var summary_lines: Array[String] = []
	summary_lines.append("Score : %d        %s" % [score, record_line])
	summary_lines.append("")
	if is_victory:
		summary_lines.append("Reliques : %s" % relic_line)
		summary_lines.append("Base HP restante : %d / %d" % [player_base.current_hp, player_base.max_hp])
		summary_lines.append("Or restant : %d" % player_base.gold)
	else:
		summary_lines.append("Vague atteinte : %d / %d" % [wave_cur, wave_tot])
	summary_lines.append("")
	summary_lines.append("Runs joués : %d    Victoires : %d" % [save["total_runs"], save["total_wins"]])
	summary_lines.append("💎  +%d gemmes  (total : %d)" % [gems_earned, total_gems])
	if not newly_unlocked.is_empty():
		summary_lines.append("🔓  Nouveau héros disponible : %s" % "  ·  ".join(newly_unlocked))

	var summary := Label.new()
	summary.position = Vector2(0.0, vp.y * 0.60)
	summary.size = Vector2(vp.x, vp.y * 0.30)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.vertical_alignment   = VERTICAL_ALIGNMENT_TOP
	summary.text = "\n".join(summary_lines)
	summary.add_theme_font_size_override("font_size", 24)
	summary.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	summary.modulate.a = 0.0
	canvas.add_child(summary)

	# Bouton Rejouer
	var btn := Button.new()
	btn.text = "↺   Rejouer"
	btn.add_theme_font_size_override("font_size", 26)
	btn.size = Vector2(200.0, 56.0)
	btn.position = Vector2(vp.x / 2.0 - 100.0, vp.y * 0.88)
	btn.modulate.a = 0.0
	canvas.add_child(btn)
	btn.pressed.connect(func() -> void: get_tree().reload_current_scene())

	# ── Animation ──
	var tween := create_tween().set_parallel(true)
	var overlay_alpha := 0.65 if is_victory else 0.78
	tween.tween_property(overlay,  "color:a",    overlay_alpha,   1.4).set_ease(Tween.EASE_IN)
	tween.tween_property(title,    "modulate:a", 1.0, 0.5).set_delay(0.7).set_ease(Tween.EASE_IN)
	tween.tween_property(title,    "scale",      Vector2(1.0, 1.0), 0.5).set_delay(0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(summary,  "modulate:a", 1.0, 0.8).set_delay(1.4).set_ease(Tween.EASE_IN)
	tween.tween_property(btn,      "modulate:a", 1.0, 0.6).set_delay(2.0).set_ease(Tween.EASE_IN)
