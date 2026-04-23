class_name MetaShop
extends CanvasLayer

signal closed

const HEROES := ["Bladedancer", "Pyromancer", "Stormshard"]
const MAX_LEVEL := 10
const MILESTONE_LEVELS := [3, 6, 10]
const MILESTONES: Dictionary = {
	"Bladedancer": ["L3 — Critique 20%", "L6 — Saignement 3DPS/3s", "L10 — Tourbillon AoE /8s"],
	"Pyromancer":  ["L3 — Brûlure 2DPS/4s", "L6 — Explosion AoE r50", "L10 — Déluge ×3 /12s"],
	"Stormshard":  ["L3 — Lenteur 50%/1.5s", "L6 — Chaîne +1 rebond", "L10 — Tempête all /15s"],
}
const HERO_ARCHETYPES := {
	"Bladedancer": "dps",
	"Pyromancer":  "dps",
	"Stormshard":  "utility"
}
const PRIMARY_STAT   := {"dps": "damage", "utility": "range"}
const SECONDARY_STAT := {"dps": "speed",  "utility": "damage"}
const ARCHETYPE_LABEL := {"dps": "DPS Pur", "utility": "Utilitaire"}
const STAT_LABELS := {"damage": "Dégâts", "range": "Portée", "speed": "Vitesse"}

var _gems_label: Label
var _upgrade_buttons: Dictionary = {}
var _cost_labels: Dictionary = {}
var _level_labels: Dictionary = {}
var _milestone_status_labels: Dictionary = {}


func _ready() -> void:
	layer = 10
	_build_ui()
	_refresh_ui()


func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -450
	panel.offset_top = -310
	panel.offset_right = 450
	panel.offset_bottom = 310
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# --- Header ---
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 36)
	vbox.add_child(header)

	var title_lbl := Label.new()
	title_lbl.text = "⚗ Forge des Héros"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)

	_gems_label = Label.new()
	_gems_label.add_theme_font_size_override("font_size", 18)
	_gems_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_gems_label)

	# --- Tabs ---
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(tabs)

	for hero: String in HEROES:
		_upgrade_buttons[hero] = null
		_cost_labels[hero] = null
		_level_labels[hero] = {}
		_milestone_status_labels[hero] = []

		var archetype: String = HERO_ARCHETYPES[hero]
		var primary: String = PRIMARY_STAT[archetype]
		var secondary: String = SECONDARY_STAT[archetype]

		var hero_vbox := VBoxContainer.new()
		hero_vbox.name = hero
		hero_vbox.add_theme_constant_override("separation", 8)
		tabs.add_child(hero_vbox)

		var arch_lbl := Label.new()
		arch_lbl.text = "Archétype : %s  ·  Priorité : %s → %s" % [
			ARCHETYPE_LABEL[archetype], STAT_LABELS[primary], STAT_LABELS[secondary]
		]
		arch_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arch_lbl.add_theme_font_size_override("font_size", 13)
		hero_vbox.add_child(arch_lbl)

		var stats_sep := Label.new()
		stats_sep.text = "— Statistiques actuelles —"
		stats_sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hero_vbox.add_child(stats_sep)

		for stat: String in [primary, secondary]:
			var row := HBoxContainer.new()
			row.custom_minimum_size = Vector2(0, 32)
			row.add_theme_constant_override("separation", 12)
			hero_vbox.add_child(row)

			var name_lbl := Label.new()
			var suffix := " (principal)" if stat == primary else " (secondaire, +1 tous les 2 niveaux)"
			name_lbl.text = STAT_LABELS[stat] + suffix
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(name_lbl)

			var level_lbl := Label.new()
			level_lbl.custom_minimum_size = Vector2(60, 0)
			level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(level_lbl)
			_level_labels[hero][stat] = level_lbl

		var btn_row := HBoxContainer.new()
		btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_row.add_theme_constant_override("separation", 16)
		hero_vbox.add_child(btn_row)

		var cost_lbl := Label.new()
		cost_lbl.custom_minimum_size = Vector2(130, 0)
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		btn_row.add_child(cost_lbl)
		_cost_labels[hero] = cost_lbl

		var upgrade_btn := Button.new()
		upgrade_btn.text = "Améliorer"
		upgrade_btn.custom_minimum_size = Vector2(110, 36)
		upgrade_btn.pressed.connect(_on_upgrade_pressed.bind(hero))
		btn_row.add_child(upgrade_btn)
		_upgrade_buttons[hero] = upgrade_btn

		var mil_sep := Label.new()
		mil_sep.text = "— Paliers (débloqués automatiquement) —"
		mil_sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hero_vbox.add_child(mil_sep)

		var mil_hbox := HBoxContainer.new()
		mil_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		mil_hbox.add_theme_constant_override("separation", 16)
		hero_vbox.add_child(mil_hbox)

		for i: int in range(3):
			var card := PanelContainer.new()
			card.custom_minimum_size = Vector2(220, 70)
			mil_hbox.add_child(card)

			var card_vbox := VBoxContainer.new()
			card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			card.add_child(card_vbox)

			var mil_text := Label.new()
			mil_text.text = MILESTONES[hero][i]
			mil_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mil_text.add_theme_font_size_override("font_size", 13)
			card_vbox.add_child(mil_text)

			var mil_status := Label.new()
			mil_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mil_status.add_theme_font_size_override("font_size", 12)
			card_vbox.add_child(mil_status)
			_milestone_status_labels[hero].append(mil_status)

	# --- Close ---
	var close_btn := Button.new()
	close_btn.text = "✕ Fermer"
	close_btn.custom_minimum_size = Vector2(0, 36)
	close_btn.pressed.connect(_on_close_pressed)
	vbox.add_child(close_btn)


