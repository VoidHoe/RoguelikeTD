class_name DraftScreen
extends CanvasLayer

## Emitted when the player clicks "Choisir" on a card.
## type : "hero_unlock" | "relic" | "hero_upgrade"
## data : the Dictionary from HERO_POOL or RELIC_POOL
signal option_chosen(type: String, data: Dictionary)

# ─── palette ─────────────────────────────────────────────────────────────────
const C_BG     := Color(0.0706, 0.0784, 0.102,  1.0)  # #12141a
const C_CARD   := Color(0.1176, 0.1294, 0.1882, 1.0)  # #1e2130
const C_BORDER := Color(0.2275, 0.2392, 0.2706, 1.0)  # #3a3d45
const C_GOLD   := Color(0.7843, 0.5922, 0.2275, 1.0)  # #c8973a
const C_TEXT   := Color(0.8471, 0.8314, 0.7843, 1.0)  # #d8d4c8
const C_DIM    := Color(0.4784, 0.4706, 0.4392, 1.0)  # #7a7870
const C_SEP    := Color(0.2275, 0.2392, 0.2706, 0.8)

# Damage type accent colors
const TYPE_COLORS := {
	"slashing":  Color(0.251, 0.376, 0.627, 1.0),
	"fire":      Color(0.784, 0.376, 0.188, 1.0),
	"electric":  Color(0.753, 0.690, 0.125, 1.0),
	"magic":     Color(0.439, 0.251, 0.627, 1.0),
	"crushing":  Color(0.439, 0.188, 0.125, 1.0),
}

const CARD_W := 210
const CARD_H := 300
const PORTRAIT_H := 96

@onready var _title_label: Label      = $Root/Center/Panel/Margin/VBox/Title
@onready var _sub_label:   Label      = $Root/Center/Panel/Margin/VBox/Sub
@onready var _cards_box: HBoxContainer = $Root/Center/Panel/Margin/VBox/Cards

## Populate cards after add_child(). options: Array of { type, data, show_cost? }
func setup(options: Array[Dictionary], title_text: String, sub_text: String) -> void:
	_title_label.text = title_text
	_sub_label.text   = sub_text
	for opt in options:
		_cards_box.add_child(_make_card(opt))

# ─── card ─────────────────────────────────────────────────────────────────────

