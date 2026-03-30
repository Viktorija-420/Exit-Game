extends Area2D

@export_file("*.tscn") var next_level_scene: String = ""

@onready var anim: AnimatedSprite2D = $Sprite2D
@onready var trigger_shape: CollisionShape2D = $TriggerShape

@onready var open_door: AudioStreamPlayer2D = $DoorOpen
@onready var locked_door: AudioStreamPlayer2D = $DoorLocked

var _transitioning := false
var player_ref: CharacterBody2D = null # Store the player to update the UI
var is_open := false

func _ready() -> void:
	add_to_group("door") # Ensure it's in the group
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	Global.key_changed.connect(_on_key_changed)
	
	# Start closed
	if anim: anim.play("Closed")

func _process(_delta: float) -> void:
	# Only allow transition if the door IS OPEN (after cutscene)
	if player_ref and Global.has_key and is_open and not _transitioning:
		if Input.is_action_just_pressed("interact"):
			_try_transition()

func _on_key_changed(_has_key: bool) -> void:
	# We don't play animation here anymore, the cutscene handles it
	_update_ui()
	
func play_open_animation() -> void:
	if anim and anim.sprite_frames.has_animation("DoorAnim"):
		open_door.play()
		anim.play("DoorAnim")
		is_open = true # Now the door is officially "usable"
		_update_ui()

func _update_ui() -> void:
	if player_ref and player_ref.has_node("DoorLabel"):
		var label = player_ref.get_node("DoorLabel") as Label
		if not Global.has_key:
			locked_door.play()
			label.text = "I need a key first"
			label.visible = true
		elif is_open:
			label.text = " "
			label.visible = true
		else:
			# Key is found but cutscene hasn't finished/started
			label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body
		_update_ui()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if player_ref and player_ref.has_node("DoorLabel"):
			player_ref.get_node("DoorLabel").visible = false
		player_ref = null

func _try_transition() -> void:
	if _transitioning or next_level_scene == "":
		return

	_transitioning = true
	# Hide UI immediately on transition
	if player_ref and player_ref.has_node("DoorLabel"):
		player_ref.get_node("DoorLabel").visible = false
		
	call_deferred("_reset_key_and_change_scene")

func _reset_key_and_change_scene() -> void:
	# Keep the key if you want it to persist, or reset it:
	Global.has_key = false 
	get_tree().change_scene_to_file(next_level_scene)
