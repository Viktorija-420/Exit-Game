extends Control

@export_file("*.tscn") var first_level_scene := "res://Level_01.tscn"
@export_file("*.tscn") var rules_scene := "res://Rules.tscn"
@export_file("*.tscn") var settings_scene := "res://Settings.tscn"

@onready var play_button: Button = get_node_or_null("Menu/MenuButtons/PlayButton") as Button
@onready var rules_button: Button = get_node_or_null("Menu/MenuButtons/RulesButton") as Button
@onready var settings_button: Button = get_node_or_null("Menu/MenuButtons/SettingsButton") as Button
@onready var quit_button: Button = get_node_or_null("Menu/MenuButtons/QuitButton") as Button

func _ready() -> void:
	get_tree().paused = false
	_safe_connect(play_button, _on_play_pressed)
	_safe_connect(rules_button, _on_rules_pressed)
	_safe_connect(settings_button, _on_settings_pressed)
	_safe_connect(quit_button, _on_quit_pressed)

func _on_play_pressed() -> void:
	Global.reset_run()
	_change_scene(first_level_scene)

func _on_rules_pressed() -> void:
	_change_scene(rules_scene)

func _on_settings_pressed() -> void:
	_change_scene(settings_scene)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _safe_connect(btn: Button, cb: Callable) -> void:
	if btn and not btn.pressed.is_connected(cb):
		btn.pressed.connect(cb)

func _change_scene(path: String) -> void:
	if path != "" and ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
