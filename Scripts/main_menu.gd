extends Node2D

@export_file("*.tscn") var intro_scene: String = "res://intro.tscn"
@export var fade_time: float = 0.6

@onready var play_button: Button = $Menu/MenuButtons/PlayButton
@onready var rules_button: Button = $Menu/MenuButtons/RulesButton
@onready var settings_button: Button = $Menu/MenuButtons/SettingsButton
@onready var quit_button: Button = $Menu/MenuButtons/QuitButton
@onready var fade: ColorRect = $Fade

var _transitioning := false

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	rules_button.pressed.connect(_on_rules_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	if fade:
		fade.visible = true
		fade.color = Color.BLACK
		fade.modulate.a = 0.0

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
	get_tree().change_scene_to_file("res://Rules.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://Settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
