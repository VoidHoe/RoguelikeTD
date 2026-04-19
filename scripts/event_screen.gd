class_name EventScreen
extends CanvasLayer

## Emitted when the player clicks "Choisir" on an event card.
## type : the "type" field from the option Dictionary
## data : the full option Dictionary
signal event_chosen(type: String, data: Dictionary)

@onready var _title_label: Label = $Root/Center/Panel/Margin/VBox/Title
@onready var _sub_label: Label   = $Root/Center/Panel/Margin/VBox/Sub
@onready var _cards_box: HBoxContainer = $Root/Center/Panel/Margin/VBox/Cards

## Call this after add_child() to populate the event cards.
## options : Array of { name: String, desc: String, type: String, ...extra fields }
func setup(options: Array[Dictionary], title_text: String, sub_text: String) -> void:
	_title_label.text = title_text
	_sub_label.text   = sub_text
	for opt in options:
		_cards_box.add_child(_make_card(opt))

func _make_card(opt: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 230)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = opt.get("name", "")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_lbl)

	vbox.add_child(HSeparator.new())

	var desc_lbl := Label.new()
	desc_lbl.text = opt.get("desc", "")
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var btn := Button.new()
	btn.text = "Choisir"
	var captured_data: Dictionary = opt
	btn.pressed.connect(func() -> void:
		event_chosen.emit(captured_data["type"], captured_data)
		queue_free()
	)
	vbox.add_child(btn)

	return card
