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
	for c in _relics_row.get_children(): c.queue_free()
	for r in relics:
		var dot := _lbl("◆", C_GOLD, 14)
		dot.tooltip_text = "%s\n%s" % [r.get("name", ""), r.get("desc", "")]
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_relics_row.add_child(dot)

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
