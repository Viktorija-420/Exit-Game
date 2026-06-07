extends Node2D

@export_file("*.tscn") var intro_scene: String = "res://intro.tscn"
@export var fade_time: float = 0.6

const COLOR_NORMAL := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_HOVER  := Color(0.75, 0.75, 0.75, 1.0)
const COLOR_PRESSED := Color(0.85, 0.65, 0.75, 1.0)

@onready var play_button: Button = $Menu/PlayButton
@onready var rules_button: Button = $Menu/RulesButton
@onready var settings_button: Button = $Menu/SettingsButton
@onready var quit_button: Button = $Menu/QuitButton
@onready var fade: ColorRect = $Fade

var _transitioning := false

func _ready() -> void:
	# Pogu pamatfunkcionalitāte
	play_button.pressed.connect(_on_play_pressed)
	rules_button.pressed.connect(_on_rules_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Iestatām pielāgotus vizuālos stāvokļus katrai pogai
	_setup_button_visuals(play_button)
	_setup_button_visuals(rules_button)
	_setup_button_visuals(settings_button)
	_setup_button_visuals(quit_button)

	if fade:
		fade.visible = true
		fade.color = Color.BLACK
		fade.modulate.a = 0.0

func _setup_button_visuals(btn: Button) -> void:
	# 1. Noņemam Godot noklusējuma pogas tēmas vizuālos elementus (padara pogas fonu caurspīdīgu)
	btn.flat = true
	
	# Tāpat notīrām fokusa kontūras, lai tās neparādītos, kad tiek uzklikšķināts
	btn.focus_mode = Control.FOCUS_NONE

	# 2. Droši paņemam bērna mezglu TextureRect
	var tex_rect := btn.get_child(0) as TextureRect
	if not tex_rect:
		return

	# Izsekojam stāvokli lokāli katrai pogai, lai izvairītos no viewport vaicājumiem
	var is_hovered := false

	# 3. Savienojam peles uzvirzīšanas un klikšķu interakcijas, lai modulētu GAN Button, GAN TextureRect
	btn.mouse_entered.connect(func(): 
		is_hovered = true
		tex_rect.modulate = COLOR_HOVER
		btn.self_modulate = COLOR_HOVER
	)
	btn.mouse_exited.connect(func(): 
		is_hovered = false
		tex_rect.modulate = COLOR_NORMAL
		btn.self_modulate = COLOR_NORMAL
	)
	btn.button_down.connect(func(): 
		tex_rect.modulate = COLOR_PRESSED
		btn.self_modulate = COLOR_PRESSED
	)
	btn.button_up.connect(func(): 
		# Droša uzvirzīšanas stāvokļa atjaunošana abiem elementiem
		var target_color := COLOR_HOVER if is_hovered else COLOR_NORMAL
		tex_rect.modulate = target_color
		btn.self_modulate = target_color
	)

func _on_play_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true

	Global.reset_run()

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(fade, "modulate:a", 1.0, fade_time)
	t.tween_callback(func(): get_tree().change_scene_to_file(intro_scene))

func _on_rules_pressed() -> void:
	Global.settings_return_path = "res://MainMenu.tscn"
	Global.was_paused = false
	get_tree().change_scene_to_file("res://Rules.tscn")

func _on_settings_pressed() -> void:
	Global.settings_return_path = "res://MainMenu.tscn"
	Global.was_paused = false
	get_tree().change_scene_to_file("res://settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
