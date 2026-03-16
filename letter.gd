extends Area2D

@onready var player_near: bool = false

# Reference to the player so we can call pickup
var player_ref: Node = null

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_near = true
		player_ref = body

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_near = false
		player_ref = null

func pickup():
	if not player_ref:
		return
	# Tell player to show the 3D letter UI
	player_ref.show_letter_3d()
	queue_free()  # remove the letter from the world
