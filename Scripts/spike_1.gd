# Spike.gd — fixed
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	if body.has_method("hurt_and_reset"):
		body.hurt_and_reset(global_position.x)
