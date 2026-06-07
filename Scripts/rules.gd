extends Node2D

@export_file("*.tscn") var main_menu_scene := "res://MainMenu.tscn"

const COLOR_NORMAL := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_HOVER  := Color(0.75, 0.75, 0.75, 1.0)
const COLOR_PRESSED := Color(0.85, 0.65, 0.75, 1.0)

@onready var back_button: Button = get_node_or_null("Menu/Panel/Back") as Button

func _ready() -> void:
	# Nodrošina, ka noteikumu scēna strādā, kad spēle ir nopauzēta
	process_mode = Node.PROCESS_MODE_ALWAYS

	if back_button == null:
		push_error("Rules: Back button not found. Expected a Button named 'Back'.")
		return

	# Pievienojam vizuālo loģiku un attīrām focus stilus
	_setup_button_visuals(back_button)

	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

## Palīgfunkcija pogas vizuālajai loģikai un noklusējuma stilu attīrīšanai
func _setup_button_visuals(btn: Button) -> void:
	# 1. Noņemam Godot noklusējuma pogas rāmjus un fokusa līniju klikšķinot
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE

	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	# 2. ✅ LABOJUMS: Atrodam TextureRect kā kaimiņu mezglu (nodevām pareizu ceļu no pogas pozīcijas)
	var tex_rect: TextureRect = btn.get_node_or_null("../TextureRect") as TextureRect
	var is_hovered := false

	# 3. Savienojam peles interakcijas ar krāsu maiņu
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

func _on_back_pressed() -> void:
	# Atgriežas uz saglabāto ceļu (Main Menu VAI Level scēnu)
	var destination = Global.settings_return_path if Global.settings_return_path != "" else main_menu_scene
	if ResourceLoader.exists(destination):
		get_tree().change_scene_to_file(destination)
