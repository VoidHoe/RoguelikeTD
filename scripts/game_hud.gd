class_name GameHUD
extends CanvasLayer

signal spawn_wave_requested

# ─── palette ─────────────────────────────────────────────────────────────────
const C_BG     := Color(0.0706, 0.0784, 0.102,  1.0)  # #12141a
const C_CARD   := Color(0.1176, 0.1294, 0.1882, 1.0)  # #1e2130
const C_BORDER := Color(0.2275, 0.2392, 0.2706, 1.0)  # #3a3d45
const C_GOLD   := Color(0.7843, 0.5922, 0.2275, 1.0)  # #c8973a
const C_TEXT   := Color(0.8471, 0.8314, 0.7843, 1.0)  # #d8d4c8
const C_DIM    := Color(0.4784, 0.4706, 0.4392, 1.0)  # #7a7870
const C_DANGER := Color(0.5412, 0.1255, 0.0627, 1.0)  # #8a2010
const C_BOSS   := Color(0.7843, 0.3765, 0.1882, 1.0)  # #c86030

const TOP_H    := 56.0
const BOTTOM_H := 48.0

# ─── internal refs ───────────────────────────────────────────────────────────
var _hp_label:       Label
var _gold_label:     Label
var _wave_label:     Label
var _relics_row:     HBoxContainer
var _spawn_btn:      Button
var _hint_bar:       PanelContainer
var _hint_label:     Label
var _preview_bar:    Panel
var _preview_row:    HBoxContainer
var _preview_box:    StyleBoxFlat
var _relic_popup:    Panel        = null
var _active_relics:  Array[Dictionary] = []

# ─── build ───────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_top_bar()
	_build_hint_bar()
	_build_preview_bar()

func _build_top_bar() -> void:
	var bar := Panel.new()
	_top_wide(bar, 0.0, TOP_H)
	bar.add_theme_stylebox_override("panel", _flat(C_BG, C_BORDER))
	add_child(bar)

	# bottom separator
	var sep := _hline(C_BORDER)
	sep.anchor_top = 1.0; sep.anchor_bottom = 1.0
	sep.offset_top = -1.0; sep.offset_bottom = 0.0
	bar.add_child(sep)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 0)
	bar.add_child(row)

	row.add_child(_gap(16))

	# ── left: HP + gold ──────────────────────────────────────────────────────
	var left := HBoxContainer.new()
	left.add_theme_constant_override("separation", 24)
	left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(left)

	_hp_label   = _lbl("♥  — / —",  C_TEXT, 15)
	_gold_label = _lbl("⬡  —",      C_GOLD, 15)
	left.add_child(_hp_label)
	left.add_child(_gold_label)

	# ── center: wave label ───────────────────────────────────────────────────
	row.add_child(_expand())
	_wave_label = _lbl("PRÊT", C_GOLD, 16)
	_wave_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_wave_label)
	row.add_child(_expand())

	# ── right: relics + spawn button ─────────────────────────────────────────
	var right := HBoxContainer.new()
	right.add_theme_constant_override("separation", 14)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(right)

	_relics_row = HBoxContainer.new()
	_relics_row.add_theme_constant_override("separation", 6)
	right.add_child(_relics_row)

	_spawn_btn = Button.new()
	_spawn_btn.text = "LANCER LA VAGUE"
	_spawn_btn.custom_minimum_size = Vector2(0, 36)
	_spawn_btn.visible = false
	_spawn_btn.pressed.connect(func() -> void: spawn_wave_requested.emit())
	right.add_child(_spawn_btn)

	row.add_child(_gap(16))

