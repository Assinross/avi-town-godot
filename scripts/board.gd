extends Control

const Rules = preload("res://scripts/colony_rules.gd")
const HALF := Vector2(37, 19)
const OUTSIDE := Vector2i(-1, -1)
const SAND := [Color("#a66f54"), Color("#ad7558"), Color("#b27b5d"), Color("#a26a51")]

var rules: Rules
var hover := OUTSIDE
var selected := Rules.Building.EXTRACTOR
var pulse := 0.0
var impact := false

func origin() -> Vector2:
	return Vector2(size.x * 0.325, size.y * 0.29)

func center(cell: Vector2i) -> Vector2:
	return origin() + Vector2((cell.x - cell.y) * HALF.x, (cell.x + cell.y) * HALF.y)

func cell_at(point: Vector2) -> Vector2i:
	var p := (point - origin()) / HALF
	return Vector2i(floori((p.x + p.y) * 0.5 + 0.5), floori((p.y - p.x) * 0.5 + 0.5))

func play_raid(damage: int) -> void:
	impact = damage > 0
	pulse = 1.0
	queue_redraw()

func _process(delta: float) -> void:
	if pulse > 0.0:
		pulse = maxf(0.0, pulse - delta * 1.5)
		queue_redraw()

func _draw() -> void:
	draw_landscape()
	if rules == null:
		return
	var rear := center(Vector2i.ZERO) - Vector2(0, HALF.y)
	var east := center(Vector2i(7, 0)) + Vector2(HALF.x, 0)
	var south := center(Vector2i(7, 7)) + Vector2(0, HALF.y)
	var west := center(Vector2i(0, 7)) - Vector2(HALF.x, 0)
	var depth := Vector2(0, 25)
	face([rear + depth * 1.7, east + depth * 1.7, south + depth * 1.7, west + depth * 1.7], Color("#13131f"))
	face([west, south, south + depth, west + depth], Color("#69424a"))
	face([south, east, east + depth, south + depth], Color("#4b343f"))
	draw_line(west + depth * 0.65, south + depth * 0.65, Color("#86544f"), 2, true)
	for y in range(Rules.SIZE):
		for x in range(Rules.SIZE):
			draw_tile(Vector2i(x, y))
	for row in range(2 * Rules.SIZE - 1):
		for y in range(Rules.SIZE):
			var x := row - y
			if x >= 0 and x < Rules.SIZE:
				draw_building(Vector2i(x, y))
	if pulse > 0.0:
		var at := center(Rules.HQ) - Vector2(0, 31)
		var tint := Color("#ff927d") if impact else Color("#72f3df")
		tint.a = pulse
		draw_arc(at, 16 + 44 * (1.0 - pulse), 0, TAU, 40, tint, 2.5, true)

func draw_landscape() -> void:
	for i in range(32):
		var blend := float(i) / 31.0
		var sky := Color("#111423").lerp(Color("#34283a"), sin(blend * PI))
		draw_rect(Rect2(0, size.y * i / 32.0, size.x, size.y / 32.0 + 1), sky)
	var moon := Vector2(size.x * 0.56, size.y * 0.20)
	draw_circle(moon, 45, Color("#473442"), true, -1, true)
	draw_circle(moon, 34, Color("#805452"), true, -1, true)
	draw_circle(moon, 28, Color("#e5a983"), true, -1, true)
	for i in range(55):
		var star := Vector2(fmod(i * 97.3, size.x), fmod(i * 31.7, size.y * 0.41))
		draw_circle(star, 1.0 if i % 5 == 0 else 0.55, Color("#bba2a2"))
	draw_ridge(0.40, Color("#473644"), 1.0)
	draw_ridge(0.49, Color("#322a3b"), 1.5)
	draw_ridge(0.59, Color("#242336"), 1.2)
	for i in range(21):
		var y := size.y * 0.67 + fmod(i * 39.4, size.y * 0.24)
		var x := fmod(i * 73.1, size.x)
		draw_line(Vector2(x, y), Vector2(x + 19 + i % 6 * 8, y - 3), Color("#353043"), 1, true)

