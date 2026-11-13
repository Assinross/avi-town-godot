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
	add_label(self, "AVI TOWN", 44, "#f9e7d1").position = Vector2(35, 26)
	add_label(self, "Первая колония", 19, "#e7ad86").position = Vector2(39, 79)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	panel.offset_left = -342
	panel.offset_right = -26
	panel.offset_top = -266
	panel.offset_bottom = 266
	var background := surface("#1c2232", "#4d4659")
	background.set_content_margin_all(19)
	background.shadow_color = Color("#0a0d19a0")
	background.shadow_size = 12
	background.shadow_offset = Vector2(0, 6)
	panel.add_theme_stylebox_override("panel", background)
	add_child(panel)

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 8)
	panel.add_child(menu)
	add_label(menu, "Оборона поселения", 25, "#f9e7d1")
	add_label(menu, "Переживи три налёта НЛО", 16, "#b9b9cd")
	hud = add_label(menu, "", 18, "#efe2cd")
	hud.add_theme_stylebox_override("normal", surface("#141a27", "#363e52"))
	hud.custom_minimum_size.y = 104
	hud.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	extractor = add_button(menu, "", func(): select(Rules.Building.EXTRACTOR))
	turret = add_button(menu, "", func(): select(Rules.Building.TURRET))
	add_label(menu, "Добытчик даёт +2 металла за день.\nПВО поглощает 1 урон за налёт.", 15, "#b9b9cd")
	raid = add_button(menu, "Завершить день  ·  Enter", end_day)
	button_colors(raid, "#ebb985", "#f6cea1", "#231b29")
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	menu.add_child(actions)
	pause_button = add_button(actions, "Пауза", toggle_pause)
	add_button(actions, "Новая партия", restart)
	status = add_label(menu, "", 16, "#aee8d7")
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 48
	add_label(self, "ЛКМ — строить    •    1 / 2 — выбор постройки    •    Esc — пауза", 16, "#cec4d1").position = Vector2(39, 580)
	restart()

func add_label(parent: Node, caption: String, font_size: int, color: String) -> Label:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(color))
	parent.add_child(label)
	return label

func add_button(parent: Node, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 40
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	button_colors(button, "#2c3548", "#424e67", "#f3e9dd")
	button.add_theme_stylebox_override("disabled", surface("#272b39", "#373b4c"))
	button.add_theme_color_override("font_disabled_color", Color("#a6a8b7"))
	var focus := surface("#2c3548", "#aee8d7")
	focus.draw_center = false
	button.add_theme_stylebox_override("focus", focus)
	parent.add_child(button)
	return button

func surface(fill: String, border: String) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(fill)
	box.border_color = Color(border)
	box.set_border_width_all(1)
	box.set_corner_radius_all(9)
	box.set_content_margin_all(8)
	return box

func button_colors(button: Button, fill: String, hover_color: String, ink: String) -> void:
	button.add_theme_stylebox_override("normal", surface(fill, hover_color))
	button.add_theme_stylebox_override("hover", surface(hover_color, hover_color))
	button.add_theme_stylebox_override("pressed", surface(fill, ink))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color(ink))

func restart() -> void:
	rules = Rules.new()
	board.rules = rules
	board.pulse = 0.0
	board.hover = Board.OUTSIDE
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
	board.play_raid(damage)
	match rules.phase:
		Rules.Phase.WON:
			status.text = "Победа! Колония пережила три налёта."
		Rules.Phase.LOST:
			status.text = "Поражение. Штаб разрушен."
		_:
			status.text = "Налёт отражён. Штаб не получил урона." if damage == 0 else "Налёт нанёс штабу %d урона." % damage
	refresh()

func refresh() -> void:
	var strength := "—" if rules.wave == Rules.WAVES.size() else str(Rules.WAVES[rules.wave])
	hud.text = "Металл  %d    Штаб  %d / 5\nНалёты  %d / 3    Сила  %s\nЗащита  %d    Доход  +%d\nПрогноз урона штабу  %s" % [
		rules.metal, rules.health, rules.wave, strength, rules.defense(), 1 + 2 * rules.extractors(),
		"—" if strength == "—" else str(rules.predicted_damage())]
	var playing := rules.phase == Rules.Phase.PLAYING
	extractor.disabled = not playing
	turret.disabled = not playing
	extractor.text = ("▶ " if selected == Rules.Building.EXTRACTOR else "") + "1   Добытчик · 2 металла"
	turret.text = ("▶ " if selected == Rules.Building.TURRET else "") + "2   ПВО · 3 металла"
	raid.disabled = not playing
	pause_button.disabled = not (playing or rules.phase == Rules.Phase.PAUSED)
	pause_button.text = "Продолжить" if rules.phase == Rules.Phase.PAUSED else "Пауза"
	button_colors(extractor, "#694635" if selected == Rules.Building.EXTRACTOR else "#302a34",
		"#805841", "#ffe4c4")
	button_colors(turret, "#28534f" if selected == Rules.Building.TURRET else "#26343e",
		"#37635e", "#caf9ea")
	status.add_theme_color_override("font_color",
		Color("#ffac98") if rules.phase == Rules.Phase.LOST else Color("#aee8d7"))
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
		elif Rules.is_road(cell):
			status.text = "Эта клетка занята дорогой."
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
