extends Control

const Rules = preload("res://scripts/colony_rules.gd")
const HALF := Vector2(30, 15)
const OUTSIDE := Vector2i(-1, -1)

var rules: Rules
var hover := OUTSIDE
var selected := Rules.Building.EXTRACTOR

func origin() -> Vector2:
	return Vector2(size.x * 0.36, size.y * 0.33)

func center(cell: Vector2i) -> Vector2:
	return origin() + Vector2((cell.x - cell.y) * HALF.x, (cell.x + cell.y) * HALF.y)

func cell_at(point: Vector2) -> Vector2i:
	var p := (point - origin()) / HALF
	return Vector2i(floori((p.x + p.y) * 0.5 + 0.5), floori((p.y - p.x) * 0.5 + 0.5))

func _draw() -> void:
	if rules == null:
		return
	for y in range(Rules.SIZE):
		for x in range(Rules.SIZE):
			var cell := Vector2i(x, y)
			var point := center(cell)
			var tile := PackedVector2Array([point - Vector2(0, HALF.y), point + Vector2(HALF.x, 0),
				point + Vector2(0, HALF.y), point - Vector2(HALF.x, 0), point - Vector2(0, HALF.y)])
			var color := Color("#786143") if (x + y) % 2 == 0 else Color("#695439")
			if cell == hover and rules.can_build(cell, selected):
				color = Color("#9d905d")
			draw_colored_polygon(tile.slice(0, 4), color)
			draw_polyline(tile, Color("#342d26"), 1.0, true)
	for y in range(Rules.SIZE):
		for x in range(Rules.SIZE):
			var cell := Vector2i(x, y)
			var point := center(cell)
			if cell == Rules.HQ:
				draw_structure(point, Color("#bbd9ce"), "Ш", 28.0)
			elif rules.buildings.has(cell):
				var turret := rules.buildings[cell] == Rules.Building.TURRET
				draw_structure(point, Color("#7cdbd8") if turret else Color("#ffc47a"),
					"П" if turret else "Д", 22.0 if turret else 16.0)

func draw_structure(point: Vector2, color: Color, glyph: String, height: float) -> void:
	var top := point - Vector2(0, height)
	var roof := PackedVector2Array([top + Vector2(0, -9), top + Vector2(18, 0),
		top + Vector2(0, 9), top + Vector2(-18, 0)])
	draw_colored_polygon(PackedVector2Array([roof[1], roof[2], point + Vector2(0, 9),
		point + Vector2(18, 0)]), color.darkened(0.47))
	draw_colored_polygon(PackedVector2Array([roof[2], roof[3], point + Vector2(-18, 0),
		point + Vector2(0, 9)]), color.darkened(0.27))
	draw_colored_polygon(roof, color)
	draw_string(ThemeDB.fallback_font, top + Vector2(-5, 5), glyph, HORIZONTAL_ALIGNMENT_LEFT,
		-1, 14, Color("#142320"))
