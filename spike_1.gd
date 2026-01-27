extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return

	Global.lives -= 1

	# play hurt animation + fall + reset
	if body.has_method("hurt_and_reset"):
		body.hurt_and_reset(global_position.x)
	elif body.has_method("reset_to_start"):
		body.reset_to_start()

	if Global.lives <= 0:
		get_tree().change_scene_to_file("res://MainMenu.tscn")
