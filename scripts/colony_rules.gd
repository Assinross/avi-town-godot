extends RefCounted

enum Phase { PLAYING, PAUSED, WON, LOST }
enum Building { EXTRACTOR, TURRET }

const SIZE := 8
const HQ := Vector2i(3, 3)
const ROAD_ROW := 4
const COSTS := [2, 3]
const WAVES := [1, 3, 5]

var phase := Phase.PLAYING
var metal := 5
var health := 5
var wave := 0
var buildings: Dictionary[Vector2i, Building] = {}

static func is_road(cell: Vector2i) -> bool:
	return cell.y == ROAD_ROW and cell.x >= 0 and cell.x < SIZE

func can_build(cell: Vector2i, kind: Building) -> bool:
	return phase == Phase.PLAYING and Rect2i(0, 0, SIZE, SIZE).has_point(cell) \
		and cell != HQ and not is_road(cell) and not buildings.has(cell) and metal >= COSTS[kind]

func build(cell: Vector2i, kind: Building) -> bool:
	if not can_build(cell, kind):
		return false
	buildings[cell] = kind
	metal -= COSTS[kind]
	return true

func extractors() -> int:
	return buildings.values().count(Building.EXTRACTOR)

func defense() -> int:
	return buildings.values().count(Building.TURRET)

func end_day() -> int:
	if phase != Phase.PLAYING:
		return 0
	var damage := maxi(0, WAVES[wave] - defense())
	health = maxi(0, health - damage)
	metal += 1 + 2 * extractors()
	wave += 1
	if health == 0:
		phase = Phase.LOST
	elif wave == WAVES.size():
		phase = Phase.WON
	return damage
