extends Area2D

@export_file("*.tscn") var next_level_scene: String = "res://MainMenu.tscn"

@onready var anim: AnimatedSprite2D = $Sprite2D
@onready var blocker_shape: CollisionShape2D = $Blocker/CollisionShape2D

var _transitioning: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	Global.key_changed.connect(_on_key_changed)
	_update_door()


func _on_key_changed(_has_key: bool) -> void:
	_update_door()


func _update_door() -> void:
	if Global.has_key:
		if anim and anim.sprite_frames and anim.sprite_frames.has_animation("Open"):
			anim.play("Open")
		if blocker_shape:
			blocker_shape.disabled = true
	else:
		if anim and anim.sprite_frames and anim.sprite_frames.has_animation("Closed"):
			anim.play("Closed")
		if blocker_shape:
			blocker_shape.disabled = false


func _on_body_entered(body: Node2D) -> void:
	if _transitioning:
		return

	# Accept ANY player node type (CharacterBody2D, etc.) as long as it's in group "player"
	if not body.is_in_group("player"):
		return

	# Require key
	if not Global.has_key:
		return

	_transitioning = true

	# stop re-triggering instantly
	monitoring = false
	if blocker_shape:
		blocker_shape.disabled = true

	# Change scene SAFELY after physics step + validate path
	call_deferred("_change_scene_safely")


func _change_scene_safely() -> void:
	if next_level_scene == "":
		push_error("Door: next_level_scene is empty!")
		return

	var packed := load(next_level_scene)
	if packed == null or not (packed is PackedScene):
		push_error("Door: can't load scene at path: " + str(next_level_scene))
		return

	get_tree().change_scene_to_packed(packed)