func draw_ridge(level: float, color: Color, frequency: float) -> void:
	var points := PackedVector2Array()
	for i in range(37):
		var x := size.x * i / 36.0
		var y := size.y * level + sin(i * frequency) * 15 + cos(i * 0.47) * 21
		points.append(Vector2(x, y))
	points.append(size)
	points.append(Vector2(0, size.y))
	draw_colored_polygon(points, color)

func draw_tile(cell: Vector2i) -> void:
	var point := center(cell)
	var outline := diamond(point, HALF)
	var seed_value := cell.x * 17 + cell.y * 29 + cell.x * cell.y * 3
	var color: Color = SAND[seed_value % SAND.size()]
	var active := cell == hover and rules.can_build(cell, selected)
	draw_colored_polygon(outline, color.lightened(0.22) if active else color)
	outline.append(outline[0])
	draw_polyline(outline, Color("#ffe0a6") if active else Color("#775044"), 2.0 if active else 1.0, true)
	if cell == Rules.HQ or rules.buildings.has(cell):
		return
	for i in range(4):
		var shift := Vector2((seed_value * 7 + i * 13) % 35 - 17, (seed_value + i * 11) % 13 - 6)
		var grain := color.darkened(0.15) if i % 2 else color.lightened(0.12)
		draw_line(point + shift, point + shift + Vector2(3 + i, -1), grain, 1.0, true)
	if seed_value % 5 == 0:
		face([point + Vector2(-10, 2), point + Vector2(-6, -4), point + Vector2(-1, -3),
			point + Vector2(4, 1), point + Vector2(-2, 4)], Color("#745553"))

func draw_building(cell: Vector2i) -> void:
	var point := center(cell)
	if cell == Rules.HQ:
		block(point, Vector2(27, 13), 31, Color("#8c9d9a"))
		block(point - Vector2(0, 31), Vector2(18, 9), 11, Color("#b3c7bd"))
		draw_line(point + Vector2(4, -44), point + Vector2(4, -65), Color("#d6d1b3"), 2, true)
		draw_circle(point + Vector2(4, -65), 3, Color("#ffcf87"), true, -1, true)
		for i in range(3):
			draw_line(point + Vector2(-15 + i * 7, -23 + i * 3),
				point + Vector2(-11 + i * 7, -21 + i * 3), Color("#84f2d8"), 2, true)
	elif rules.buildings.get(cell) == Rules.Building.EXTRACTOR:
		block(point, Vector2(23, 11), 10, Color("#867b70"))
		block(point + Vector2(-6, -12), Vector2(12, 6), 17, Color("#e8ae68"))
		block(point + Vector2(10, -9), Vector2(8, 4), 9, Color("#ba784f"))
		draw_line(point + Vector2(-5, -29), point + Vector2(11, -21), Color("#f9d39a"), 3, true)
		draw_line(point + Vector2(11, -21), point + Vector2(11, -10), Color("#463a46"), 2, true)
	elif rules.buildings.get(cell) == Rules.Building.TURRET:
		block(point, Vector2(24, 12), 10, Color("#747987"))
		block(point - Vector2(0, 11), Vector2(14, 7), 15, Color("#73bdb4"))
		draw_line(point + Vector2(3, -26), point + Vector2(22, -38), Color("#344c55"), 8, true)
		draw_line(point + Vector2(3, -28), point + Vector2(22, -40), Color("#a9e7d8"), 3, true)
		draw_circle(point + Vector2(-4, -25), 3, Color("#c1ffee"), true, -1, true)

func block(point: Vector2, half_size: Vector2, height: float, color: Color) -> void:
	var floor_points := diamond(point, half_size)
	var roof := diamond(point - Vector2(0, height), half_size)
	face([roof[1], roof[2], floor_points[2], floor_points[1]], color.darkened(0.50))
	face([roof[2], roof[3], floor_points[3], floor_points[2]], color.darkened(0.29))
	draw_colored_polygon(roof, color)
	draw_line(roof[3], roof[0], color.lightened(0.26), 1.2, true)
	draw_line(roof[0], roof[1], color.lightened(0.16), 1.2, true)

func diamond(point: Vector2, half_size: Vector2) -> PackedVector2Array:
	return PackedVector2Array([point - Vector2(0, half_size.y), point + Vector2(half_size.x, 0),
		point + Vector2(0, half_size.y), point - Vector2(half_size.x, 0)])

func face(points: Array[Vector2], color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)
