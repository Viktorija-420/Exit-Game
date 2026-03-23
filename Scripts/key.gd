extends Area2D

@export var collect_label_path: NodePath
@export var blink_speed: float = 2.0      # how fast it blinks
@export var light_on_energy: float = 2.5  # strong glow
@export var light_off_energy: float = 0.0 # fully off

@onready var label: CanvasItem = get_node_or_null(collect_label_path) as CanvasItem
@onready var sprite: Sprite2D = $Sprite2D
@onready var glow_light: PointLight2D = $PointLight2D

var player_near: bool = false
var blink_time: float = 0.0


func _ready() -> void:
	if label:
		label.visible = false

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	blink_time += delta

	# Handle collecting
	if player_near and Input.is_action_just_pressed("Collect"):
		collect()

	# Blink glow ON / OFF
	if glow_light:
		var is_on = int(blink_time * blink_speed) % 2 == 0
		
		if is_on:
			glow_light.energy = light_on_energy
			if sprite:
				sprite.modulate = Color(1.2, 1.2, 1.2)
		else:
			glow_light.energy = light_off_energy
			if sprite:
				sprite.modulate = Color(0.8, 0.8, 0.8)


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
	# 1. Atzīmējam, ka atslēga ir iegūta
	Global.has_key = true
	
	# 2. Paslēpjam atslēgu un label, lai izskatās, ka tā ir paņemta
	if label: label.visible = false
	sprite.visible = false
	if glow_light: glow_light.enabled = false
	
	# Atrodam spēlētāju un durvis
	var player = get_tree().get_first_node_in_group("player")
	var door = get_tree().current_scene.find_child("Door", true, false) # Meklē mezglu ar nosaukumu "Door"

	if player and door:
		# Apturam spēlētāja kustību uz laiku
		player.controls_enabled = false
		
		# Izsaucam kameras funkciju (šo tūlīt pievienosim player skriptā)
		await player.show_door_cutscene(door.global_position)
		
		# Atļaujam spēlētājam atkal kustēties
		player.controls_enabled = true

	# Tagad varam droši izdzēst atslēgas objektu
	queue_free()
