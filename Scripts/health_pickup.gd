extends Area2D

@export var heal_amount: int = 1

var label: CanvasItem
@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

# Glow effect
@onready var light: PointLight2D = get_node_or_null("PointLight2D")
@export var glow_min_energy: float = 0.6
@export var glow_max_energy: float = 2.0
@export var glow_speed: float = 5.0
var _glow_time: float = 0.0

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

func _process(delta: float) -> void:
	if player_near and Input.is_action_just_pressed("Collect"):
		print("COLLECT PRESSED")
		collect()
		
	if light:
		_glow_time += delta * glow_speed
		var t = (sin(_glow_time) + 1.0) / 2.0
		light.energy = lerp(glow_min_energy, glow_max_energy, t)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = true
		if label:
			label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("PLAYER ENTERED")
		player_near = false
		if label:
			label.visible = false

func collect() -> void:
	print("COLLECT FUNCTION")
	Global.gain_life(heal_amount)

	if label:
		label.visible = false

	call_deferred("queue_free")
