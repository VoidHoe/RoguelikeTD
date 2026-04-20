class_name MainMenu
extends Node2D

var _gems_label: Label
var _canvas: CanvasLayer

func _ready() -> void:
	_build_ui()
	_update_gems_label()


func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	add_child(_canvas)

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	vbox.custom_minimum_size = Vector2(320, 0)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "☠ Roguelike TD"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_gems_label = Label.new()
	_gems_label.add_theme_font_size_override("font_size", 20)
	_gems_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_gems_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer)

	var play_btn := Button.new()
	play_btn.text = "▶  Jouer"
	play_btn.custom_minimum_size = Vector2(240, 54)
	play_btn.add_theme_font_size_override("font_size", 22)
	play_btn.pressed.connect(_on_play_pressed)
	vbox.add_child(play_btn)

	var forge_btn := Button.new()
	forge_btn.text = "⚗  Forge des Héros"
	forge_btn.custom_minimum_size = Vector2(240, 54)
	forge_btn.add_theme_font_size_override("font_size", 20)
	forge_btn.pressed.connect(_on_forge_pressed)
	vbox.add_child(forge_btn)


func _update_gems_label() -> void:
	if _gems_label:
		_gems_label.text = "💎 %d gemmes" % SaveManager.get_gems()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/maps/run_test.tscn")


func _on_forge_pressed() -> void:
	var shop := MetaShop.new()
	add_child(shop)
	shop.closed.connect(_update_gems_label)
