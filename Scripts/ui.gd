extends CanvasLayer

# --- Custom Button Colors & Visual States ---
const COLOR_NORMAL := Color(1.0, 1.0, 1.0, 1.0)       # Default white/unmodulated
const COLOR_HOVER  := Color(0.75, 0.75, 0.75, 1.0)    # Greyish
const COLOR_PRESSED := Color(0.85, 0.65, 0.75, 1.0)    # Pinkish-Grey

# -------------------- NODES --------------------

@onready var pause_menu: Control = get_node_or_null("UI_Root/MainContainer/PauseMenu") as Control
@onready var blur_overlay: ColorRect = get_node_or_null("UI_Root/MainContainer/PauseMenu/BlurOverlay") as ColorRect
@onready var main_menu_button: Button = get_node_or_null("UI_Root/MainContainer/PauseMenu/Panel/MainMenuButton") as Button
@onready var settings_button: Button = get_node_or_null("UI_Root/MainContainer/PauseMenu/Panel/SettingButton") as Button
@onready var rules_button: Button = get_node_or_null("UI_Root/MainContainer/PauseMenu/Panel/RulesButton") as Button
@onready var exit_button: Button = get_node_or_null("UI_Root/MainContainer/PauseMenu/Panel/ExitButton") as Button

@onready var pause_button: Button = get_node_or_null("UI_Root/MainContainer/PauseButton") as Button
@onready var game_over_label: Label = get_node_or_null("UI_Root/MainContainer/GameOverLabel") as Label
@onready var fade: ColorRect = get_node_or_null("UI_Root/MainContainer/Fade") as ColorRect

# -------------------- EXPORTS --------------------

@export var fade_in_on_start: bool = true
@export var fade_in_time: float = 0.6

@export var charge_fill_speed: float = 3.5
@export var charge_drain_speed: float = 5.0

# -------------------- HEARTS --------------------

var hearts: Array[TextureRect] = []
var full_textures: Array[Texture2D] = []
var empty_textures: Array[Texture2D] = []

var _tween: Tween

# -------------------- Collect --------------------

@onready var collect_ui: CanvasItem = get_node_or_null("UI_Root/MainContainer/Collect")

func _ready() -> void:
	# UI must keep working when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# -------------------- Pause Menu Setup --------------------
	if pause_menu:
		pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		pause_menu.visible = false

	if blur_overlay:
		blur_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
		blur_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Pause button setup
	if pause_button:
		pause_button.process_mode = Node.PROCESS_MODE_ALWAYS
		_setup_button_visuals(pause_button)
		pause_button.move_to_front()
		_safe_connect_pressed(pause_button, _on_pause_pressed)
		_update_pause_button_text()
	
	var resume_button = get_node_or_null("UI_Root/MainContainer/PauseMenu/Panel/ResumeButton")
	if resume_button: _safe_connect_pressed(resume_button, _on_resume_pressed)
	
	# Menu buttons with style handling
	_setup_button_visuals(main_menu_button)
	_setup_button_visuals(settings_button)
	_setup_button_visuals(rules_button)
	_setup_button_visuals(exit_button)

	_safe_connect_pressed(main_menu_button, _on_main_menu_pressed)
	_safe_connect_pressed(settings_button, _on_settings_pressed)
	_safe_connect_pressed(rules_button, _on_rules_pressed)
	_safe_connect_pressed(exit_button, _on_exit_pressed)

	# -------------------- Game Over Label --------------------
	if game_over_label:
		game_over_label.visible = false
		game_over_label.process_mode = Node.PROCESS_MODE_ALWAYS

	# -------------------- Fade Setup --------------------
	if fade:
		fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		fade.z_index = 999
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fade.process_mode = Node.PROCESS_MODE_ALWAYS
		fade.visible = true
		fade.modulate.a = 1.0

		if fade_in_on_start:
			fade_in(fade_in_time)
		else:
			fade.visible = false

	# -------------------- Hearts Setup --------------------
	hearts = [
		_must_get_heart("UI_Root/MainContainer/HeartsHolder/Hearts/heart1"),
		_must_get_heart("UI_Root/MainContainer/HeartsHolder/Hearts/heart2"),
		_must_get_heart("UI_Root/MainContainer/HeartsHolder/Hearts/heart3"),
		_must_get_heart("UI_Root/MainContainer/HeartsHolder/Hearts/heart4"),
		_must_get_heart("UI_Root/MainContainer/HeartsHolder/Hearts/heart5"),
		_must_get_heart("UI_Root/MainContainer/HeartsHolder/Hearts/heart6")
	]

	var empty_hearts: Array[TextureRect] = [
		_must_get_heart("UI_Root/MainContainer/HeartsHolder/HeartsEmpty/heart1"),
		_must_get_heart("UI_Root/MainContainer/HeartsHolder/HeartsEmpty/heart2"),
		_must_get_heart("UI_Root/MainContainer/HeartsHolder/HeartsEmpty/heart3"),
		_must_get_heart("UI_Root/MainContainer/HeartsHolder/HeartsEmpty/heart4"),
		_must_get_heart("UI_Root/MainContainer/HeartsHolder/HeartsEmpty/heart5"),
		_must_get_heart("UI_Root/MainContainer/HeartsHolder/HeartsEmpty/heart6")
	]

	full_textures.clear()
	empty_textures.clear()

	for i in range(hearts.size()):
		full_textures.append(hearts[i].texture)
		empty_textures.append(empty_hearts[i].texture)

	var empty_holder: Node = get_node_or_null("UI_Root/MainContainer/HeartsHolder/HeartsEmpty")
	if empty_holder:
		(empty_holder as CanvasItem).visible = false

	# -------------------- Lives Hook --------------------
	if Global and Global.has_signal("lives_changed"):
		if not Global.lives_changed.is_connected(_on_lives_changed):
			Global.lives_changed.connect(_on_lives_changed)
		_on_lives_changed(Global.lives)
	
	if collect_ui:
		collect_ui.visible = false

	# -------------------- PAUZES STĀVOKĻA ATJAUNOŠANA --------------------
	# Ja mēs tikko atgriezāmies no Settings vai Rules un spēlei ir jābūt nopauzētai:
	if Global and Global.was_paused:
		get_tree().paused = true
		if pause_menu:
			pause_menu.visible = true
		_update_pause_button_text()
		if pause_button:
			pause_button.move_to_front()
		Global.was_paused = false # Atiestatām stāvokli drošībai
		