func _build_hint_bar() -> void:
	_hint_bar = PanelContainer.new()
	_top_wide(_hint_bar, TOP_H, TOP_H + 28.0)
	var sbox := _flat(Color(0.102, 0.1098, 0.1255, 0.92), C_BORDER)
	sbox.border_width_top = 0; sbox.border_width_left = 0; sbox.border_width_right = 0
	_hint_bar.add_theme_stylebox_override("panel", sbox)
	_hint_bar.visible = false
	add_child(_hint_bar)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 5)
	m.add_theme_constant_override("margin_bottom", 5)
	_hint_bar.add_child(m)

	_hint_label = _lbl("", C_DIM, 13)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.add_child(_hint_label)

func _build_preview_bar() -> void:
	_preview_bar = Panel.new()
	_preview_bar.anchor_left   = 0.0;  _preview_bar.anchor_right  = 1.0
	_preview_bar.anchor_top    = 1.0;  _preview_bar.anchor_bottom = 1.0
	_preview_bar.offset_left   = 0.0;  _preview_bar.offset_right  = 0.0
	_preview_bar.offset_top    = -BOTTOM_H; _preview_bar.offset_bottom = 0.0
	_preview_box = _flat(C_BG, C_BORDER)
	_preview_box.border_width_left   = 0
	_preview_box.border_width_right  = 0
	_preview_box.border_width_bottom = 0
	_preview_bar.add_theme_stylebox_override("panel", _preview_box)
	add_child(_preview_bar)

	var top_line := _hline(C_BORDER)
	top_line.anchor_top = 0.0; top_line.anchor_bottom = 0.0
	top_line.offset_bottom = 1.0
	_preview_bar.add_child(top_line)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 14)
	_preview_bar.add_child(row)

	row.add_child(_gap(16))
	var prefix := _lbl("PROCHAINE VAGUE  ▸", C_DIM, 11)
	prefix.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(prefix)

	_preview_row = HBoxContainer.new()
	_preview_row.add_theme_constant_override("separation", 14)
	_preview_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_preview_row)

# ─── public API ──────────────────────────────────────────────────────────────

func update_hp(current: int, max_val: int) -> void:
	if not _hp_label: return
	_hp_label.text = "♥  %d / %d" % [current, max_val]
	var danger := max_val > 0 and float(current) / float(max_val) < 0.25
	_hp_label.add_theme_color_override("font_color", C_DANGER if danger else C_TEXT)

func update_gold(amount: int) -> void:
	if _gold_label: _gold_label.text = "⬡  %d" % amount

func update_wave(current: int, total: int) -> void:
	if not _wave_label: return
	_wave_label.text = "PRÊT" if current == 0 else "VAGUE  %d / %d" % [current, total]

func update_relics(relics: Array[Dictionary]) -> void:
	if not _relics_row: return
	_active_relics = relics
	for c in _relics_row.get_children(): c.queue_free()
	for r in relics:
		var btn := Button.new()
		btn.flat = true
		btn.custom_minimum_size = Vector2(28, 28)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.tooltip_text = r.get("name", "")
		btn.pressed.connect(_on_relic_btn_pressed)
		var icon_path: String = r.get("icon", "")
		var tex: Texture2D = null
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			tex = load(icon_path) as Texture2D
		if tex:
			var img := TextureRect.new()
			img.texture = tex
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img.set_anchors_preset(Control.PRESET_FULL_RECT)
			img.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(img)
		else:
			btn.text = "◆"
			btn.add_theme_color_override("font_color", C_GOLD)
		_relics_row.add_child(btn)
	if is_instance_valid(_relic_popup):
		_relic_popup.queue_free()
		_relic_popup = null
		_open_relic_popup()

func _on_relic_btn_pressed() -> void:
	if is_instance_valid(_relic_popup):
		_relic_popup.queue_free()
		_relic_popup = null
	else:
		_open_relic_popup()

