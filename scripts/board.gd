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
		pulse = maxf(0.0, pulse - delta * 0.62)
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
		draw_raid()

func draw_raid() -> void:
	var progress := 1.0 - pulse
	var target := center(Rules.HQ)
	var ship := target + Vector2(lerpf(-175.0, 190.0, progress), -132.0 + sin(progress * PI) * 32.0)
	var firing := progress > 0.28 and progress < 0.74
	if firing and impact:
		var flash := 0.65 + 0.35 * sin(progress * 85.0)
		face([ship + Vector2(-9, 4), ship + Vector2(9, 4), target + Vector2(21, 4),
			target + Vector2(-21, 4)], Color(1.0, 0.24, 0.18, flash * 0.34))
		draw_line(ship, target - Vector2(0, 15), Color(1.0, 0.52, 0.38, flash), 2, true)
		draw_arc(target, 13 + fmod(progress * 95.0, 19), 0, TAU, 32,
			Color(1.0, 0.63, 0.38, flash * 0.8), 2, true)
	if firing:
		for cell in rules.buildings:
			if rules.buildings[cell] == Rules.Building.TURRET:
				var muzzle := center(cell) + Vector2(21, -49)
				var shot := fmod(progress * 8.0 + cell.x * 0.19, 1.0)
				draw_line(muzzle.lerp(ship, shot), muzzle.lerp(ship, minf(1.0, shot + 0.12)),
					Color("#a7ffee"), 2, true)
	draw_oval(ship + Vector2(0, 4), Vector2(40, 13), Color("#292631"))
	draw_oval(ship, Vector2(40, 11), Color("#5d5966"))
	draw_oval(ship - Vector2(0, 7), Vector2(21, 10), Color("#777784"))
	draw_line(ship + Vector2(-33, 3), ship + Vector2(33, 3), Color("#aaa0a7"), 1, true)
	for i in range(5):
		var light := ship + Vector2((i - 2) * 12, 6 + (2 - absi(i - 2)))
		draw_circle(light, 2, Color("#ffad77"), true, -1, true)

func draw_oval(point: Vector2, radius: Vector2, color: Color) -> void:
	var outline := PackedVector2Array()
	for i in range(32):
		var angle := TAU * i / 32.0
		outline.append(point + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(outline, color)

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
	if Rules.is_road(cell):
		draw_road(point, cell.x == Rules.HQ.x)
		return
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
		block(point, Vector2(30, 15), 7, Color("#766e5e"))
		block(point - Vector2(0, 6), Vector2(26, 13), 20, Color("#797b62"))
		block(point - Vector2(0, 26), Vector2(20, 10), 6, Color("#a9a092"))
		face([point + Vector2(4, -13), point + Vector2(19, -20),
			point + Vector2(19, -6), point + Vector2(4, 1)], Color("#34333b"))
		draw_line(point + Vector2(5, -14), point + Vector2(18, -20), Color("#ffc87e"), 3, true)
		draw_line(point + Vector2(-9, -30), point + Vector2(-2, -49), Color("#35363e"), 4, true)
		draw_line(point + Vector2(8, -30), point + Vector2(-2, -49), Color("#35363e"), 4, true)
		var dish := PackedVector2Array()
		for i in range(24):
			var angle := TAU * i / 24.0
			dish.append(point + Vector2(-4, -51) + Vector2(cos(angle) * 17, sin(angle) * 8).rotated(0.56))
		draw_colored_polygon(dish, Color("#d4c9bc"))
		dish.append(dish[0])
		draw_polyline(dish, Color("#fff0dc"), 1.4, true)
		draw_line(point + Vector2(-4, -51), point + Vector2(-14, -64), Color("#575661"), 2, true)
		draw_circle(point + Vector2(-14, -64), 2, Color("#ffe0a0"), true, -1, true)
	elif rules.buildings.get(cell) == Rules.Building.EXTRACTOR:
		block(point, Vector2(23, 11), 10, Color("#867b70"))
		block(point + Vector2(-6, -12), Vector2(12, 6), 17, Color("#e8ae68"))
		block(point + Vector2(10, -9), Vector2(8, 4), 9, Color("#ba784f"))
		draw_line(point + Vector2(-5, -29), point + Vector2(11, -21), Color("#f9d39a"), 3, true)
		draw_line(point + Vector2(11, -21), point + Vector2(11, -10), Color("#463a46"), 2, true)
	elif rules.buildings.get(cell) == Rules.Building.TURRET:
		block(point, Vector2(27, 13), 10, Color("#9b9188"))
		block(point - Vector2(0, 10), Vector2(19, 9), 8, Color("#505461"))
		draw_line(point + Vector2(-13, -13), point + Vector2(-3, -8), Color("#50e2dc"), 2, true)
		block(point - Vector2(0, 17), Vector2(12, 6), 15, Color("#545865"))
		for offset in [-5, 5]:
			var mount := point + Vector2(offset, -29)
			var muzzle := mount + Vector2(21, -21)
			draw_line(mount, muzzle, Color("#252a37"), 7, true)
			draw_line(mount - Vector2(0, 2), muzzle - Vector2(0, 2), Color("#b4b5bd"), 2, true)
			draw_line(mount, mount.lerp(muzzle, 0.37), Color("#52dcd6"), 2, true)

func draw_road(point: Vector2, crossing: bool) -> void:
	face([road_point(point, -0.5, -0.37), road_point(point, 0.5, -0.37),
		road_point(point, 0.5, 0.37), road_point(point, -0.5, 0.37)], Color("#b3a698"))
	face([road_point(point, -0.5, -0.29), road_point(point, 0.5, -0.29),
		road_point(point, 0.5, 0.29), road_point(point, -0.5, 0.29)], Color("#43424b"))
	if crossing:
		for i in range(5):
			var across := -0.23 + i * 0.10
			draw_line(road_point(point, -0.17, across), road_point(point, 0.17, across),
				Color("#f8dfa8"), 2, true)
	else:
		draw_line(road_point(point, -0.23, 0), road_point(point, 0.23, 0),
			Color("#e7ba68"), 1.5, true)

func road_point(point: Vector2, along: float, across: float) -> Vector2:
	return point + Vector2((along - across) * HALF.x, (along + across) * HALF.y)

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