func _refresh_ui() -> void:
	var data := SaveManager.load_data()
	var gems: int = data.get("gems", 0)
	_gems_label.text = "💎 %d gemmes" % gems

	for hero: String in HEROES:
		var archetype: String = HERO_ARCHETYPES[hero]
		var primary: String = PRIMARY_STAT[archetype]
		var secondary: String = SECONDARY_STAT[archetype]
		var upg: Dictionary = data.get("hero_upgrade_levels", {}).get(hero, {})
		var primary_level: int = upg.get(primary, 0)
		var secondary_level: int = upg.get(secondary, 0)
		var at_max: bool = primary_level >= MAX_LEVEL
		var cost: int = (primary_level + 1) * 10

		_level_labels[hero][primary].text   = "Niv. %d" % primary_level
		_level_labels[hero][secondary].text = "Niv. %d" % secondary_level

		if at_max:
			_cost_labels[hero].text = "MAX"
		else:
			_cost_labels[hero].text = "Coût : %d 💎" % cost

		_upgrade_buttons[hero].disabled = at_max or gems < cost

		for i: int in range(3):
			var req: int = MILESTONE_LEVELS[i]
			var lbl: Label = _milestone_status_labels[hero][i]
			if primary_level >= req:
				lbl.text = "✅ Débloqué"
				lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
			else:
				lbl.text = "🔒 Niv.%d requis" % req
				lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))


func _on_upgrade_pressed(hero: String) -> void:
	var archetype: String = HERO_ARCHETYPES[hero]
	var primary: String = PRIMARY_STAT[archetype]
	var secondary: String = SECONDARY_STAT[archetype]

	var data := SaveManager.load_data()
	var primary_level: int = data.get("hero_upgrade_levels", {}).get(hero, {}).get(primary, 0)

	if primary_level >= MAX_LEVEL:
		return

	var cost: int = (primary_level + 1) * 10
	if not SaveManager.spend_gems(cost):
		return

	var new_primary := primary_level + 1
	SaveManager.set_hero_upgrade(hero, primary, new_primary)

	# Secondary stat at half rate: increments at level 2, 4, 6, 8, 10
	if new_primary / 2 > primary_level / 2:
		SaveManager.set_hero_upgrade(hero, secondary, new_primary / 2)

	_refresh_ui()


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
