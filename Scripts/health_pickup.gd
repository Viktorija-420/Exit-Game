extends Area2D

@export var heal_amount: int = 1

# --- References ---
@onready var local_label: Label = $Label 
@onready var anim: Sprite2D = $Sprite2D
@onready var light: PointLight2D = get_node_or_null("PointLight2D")
@onready var drink: AudioStreamPlayer2D = $Drink

var ui_label_container: CanvasItem # The "UI/Collect" from your first screenshot

# --- Logic Variables ---
var player_near: bool = false
@export var glow_speed: float = 5.0
@export var glow_min_energy: float = 0.6
@export var glow_max_energy: float = 2.0
var _glow_time: float = 0.0

func _ready() -> void:
	# Find the UI label in the scene tree
	var root = get_tree().current_scene
	if root:
		ui_label_container = root.get_node_or_null("UI/Collect") as CanvasItem

	# Start with both labels hidden
	if local_label: local_label.visible = false
	if ui_label_container: ui_label_container.visible = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if player_near:
		update_labels_visibility()
		
		# Only allow drinking if below max lives
		if Global.lives < Global.max_lives_cap:
			if Input.is_action_just_pressed("Collect"):
				collect()
		
	# Handle glow animation
	if light:
		_glow_time += delta * glow_speed
		var t = (sin(_glow_time) + 1.0) / 2.0
		light.energy = lerp(glow_min_energy, glow_max_energy, t)

func update_labels_visibility() -> void:
	if Global.lives >= Global.max_lives_cap:
		# FULL HEALTH: Show the label on the potion, hide the UI prompt
		if local_label:
			local_label.text = "Already at full health"
			local_label.visible = true
		if ui_label_container:
			ui_label_container.visible = false
	else:
		# NOT FULL: Show the UI prompt, hide the local label
		if local_label:
			local_label.visible = false
		if ui_label_container:
			ui_label_container.visible = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		# Hide both when leaving
		if local_label: local_label.visible = false
		if ui_label_container: ui_label_container.visible = false

func collect() -> void:
	if Global.lives >= Global.max_lives_cap:
		return

	drink.play()
	
	# Disable interaction and visuals
	player_near = false
	if anim: anim.visible = false
	if light: light.enabled = false
	if local_label: local_label.visible = false
	if ui_label_container: ui_label_container.visible = false
	
	Global.gain_life(heal_amount)

	await drink.finished
	queue_free()
