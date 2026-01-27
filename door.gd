extends Area2D

@export_file("*.tscn") var next_level_scene: String = "res://MainMenu.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Global.current_level += 1
		get_tree().change_scene_to_file(next_level_scene)
