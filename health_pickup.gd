extends Area2D

@export var heal_amount: int = 1

var label: CanvasItem
@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

var player_near: bool = false

func _ready() -> void:
	# ✅ Grab the shared Collect label from the level UI automatically
	var root := get_tree().current_scene
	if root:
		label = root.get_node_or_null("UI/Collect") as CanvasItem

	if label:
		label.visible = false
	else:
		push_warning("HealthPickup: Could not find UI/Collect/Label in current scene.")

	if anim:
		anim.play()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_near and Input.is_action_just_pressed("Collect"):
		collect()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = true
		if label:
			label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		if label:
			label.visible = false

func collect() -> void:
	Global.gain_life(heal_amount)

	if label:
		label.visible = false

	call_deferred("queue_free")
