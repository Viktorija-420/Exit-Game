extends Node2D

@onready var play_button: Button = $Menu/MenuButtons/PlayButton
@onready var rules_button: Button = $Menu/MenuButtons/RulesButton
@onready var settings_button: Button = $Menu/MenuButtons/SettingsButton
@onready var quit_button: Button = $Menu/MenuButtons/QuitButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	rules_button.pressed.connect(_on_rules_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	# ✅ RESET LIVES WHEN STARTING A NEW GAME
	Global.reset_run()

	# then go to the first level
	get_tree().change_scene_to_file("res://Level_01.tscn")

func _on_rules_pressed() -> void:
	get_tree().change_scene_to_file("res://Rules.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://Settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
