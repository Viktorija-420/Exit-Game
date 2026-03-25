extends CanvasLayer

# -------------------- NODES --------------------

@onready var pause_menu: Control = get_node_or_null("PauseMenu") as Control
@onready var main_menu_button: Button = get_node_or_null("PauseMenu/Panel/MainMenuButton") as Button
@onready var settings_button: Button = get_node_or_null("PauseMenu/Panel/SettingButton") as Button
@onready var rules_button: Button = get_node_or_null("PauseMenu/Panel/RulesButton") as Button

@onready var pause_button: Button = get_node_or_null("PauseButton") as Button
@onready var game_over_label: Label = get_node_or_null("GameOverLabel") as Label
@onready var fade: ColorRect = get_node_or_null("Fade") as ColorRect
@onready var charge_bar: Range = get_node_or_null("ChargeBar") as Range

# -------------------- EXPORTS --------------------

@export var fade_in_on_start: bool = true
@export var fade_in_time: float = 0.6

@export var charge_fill_speed: float = 3.5
@export var charge_drain_speed: float = 5.0

# -------------------- HEARTS --------------------

var hearts: Array[TextureRect] = []
var full_textures: Array[Texture2D] = []
var empty_textures: Array[Texture2D] = []

# -------------------- CHARGE --------------------

var _charge_target: float = 0.0
var _charge_active: bool = false

# -------------------- TWEEN --------------------

var _tween: Tween

# -------------------- Collect --------------------

@onready var collect_ui: CanvasItem = get_node_or_null("Collect")

func _ready() -> void:
	# UI must keep working when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# -------------------- Pause Menu Setup --------------------
	if pause_menu:
		pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		pause_menu.visible = false

	# Pause button
	if pause_button:
		pause_button.process_mode = Node.PROCESS_MODE_ALWAYS
		pause_button.focus_mode = Control.FOCUS_NONE
		_safe_connect_pressed(pause_button, _on_pause_pressed)
		_update_pause_button_text()

	# Menu buttons
	_safe_connect_pressed(main_menu_button, _on_main_menu_pressed)
	_safe_connect_pressed(settings_button, _on_settings_pressed)
	_safe_connect_pressed(rules_button, _on_rules_pressed)

	# -------------------- Game Over Label --------------------
	if game_over_label:
		game_over_label.visible = false
		game_over_label.process_mode = Node.PROCESS_MODE_ALWAYS

	# -------------------- Fade Setup (IMPORTANT FIX) --------------------
	if fade:
		fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		fade.z_index = 999

		# ✅ CRITICAL: do NOT let Fade block button clicks (even when transparent)
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fade.process_mode = Node.PROCESS_MODE_ALWAYS

		fade.visible = true
		fade.modulate.a = 1.0

		if fade_in_on_start:
			fade_in(fade_in_time)
		else:
			fade.visible = false

	# -------------------- Charge Bar Setup --------------------
	if charge_bar:
		charge_bar.process_mode = Node.PROCESS_MODE_ALWAYS
		charge_bar.min_value = 0.0
		charge_bar.max_value = 1.0
		charge_bar.value = 0.0
		charge_bar.visible = false

	# -------------------- Hearts Setup --------------------
	hearts = [
		_must_get_heart("HeartsHolder/Hearts/heart1"),
		_must_get_heart("HeartsHolder/Hearts/heart2"),
		_must_get_heart("HeartsHolder/Hearts/heart3"),
		_must_get_heart("HeartsHolder/Hearts/heart4"),
		_must_get_heart("HeartsHolder/Hearts/heart5"),
		_must_get_heart("HeartsHolder/Hearts/heart6")
	]

	var empty_hearts: Array[TextureRect] = [
		_must_get_heart("HeartsHolder/HeartsEmpty/heart1"),
		_must_get_heart("HeartsHolder/HeartsEmpty/heart2"),
		_must_get_heart("HeartsHolder/HeartsEmpty/heart3"),
		_must_get_heart("HeartsHolder/HeartsEmpty/heart4"),
		_must_get_heart("HeartsHolder/HeartsEmpty/heart5"),
		_must_get_heart("HeartsHolder/HeartsEmpty/heart6")
	]

	full_textures.clear()
	empty_textures.clear()

	for i in range(hearts.size()):
		full_textures.append(hearts[i].texture)
		empty_textures.append(empty_hearts[i].texture)

	var empty_holder: Node = get_node_or_null("HeartsHolder/HeartsEmpty")
	if empty_holder:
		(empty_holder as CanvasItem).visible = false

	# -------------------- Lives Hook --------------------
	if Global and Global.has_signal("lives_changed"):
		if not Global.lives_changed.is_connected(_on_lives_changed):
			Global.lives_changed.connect(_on_lives_changed)
		_on_lives_changed(Global.lives)

	# Connect to player signal a moment later (safer with instanced scenes)
	call_deferred("_connect_charge_bar_to_player")
	
	if collect_ui:
		collect_ui.visible = false
		
		