# -------------------- PAUSE --------------------

func _on_pause_pressed() -> void:
	var now_paused := not get_tree().paused
	get_tree().paused = now_paused

	if fade:
		fade.visible = false

	if pause_menu:
		pause_menu.visible = now_paused

	_update_pause_button_text()
	
	if pause_button:
		pause_button.move_to_front()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Use get_viewport().set_input_as_handled() to prevent other nodes 
		# from reacting to this specific ESC press.
		get_viewport().set_input_as_handled()
		
		# Call your existing pause toggle function
		_on_pause_pressed()
		
		
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
	if Global and get_tree().current_scene:
		# Saglabājam pašreizējā līmeņa scēnas faila ceļu un uzstādām, ka bijām pauzē
		Global.settings_return_path = get_tree().current_scene.scene_file_path
		Global.was_paused = true
	get_tree().change_scene_to_file("res://settings.tscn")

func _on_rules_pressed() -> void:
	if Global and get_tree().current_scene:
		# Saglabājam pašreizējā līmeņa scēnas faila ceļu un uzstādām, ka bijām pauzē
		Global.settings_return_path = get_tree().current_scene.scene_file_path
		Global.was_paused = true
	get_tree().change_scene_to_file("res://Rules.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()


func _find_player() -> Node:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]

	var root := get_tree().current_scene
	if root:
		var p := root.get_node_or_null("Player")
		if p:
			return p

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

	if not fade:
		return

	#fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.visible = true
	fade.modulate.a = 1.0

	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(fade, "modulate:a", 0.0, time)

	_tween.finished.connect(func() -> void:
		if fade:
			fade.visible = false
	)


func _kill_tween() -> void:
	if _tween:
		_tween.kill()
	_tween = null


# -------------------- HELPERS & VISUAL STYLING --------------------

func _safe_connect_pressed(btn: Button, callable: Callable) -> void:
	if btn == null:
		return

	btn.process_mode = Node.PROCESS_MODE_ALWAYS

	if not btn.pressed.is_connected(callable):
		btn.pressed.connect(callable)


## Clean up focus behaviors and hook up modulation transitions based on mouse input
func _setup_button_visuals(btn: Button) -> void:
	if btn == null: return

	# 1. Clean up focus and button properties
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	
	# Fix formatting issues that cut off text strings during theme switches:
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.clip_text = false
	
	# Override Godot's built-in styles to prevent text shifting margins on hover/focus
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	# 2. Look for the child TextureRect image safely
	var tex_rect: TextureRect = null
	if btn.get_child_count() > 0:
		tex_rect = btn.get_child(0) as TextureRect

	var is_hovered := false

	# 3. Hook transitions up to signals
	btn.mouse_entered.connect(func():
		is_hovered = true
		btn.self_modulate = COLOR_HOVER
		if tex_rect: tex_rect.modulate = COLOR_HOVER
	)
	btn.mouse_exited.connect(func():
		is_hovered = false
		btn.self_modulate = COLOR_NORMAL
		if tex_rect: tex_rect.modulate = COLOR_NORMAL
	)
	btn.button_down.connect(func():
		btn.self_modulate = COLOR_PRESSED
		if tex_rect: tex_rect.modulate = COLOR_PRESSED
	)
	btn.button_up.connect(func():
		var target_color := COLOR_HOVER if is_hovered else COLOR_NORMAL
		btn.self_modulate = target_color
		if tex_rect: tex_rect.modulate = target_color
	)


func hide_for_letter(active: bool) -> void:
	visible = not active

	if pause_menu:
		pause_menu.visible = false


func show_collect_label(show: bool) -> void:
	if collect_ui:
		collect_ui.visible = show
