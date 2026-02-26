extends Node2D

@export var back_scene: PackedScene  # drag MainMenu.tscn here in Inspector

@onready var back_button: Button = (
	get_node_or_null("Menu/Panel/Back") as Button
)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false

	if back_button == null:
		push_error("Rules: Back button not found. Expected a Button named 'Back'.")
		return

	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	if back_scene == null:
		push_error("Rules: back_scene not set. Drag MainMenu.tscn into the export field.")
		return

	get_tree().change_scene_to_packed(back_scene)
