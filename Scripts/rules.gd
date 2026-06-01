extends Node2D

@export_file("*.tscn") var main_menu_scene := "res://MainMenu.tscn"

@onready var back_button: Button = get_node_or_null("Menu/Panel/Back") as Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if back_button == null:
		push_error("Rules: Back button not found. Expected a Button named 'Back'.")
		return

	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	if Global.settings_return_path == "InGame":
		# We are inside an active level! Hide this menu overlay and show the pause menu back.
		var parent_canvas = get_parent()
		if parent_canvas:
			self.visible = false
			var pause_panel = parent_canvas.get_node_or_null("PauseMenu")
			if pause_panel:
				pause_panel.visible = true
	else:
		# We came from MainMenu scene! Change scene back to normal.
		var destination = Global.settings_return_path if Global.settings_return_path != "InGame" else main_menu_scene
		get_tree().change_scene_to_file(destination)