func _open_relic_popup() -> void:
	const POPUP_W := 300
	const ROW_H   := 52
	var popup_h := int(_active_relics.size()) * ROW_H + 44
	_relic_popup = Panel.new()
	_relic_popup.anchor_left   = 1.0
	_relic_popup.anchor_right  = 1.0
	_relic_popup.anchor_top    = 0.0
	_relic_popup.anchor_bottom = 0.0
	_relic_popup.offset_right  = -8.0
	_relic_popup.offset_left   = -8.0 - POPUP_W
	_relic_popup.offset_top    = TOP_H + 4.0
	_relic_popup.offset_bottom = TOP_H + 4.0 + popup_h
	_relic_popup.add_theme_stylebox_override("panel", _flat(C_CARD, C_BORDER))
	add_child(_relic_popup)

	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left",   10)
	m.add_theme_constant_override("margin_right",  10)
	m.add_theme_constant_override("margin_top",     8)
	m.add_theme_constant_override("margin_bottom",  8)
	_relic_popup.add_child(m)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	m.add_child(vbox)

	var title := _lbl("— Reliques actives —", C_GOLD, 13)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	if _active_relics.is_empty():
		var none := _lbl("Aucune relique", C_DIM, 12)
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(none)
		return

	for r in _active_relics:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var icon_path: String = r.get("icon", "")
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			var tex := load(icon_path) as Texture2D
			if tex:
				var img := TextureRect.new()
				img.texture = tex
				img.custom_minimum_size = Vector2(32, 32)
				img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				img.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				row.add_child(img)

		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
		row.add_child(col)

		col.add_child(_lbl(r.get("name", ""), C_TEXT, 13))
		var desc := _lbl(r.get("desc", ""), C_DIM, 11)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(desc)

func set_spawn_visible(val: bool) -> void:
	if _spawn_btn: _spawn_btn.visible = val

func set_spawn_disabled(val: bool) -> void:
	if _spawn_btn: _spawn_btn.disabled = val

func set_hint(text: String) -> void:
	if not _hint_bar: return
	if text.is_empty():
		_hint_bar.visible = false
	else:
		_hint_label.text = text
		_hint_bar.visible = true

func update_wave_preview(preview_text: String, is_boss: bool) -> void:
	if not _preview_row: return
	for c in _preview_row.get_children(): c.queue_free()
	_preview_box.border_color = C_BOSS if is_boss else C_BORDER
	_preview_bar.add_theme_stylebox_override("panel", _preview_box)
	if preview_text.is_empty():
		return
	for part in preview_text.split("  ·  "):
		var s := part.strip_edges()
		if not s.is_empty() and not s.ends_with("BOSS"):
			_preview_row.add_child(_lbl(s, C_BOSS if is_boss else C_TEXT, 13))
	if is_boss:
		_preview_row.add_child(_lbl("  ☠  BOSS", C_BOSS, 14))

func clear_wave_preview() -> void:
	update_wave_preview("", false)

# ─── helpers ─────────────────────────────────────────────────────────────────

func _lbl(text_: String, col: Color, size: int) -> Label:
	var l := Label.new()
	l.text = text_
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", size)
	return l

func _gap(w: int) -> Control:
	var c := Control.new(); c.custom_minimum_size = Vector2(w, 0); return c

func _expand() -> Control:
	var c := Control.new(); c.size_flags_horizontal = Control.SIZE_EXPAND_FILL; return c

func _hline(col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.anchor_left = 0.0; r.anchor_right = 1.0
	r.offset_left = 0.0; r.offset_right = 0.0
	r.color = col; r.custom_minimum_size = Vector2(0, 1)
	return r

func _top_wide(ctrl: Control, top_px: float, bottom_px: float) -> void:
	ctrl.anchor_left   = 0.0; ctrl.anchor_right  = 1.0
	ctrl.anchor_top    = 0.0; ctrl.anchor_bottom = 0.0
	ctrl.offset_left   = 0.0; ctrl.offset_right  = 0.0
	ctrl.offset_top    = top_px; ctrl.offset_bottom = bottom_px

func _flat(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(1)
	s.border_color = border
	s.set_corner_radius_all(0)
	s.set_content_margin_all(0)
	return s
