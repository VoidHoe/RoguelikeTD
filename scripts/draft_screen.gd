class_name DraftScreen
extends CanvasLayer

## Emitted when the player clicks "Choisir" on a card.
## type : "hero_unlock" | "relic"
## data : the Dictionary from HERO_POOL or RELIC_POOL
signal option_chosen(type: String, data: Dictionary)

@onready var _title_label: Label = $Root/Center/Panel/Margin/VBox/Title
@onready var _sub_label: Label   = $Root/Center/Panel/Margin/VBox/Sub
@onready var _cards_box: HBoxContainer = $Root/Center/Panel/Margin/VBox/Cards

## Call this after add_child() to populate the 3 cards.
## options : Array of { type, data, show_cost? }
func setup(options: Array[Dictionary], title_text: String, sub_text: String) -> void:
	_title_label.text = title_text
	_sub_label.text   = sub_text
	for opt in options:
		_cards_box.add_child(_make_card(opt))

func _make_card(opt: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 230)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Type badge
	var type_lbl := Label.new()
	match opt.type:
		"hero_unlock":
			type_lbl.text = "★  HÉROS"
			type_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		"relic":
			type_lbl.text = "◆  RELIQUE"
			type_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(type_lbl)

	var name_lbl := Label.new()
	name_lbl.text = opt.data.name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 19)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_lbl)

	vbox.add_child(HSeparator.new())

	var desc_lbl := Label.new()
	desc_lbl.text = opt.data.get("desc", "")
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_lbl)

	# Optional shop cost hint (shown on wave draft hero unlocks)
	if opt.get("show_cost", false):
		var cost_lbl := Label.new()
		cost_lbl.text = "Prix boutique : %d or" % opt.data.cost
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.add_theme_font_size_override("font_size", 11)
		cost_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.3))
		vbox.add_child(cost_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var btn := Button.new()
	btn.text = "Choisir"
	var captured_type: String = opt.type
	var captured_data: Dictionary = opt.data
	btn.pressed.connect(func() -> void:
		option_chosen.emit(captured_type, captured_data)
		queue_free()
	)
	vbox.add_child(btn)

	return card
