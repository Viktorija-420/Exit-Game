extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return

	# stop double-trigger while still overlapping
	if body.has_method("is_hurt") and body.is_hurt():
		return

	# hurt + reset (Player handles losing life inside hurt_and_reset)
	if body.has_method("hurt_and_reset"):
		body.hurt_and_reset(global_position.x)
	elif body.has_method("reset_to_start"):
		body.reset_to_start()

	# IMPORTANT: change scene deferred (safer inside signals/physics)
	if Global.lives <= 0:
		get_tree().call_deferred("change_scene_to_file", "res://MainMenu.tscn")
