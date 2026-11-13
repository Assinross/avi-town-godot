extends Control

const Rules = preload("res://scripts/colony_rules.gd")
const Board = preload("res://scripts/board.gd")

@onready var board: Board = $Board
var rules := Rules.new()
var selected := Rules.Building.EXTRACTOR
var hud: Label
var status: Label
var extractor: Button
var turret: Button
var raid: Button
var pause_button: Button

func _ready() -> void:
	resized.connect(board.queue_redraw)
	add_label(self, "AVI TOWN", 38).position = Vector2(42, 26)
	add_label(self, "ПЕРВАЯ КОЛОНИЯ", 15).position = Vector2(45, 81)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	panel.offset_left = -345
	panel.offset_right = -30
	panel.offset_top = -248
	panel.offset_bottom = 248
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#162527")
	background.set_corner_radius_all(12)
	background.content_margin_left = 20
	background.content_margin_right = 20
	background.content_margin_top = 16
	background.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", background)
	add_child(panel)
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 9)
	panel.add_child(menu)
	add_label(menu, "Оборона поселения", 24)
	add_label(menu, "Переживи три налёта НЛО.", 17)
	hud = add_label(menu, "", 18)
	extractor = add_button(menu, "1   Добытчик · 2 металла", func(): select(Rules.Building.EXTRACTOR))
	turret = add_button(menu, "2   ПВО · 3 металла", func(): select(Rules.Building.TURRET))
	add_label(menu, "Добытчик даёт +2 металла за день.\nКаждая ПВО снимает 1 урон.", 15)
	raid = add_button(menu, "Завершить день", end_day)
	pause_button = add_button(menu, "Пауза", toggle_pause)
	add_button(menu, "Новая партия", restart)
	status = add_label(menu, "", 16)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 52
	add_label(self, "ЛКМ — строить    •    1 / 2 — выбор    •    Enter — налёт    •    Esc — пауза", 17).position = Vector2(43, 580)
	restart()

func add_label(parent: Node, caption: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func add_button(parent: Node, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 34
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func restart() -> void:
	rules = Rules.new()
	board.rules = rules
	selected = Rules.Building.EXTRACTOR
	status.text = "Выбери постройку и свободную клетку."
	refresh()

func select(kind: Rules.Building) -> void:
	if rules.phase != Rules.Phase.PLAYING:
		return
	selected = kind
	status.text = "Добытчик выбран." if kind == Rules.Building.EXTRACTOR else "ПВО выбрана."
	refresh()

func toggle_pause() -> void:
	if rules.phase == Rules.Phase.PLAYING:
		rules.phase = Rules.Phase.PAUSED
		status.text = "Партия на паузе."
	elif rules.phase == Rules.Phase.PAUSED:
		rules.phase = Rules.Phase.PLAYING
		status.text = "Партия продолжена."
	refresh()

func end_day() -> void:
	if rules.phase != Rules.Phase.PLAYING:
		return
	var damage := rules.end_day()
	match rules.phase:
		Rules.Phase.WON:
			status.text = "Победа! Колония пережила три налёта."
		Rules.Phase.LOST:
			status.text = "Поражение. Штаб разрушен."
		_:
			status.text = "Налёт отражён. Штаб цел." if damage == 0 else "Налёт нанёс штабу %d урона." % damage
	refresh()

func refresh() -> void:
	var strength := "—" if rules.wave == Rules.WAVES.size() else str(Rules.WAVES[rules.wave])
	hud.text = "Металл  %d    Штаб  %d / 5\nНалёты  %d / 3    Урон  %s\nЗащита  %d    Доход  +%d" % [
		rules.metal, rules.health, rules.wave, strength, rules.defense(), 1 + 2 * rules.extractors()]
	var playing := rules.phase == Rules.Phase.PLAYING
	extractor.disabled = not playing
	turret.disabled = not playing
	extractor.text = ("▶ " if selected == Rules.Building.EXTRACTOR else "") + "1   Добытчик · 2 металла"
	turret.text = ("▶ " if selected == Rules.Building.TURRET else "") + "2   ПВО · 3 металла"
	raid.disabled = not playing
	pause_button.disabled = not (playing or rules.phase == Rules.Phase.PAUSED)
	pause_button.text = "Продолжить" if rules.phase == Rules.Phase.PAUSED else "Пауза"
	board.selected = selected
	board.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		board.hover = board.cell_at(board.get_global_transform_with_canvas().affine_inverse() * event.position)
		board.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if rules.phase != Rules.Phase.PLAYING:
			return
		var cell := board.cell_at(board.get_global_transform_with_canvas().affine_inverse() * event.position)
		if not Rect2i(0, 0, Rules.SIZE, Rules.SIZE).has_point(cell):
			return
		if rules.build(cell, selected):
			status.text = "Постройка готова."
		elif cell == Rules.HQ or rules.buildings.has(cell):
			status.text = "Клетка занята."
		else:
			status.text = "Не хватает металла."
		refresh()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: select(Rules.Building.EXTRACTOR)
			KEY_2: select(Rules.Building.TURRET)
			KEY_ENTER: end_day()
			KEY_ESCAPE: toggle_pause()
