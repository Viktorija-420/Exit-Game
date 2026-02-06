extends Control

@onready var play_button: Button = $Menu/MenuButtons/PlayButton
@onready var rules_button: Button = $Menu/MenuButtons/RulesButton
@onready var settings_button: Button = $Menu/MenuButtons/SettingsButton
@onready var quit_button: Button = $Menu/MenuButtons/QuitButton

@export_file("*.tscn") var first_level_scene: String = "res://Level1.tscn"

func _ready() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)

func _on_play_pressed() -> void:
	# ✅ Reset lives every time a new game starts
	Global.reset_run()

	# go to level
	get_tree().change_scene_to_file(first_level_scene)
