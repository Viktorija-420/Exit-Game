extends Area2D

@export_file("*.tscn") var next_level_scene: String = "res://MainMenu.tscn"

@onready var anim: AnimatedSprite2D = $Sprite2D
@onready var trigger_shape: CollisionShape2D = $TriggerShape

var _transitioning := false

func _ready() -> void:
	# Make sure trigger works
	monitoring = true
	monitorable = true
	if trigger_shape:
		trigger_shape.disabled = false

	body_entered.connect(_on_body_entered)
	Global.key_changed.connect(_on_key_changed)

	_update_door()

func _on_key_changed(_has_key: bool) -> void:
	_update_door()

	# If player is already inside the door area when key is collected
	if Global.has_key and not _transitioning:
		for b in get_overlapping_bodies():
			if b != null and b.is_in_group("player"):
				_try_transition()
				break

func _update_door() -> void:
	if Global.has_key:
		if anim and anim.sprite_frames and anim.sprite_frames.has_animation("Open"):
			anim.play("Open")
	else:
		if anim and anim.sprite_frames and anim.sprite_frames.has_animation("Closed"):
			anim.play("Closed")

func _on_body_entered(body: Node2D) -> void:
	if body == null:
		return
	if not body.is_in_group("player"):
		return
	if not Global.has_key:
		return

	_try_transition()

func _try_transition() -> void:
	if _transitioning:
		return

	_transitioning = true

	# change scene after the signal/physics step (safe)
	get_tree().call_deferred("change_scene_to_file", next_level_scene)