func _process(delta: float) -> void:
	if charge_bar == null:
		return

	# show while charging or draining
	if _charge_active or charge_bar.value > 0.001:
		charge_bar.visible = true

	var speed := charge_fill_speed if _charge_target > charge_bar.value else charge_drain_speed
	charge_bar.value = move_toward(charge_bar.value, _charge_target, speed * delta)

	# hide when empty and not charging
	if not _charge_active and charge_bar.value <= 0.001:
		charge_bar.value = 0.0
		charge_bar.visible = false


# -------------------- PAUSE --------------------

func _on_pause_pressed() -> void:
	var now_paused := not get_tree().paused
	get_tree().paused = now_paused

	# Safety: if fade got stuck visible for any reason, never let it block UI
	if fade:
		fade.visible = false

	if pause_menu:
		pause_menu.visible = now_paused

	_update_pause_button_text()

func _on_resume_pressed() -> void:
	get_tree().paused = false

	if pause_menu:
		pause_menu.visible = false

	_update_pause_button_text()

func _update_pause_button_text() -> void:
	if pause_button:
		pause_button.text = "Resume" if get_tree().paused else "Pause"

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	
	if pause_menu:
		pause_menu.visible = false
		
	_update_pause_button_text()
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_settings_pressed() -> void:
	print("Settings clicked (make a settings menu next)")

func _on_rules_pressed() -> void:
	print("Rules clicked (make a rules screen next)")


# -------------------- CHARGE BAR SIGNAL --------------------

func _connect_charge_bar_to_player() -> void:
	var player: Node = _find_player()
	if player == null:
		return

	if not player.has_signal("charge_progress_changed"):
		return

	if not player.charge_progress_changed.is_connected(_on_charge_progress_changed):
		player.charge_progress_changed.connect(_on_charge_progress_changed)

func _on_charge_progress_changed(progress: float, charging: bool) -> void:
	_charge_target = clamp(progress, 0.0, 1.0)
	_charge_active = charging
	if not charging:
		_charge_target = 0.0


func _find_player() -> Node:
	# 1) group
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]

	# 2) name in current scene
	var root := get_tree().current_scene
	if root:
		var p := root.get_node_or_null("Player")
		if p:
			return p

	# 3) find any node that has the signal
	if root:
		return _find_node_with_signal(root, "charge_progress_changed")

	return null


func _find_node_with_signal(node: Node, sig: String) -> Node:
	if node.has_signal(sig):
		return node

	for child in node.get_children():
		var found := _find_node_with_signal(child, sig)
		if found:
			return found

	return null


# -------------------- HEARTS --------------------

func _on_lives_changed(lives_value: int) -> void:
	var ui_capacity: int = hearts.size()
	var maxl: int = int(clamp(Global.max_lives, 0, ui_capacity))
	var lives: int = int(clamp(lives_value, 0, maxl))

	for i in range(maxl):
		hearts[i].texture = full_textures[i] if i < lives else empty_textures[i]
		hearts[i].visible = true

	for i in range(maxl, ui_capacity):
		hearts[i].visible = false

	if game_over_label:
		game_over_label.visible = (lives <= 0)


func _must_get_heart(path: String) -> TextureRect:
	var node: Node = get_node_or_null(path)
	var heart: TextureRect = node as TextureRect

	return heart

# -------------------- FADE --------------------

func fade_in(time: float = 0.5) -> void:
	_kill_tween()

	if fade == null:
		return

	# Make sure fade never blocks clicks (redundant but safe)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fade.visible = true
	fade.modulate.a = 1.0

	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # keep tween working even if paused
	_tween.tween_property(fade, "modulate:a", 0.0, time)

	_tween.finished.connect(func() -> void:
		if fade:
			fade.visible = false
	)


func _kill_tween() -> void:
	if _tween:
		_tween.kill()
	_tween = null


# -------------------- HELPERS --------------------

func _safe_connect_pressed(btn: Button, callable: Callable) -> void:
	if btn == null:
		return

	btn.process_mode = Node.PROCESS_MODE_ALWAYS

	if not btn.pressed.is_connected(callable):
		btn.pressed.connect(callable)


# saistīts ar letter ui. pazūd šis ui
func hide_for_letter(active: bool) -> void:
	# Hide the whole UI layer
	visible = not active

	# Safety: always force pause menu hidden
	if pause_menu:
		pause_menu.visible = false


func show_collect_label(show: bool) -> void:
	if collect_ui:
		collect_ui.visible = show
