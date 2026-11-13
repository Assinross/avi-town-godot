extends SceneTree

const Rules = preload("res://scripts/colony_rules.gd")
const Colony = preload("res://scripts/colony.gd")
const SCENE = preload("res://scenes/colony.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func click_cell(colony: Colony, cell: Vector2i) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = colony.board.get_global_transform_with_canvas() * colony.board.center(cell)
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func run() -> void:
	var colony: Colony = SCENE.instantiate()
	root.add_child(colony)
	await process_frame
	check(colony.hud.text.contains("Металл  5"), "HUD should show initial resources")
	check(colony.board.cell_at(colony.board.center(Vector2i(7, 0))) == Vector2i(7, 0), "Board coordinates should round-trip")
	click_cell(colony, Rules.HQ)
	check(colony.rules.metal == 5, "Building on HQ should be blocked")
	click_cell(colony, Vector2i(0, 0))
	check(colony.rules.extractors() == 1 and colony.rules.metal == 3, "Click should build an extractor")
	colony.turret.pressed.emit()
	click_cell(colony, Vector2i(1, 0))
	check(colony.rules.defense() == 1 and colony.rules.metal == 0, "Turret should consume starting metal")
	colony.pause_button.pressed.emit()
	click_cell(colony, Vector2i(2, 0))
	colony.raid.pressed.emit()
	check(colony.rules.wave == 0 and colony.rules.buildings.size() == 2, "Pause should block actions")
	colony.pause_button.pressed.emit()
	colony.raid.pressed.emit()
	check(colony.rules.health == 5 and colony.rules.metal == 3, "Turret should block first raid and extractor should pay")
	click_cell(colony, Vector2i(2, 0))
	colony.raid.pressed.emit()
	click_cell(colony, Vector2i(3, 0))
	colony.raid.pressed.emit()
	check(colony.rules.phase == Rules.Phase.WON and colony.rules.health == 2, "Three prepared raids should lead to victory")
	colony.restart()
	check(colony.rules.buildings.is_empty() and colony.rules.wave == 0 and colony.rules.metal == 5, "Restart should create a fresh colony")
	for day in range(3):
		colony.raid.pressed.emit()
	check(colony.rules.phase == Rules.Phase.LOST and colony.rules.health == 0, "Undefended colony should be destroyed")
	check(colony.raid.disabled, "Final state should disable the raid button")
	if failures.is_empty():
		print("PASS: scene, mouse placement, resources, pause, victory, restart, defeat")
	quit(0 if failures.is_empty() else 1)
