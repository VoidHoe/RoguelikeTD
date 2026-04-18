class_name IsometricMap
extends Node2D

const TILE_SIZE := Vector2(64, 32)
const GRID_COLS := 10
const GRID_ROWS := 6

enum TileType { GROUND, PATH, SLOT, BASE }

const PATH_WAYPOINTS: Array[Vector2i] = [
	Vector2i(0, 2), Vector2i(3, 2), Vector2i(3, 0),
	Vector2i(7, 0), Vector2i(7, 3), Vector2i(9, 3)
]

const SLOT_POSITIONS: Array[Vector2i] = [
	Vector2i(1, 2), Vector2i(2, 2),
	Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1),
	Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2),
	Vector2i(7, 2), Vector2i(8, 2),
	Vector2i(8, 3)
]

var tile_type_map: Dictionary = {}
signal tile_clicked(grid_pos: Vector2i, tile_type: TileType)

func _ready() -> void:
	_build_type_map()
	_generate_tiles()
	_draw_path_line()

func grid_to_screen(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		(grid_pos.x - grid_pos.y) * TILE_SIZE.x / 2.0,
		(grid_pos.x + grid_pos.y) * TILE_SIZE.y / 2.0
	)

func _build_type_map() -> void:
	for i in range(len(PATH_WAYPOINTS) - 1):
		var from := PATH_WAYPOINTS[i]
		var to := PATH_WAYPOINTS[i + 1]
		for pos in _get_line_cells(from, to):
			tile_type_map[pos] = TileType.PATH
	tile_type_map[PATH_WAYPOINTS[-1]] = TileType.BASE
	for pos in SLOT_POSITIONS:
		if not tile_type_map.has(pos):
			tile_type_map[pos] = TileType.SLOT

func _get_line_cells(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var step := Vector2i(sign(to.x - from.x), sign(to.y - from.y))
	var pos := from
	while pos != to:
		cells.append(pos)
		pos += step
	cells.append(to)
	return cells

func _generate_tiles() -> void:
	for row in GRID_ROWS:
		for col in GRID_COLS:
			var grid_pos := Vector2i(col, row)
			var tile_type: TileType = tile_type_map.get(grid_pos, TileType.GROUND)
			_create_tile(grid_pos, tile_type)

func _create_tile(grid_pos: Vector2i, tile_type: TileType) -> void:
	var node := Node2D.new()
	node.position = grid_to_screen(grid_pos)
	node.z_index = grid_pos.x + grid_pos.y
	node.name = "Tile_%d_%d" % [grid_pos.x, grid_pos.y]

	var poly := Polygon2D.new()
	poly.polygon = _diamond_points()
	poly.color = _tile_color(tile_type)
	node.add_child(poly)

	var outline := Line2D.new()
	var pts := _diamond_points()
	outline.add_point(pts[0])
	outline.add_point(pts[1])
	outline.add_point(pts[2])
	outline.add_point(pts[3])
	outline.add_point(pts[0])
	outline.width = 1.0
	outline.default_color = Color(0, 0, 0, 0.3)
	node.add_child(outline)

	if tile_type == TileType.SLOT:
		var area := Area2D.new()
		area.input_pickable = true
		var col_shape := CollisionPolygon2D.new()
		col_shape.polygon = _diamond_points()
		area.add_child(col_shape)
		var captured_pos := grid_pos
		var captured_type := tile_type
		area.input_event.connect(func(_cam: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _idx: int) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				tile_clicked.emit(captured_pos, captured_type)
		)
		node.add_child(area)

	add_child(node)

func _diamond_points() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -TILE_SIZE.y / 2.0),
		Vector2(TILE_SIZE.x / 2.0, 0.0),
		Vector2(0.0, TILE_SIZE.y / 2.0),
		Vector2(-TILE_SIZE.x / 2.0, 0.0),
	])

func _tile_color(tile_type: TileType) -> Color:
	match tile_type:
		TileType.PATH: return Color(0.6, 0.5, 0.3)
		TileType.SLOT: return Color(0.25, 0.45, 0.25)
		TileType.BASE: return Color(0.5, 0.2, 0.2)
		_: return Color(0.4, 0.35, 0.3)

func _draw_path_line() -> void:
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = Color(1.0, 0.8, 0.0, 0.6)
	for wp in PATH_WAYPOINTS:
		line.add_point(grid_to_screen(wp))
	line.z_index = 1000
	add_child(line)

func get_slot_positions() -> Array[Vector2i]:
	var slots: Array[Vector2i] = []
	for pos: Vector2i in tile_type_map:
		if tile_type_map[pos] == TileType.SLOT:
			slots.append(pos)
	return slots