func _make_card(opt: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	card.add_theme_stylebox_override("panel", _card_sbox(C_BORDER))
	_wire_hover(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	card.add_child(vbox)

	# ── portrait / icon area ──────────────────────────────────────────────────
	vbox.add_child(_make_portrait_area(opt))

	# ── or terne separateur ──────────────────────────────────────────────────
	var sep_line := ColorRect.new()
	sep_line.custom_minimum_size = Vector2(0, 1)
	sep_line.color = C_GOLD
	sep_line.modulate.a = 0.5
	vbox.add_child(sep_line)

	# ── body ──────────────────────────────────────────────────────────────────
	var body_m := MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		body_m.add_theme_constant_override("margin_" + side, 10 if side in ["left","right"] else 8)
	vbox.add_child(body_m)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	body_m.add_child(body)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = opt.data.name.to_upper()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.add_child(name_lbl)

	# Subtype / class label
	var sub_lbl := Label.new()
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", C_DIM)
	match opt.type:
		"hero_unlock":
			var dt: String = opt.data.get("damage_type", "")
			sub_lbl.text = dt.to_upper() if not dt.is_empty() else "HÉROS"
			var col: Color = TYPE_COLORS.get(dt, C_DIM)
			sub_lbl.add_theme_color_override("font_color", col)
		"relic":
			sub_lbl.text = "RELIQUE"
		"hero_upgrade":
			sub_lbl.text = "AMÉLIORATION"
	body.add_child(sub_lbl)

	body.add_child(_hsep())

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = opt.data.get("desc", "")
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", C_DIM)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.add_child(desc_lbl)

	# Cost hint
	if opt.get("show_cost", false):
		var cost_lbl := Label.new()
		cost_lbl.text = "Prix boutique : %d ⬡" % opt.data.cost
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.add_theme_font_size_override("font_size", 11)
		cost_lbl.add_theme_color_override("font_color", C_GOLD)
		body.add_child(cost_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(spacer)

	body.add_child(_hsep())

	# Button
	var btn := Button.new()
	btn.text = "CHOISIR"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t: String = opt.type
	var d: Dictionary = opt.data
	btn.pressed.connect(func() -> void:
		option_chosen.emit(t, d)
		queue_free()
	)
	body.add_child(btn)

	return card

# ─── portrait / icon area ─────────────────────────────────────────────────────

func _make_portrait_area(opt: Dictionary) -> Control:
	var accent := _accent_color(opt)

	var container := Panel.new()
	container.custom_minimum_size = Vector2(0, PORTRAIT_H)

	# Background: darkened accent tint
	var sbox := StyleBoxFlat.new()
	sbox.bg_color = accent.darkened(0.75)
	sbox.set_border_width_all(0)
	sbox.set_corner_radius_all(0)
	sbox.set_content_margin_all(0)
	container.add_theme_stylebox_override("panel", sbox)

	# Try to load pixel art portrait or icon
	var img_path := ""
	match opt.type:
		"hero_unlock":
			img_path = opt.data.get("portrait", "")
		"relic":
			img_path = opt.data.get("icon", "")
		"hero_upgrade":
			img_path = opt.data.get("portrait", "")

	if img_path != "" and ResourceLoader.exists(img_path):
		var tex := load(img_path) as Texture2D
		if tex:
			var trect := TextureRect.new()
			trect.texture = tex
			trect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			trect.set_anchors_preset(Control.PRESET_FULL_RECT)
			# Pixel art: no filtering
			trect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			container.add_child(trect)
			return container

	# Fallback: badge + decorative accent bar
	var fallback := VBoxContainer.new()
	fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	fallback.add_theme_constant_override("separation", 0)
	container.add_child(fallback)

	# Top accent strip
	var strip := ColorRect.new()
	strip.custom_minimum_size = Vector2(0, 3)
	strip.color = accent
	fallback.add_child(strip)

	# Badge label centered
	var badge := Label.new()
	match opt.type:
		"hero_unlock": badge.text = "★"
		"relic":       badge.text = "◆"
		"hero_upgrade":badge.text = "↑"
	badge.add_theme_color_override("font_color", accent.lightened(0.3))
	badge.add_theme_font_size_override("font_size", 32)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fallback.add_child(badge)

	# Bottom accent strip
	var strip2 := ColorRect.new()
	strip2.custom_minimum_size = Vector2(0, 3)
	strip2.color = accent
	fallback.add_child(strip2)

	return container

# ─── hover ────────────────────────────────────────────────────────────────────

func _wire_hover(card: PanelContainer) -> void:
	card.mouse_entered.connect(func() -> void:
		card.add_theme_stylebox_override("panel", _card_sbox(C_GOLD))
	)
	card.mouse_exited.connect(func() -> void:
		card.add_theme_stylebox_override("panel", _card_sbox(C_BORDER))
	)

# ─── helpers ─────────────────────────────────────────────────────────────────

func _accent_color(opt: Dictionary) -> Color:
	match opt.type:
		"hero_unlock", "hero_upgrade":
			var dt: String = opt.data.get("damage_type", "")
			return TYPE_COLORS.get(dt, C_GOLD)
		"relic":
			return Color(0.251, 0.376, 0.627, 1.0)
	return C_GOLD

func _card_sbox(border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = C_CARD
	s.set_border_width_all(1)
	s.border_color = border
	s.set_corner_radius_all(0)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	s.set_content_margin_all(0)
	return s

func _hsep() -> ColorRect:
	var r := ColorRect.new()
	r.custom_minimum_size = Vector2(0, 1)
	r.color = C_BORDER
	return r
