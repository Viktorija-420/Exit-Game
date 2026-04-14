extends CharacterBody2D

# -------------------------
# VARIABLES & STATE
# -------------------------
var player_alive: bool = true
var _attacking: bool = false 
var _hurt: bool = false
var _hurt_timer: float = 0.0
var _shielding: bool = false
var _normal_scale: Vector2
var controls_enabled: bool = true

var enemy_inattack_range: bool = false
var enemy_attack_cooldown: bool = true
var last_enemy_hit_position: float = 0.0 
var current_enemy = null

var current_letter: Node = null

# -------------------------
# NODES
# -------------------------
@onready var anim: AnimatedSprite2D = $Anim
@onready var cam: Camera2D = $Camera2D
@onready var door_label: Label = $DoorLabel

# -------------------------
# SETTINGS
# -------------------------
@export_group("Movement")
@export var speed: float = 200.0
@export var jump_force: float = -400.0
@export var gravity: float = 1200.0 

@export_group("Hurt & Jolt Settings")
@export var hurt_fall_time: float = 0.40
@export var hurt_knockup: float = -350.0 
@export var hurt_push_x: float = 400.0
@export var hurt_throb_scale: float = 1.18
@export var hurt_throb_time: float = 0.10

# -------------------------
# CAMERA
# -------------------------
@export_group("Camera Shake")
@export var shake_strength: float = 15.0 
@export var shake_decay: float = 8.0
@export var shake_noise_speed: float = 25.0
var _shake_amount: float = 0.0
var _noise_time: float = 0.0

@export_group("Camera Follow")
@export var look_ahead_distance: float = 80.0
@export var look_ahead_speed: float = 3.0

var _look_ahead: float = 0.0

var _was_on_floor: bool = false

@export var landing_shake_strength: float = 6.0
@export var landing_velocity_threshold: float = 250.0

# -------------------------
# SHIELD
# -------------------------

@export_group("Shield Settings")
@export var shield_action: StringName = &"Shield"
@export var shield_speed_mult: float = 0.55

# -------------------------
# DUST
# -------------------------

@onready var dust: GPUParticles2D = $Dust
@onready var landing_dust: GPUParticles2D = $LandingDUst

# -------------------------
# VOID
# -------------------------
@export var void_y_level: float = 1000.0

# -------------------------
# SOUND
# -------------------------
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var walk_sound: AudioStreamPlayer2D = $WalkSound
@onready var jump_grunt: AudioStreamPlayer2D = $JumpGrunt
@onready var land_sound: AudioStreamPlayer2D = $LandSound
@onready var hurt_sound: AudioStreamPlayer2D = $Hurt
@onready var block_sound: AudioStreamPlayer2D = $Block

# -------------------------
# READY
# -------------------------
func _ready():
	add_to_group("player")
	if anim:
		_normal_scale = anim.scale
		anim.play("idle")
		if not anim.animation_finished.is_connected(_on_anim_animation_finished):
			anim.animation_finished.connect(_on_anim_animation_finished)

# -------------------------
# MAIN LOOP
# -------------------------
func _physics_process(delta: float):
	if controls_enabled:
		_update_camera_shake(delta)
		_update_camera_follow(delta)

	if not controls_enabled or not player_alive:
		velocity.x = 0
		move_and_slide() 
		return
		
	_update_camera_shake(delta)
	_update_camera_follow(delta)

	_apply_gravity(delta)

	if _hurt:
		_process_hurt(delta)
	else:
		_shielding = Input.is_action_pressed(shield_action) and not _attacking
		_handle_attack_input()
		_handle_movement()
		_handle_jump()
		_handle_letter_input()

	move_and_slide()
	_update_animation()
	enemy_attack()
	_check_landing()
	_update_dust()
	_check_void_fall()

# -------------------------
# MOVEMENT FUNCTIONS
# -------------------------
func _handle_movement():
	var dir := Input.get_action_strength("Right") - Input.get_action_strength("Left")
	var move_speed := speed * (shield_speed_mult if _shielding else 1.0)
	
	if not _hurt:
		velocity.x = dir * move_speed
	
	if abs(velocity.x) > 1:
		anim.flip_h = velocity.x < 0

func _handle_jump():
	if Input.is_action_just_pressed("Up") and is_on_floor() and not _hurt:
		velocity.y = jump_force
		jump_grunt.play()

func _apply_gravity(delta: float):
	if not is_on_floor() or _hurt:
		velocity.y += gravity * delta

func _handle_attack_input():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _attacking and not _shielding and not _hurt:
		_attacking = true
		Global.player_current_attack = true 
		anim.play("attack")
		hit_sound.play()
		
		$Player_hitbox.monitoring = true

# -------------------------
# LETTER PICKUP INPUT
# -------------------------
func _handle_letter_input():
	if current_letter and Input.is_action_just_pressed("interact"):
		current_letter.pickup()

# -------------------------
# ANIMATION
# -------------------------
func _update_animation():
	if not anim: return
	
	if _hurt:
		walk_sound.stop()
		anim.play("hurt")
		return
	
	if _attacking:
		walk_sound.stop()
		return

	if _shielding and is_on_floor():
		if abs(velocity.x) > 1:
			anim.play("shield")        # Kustas ar vairogu
		else:
			anim.play("shieldNoWalk")  # Stāv uz vietas ar vairogu
		return

	if not is_on_floor():
		if velocity.y < 0:
			anim.play("jump")
		else:
			anim.play("fall")
		return

	if abs(velocity.x) > 1:
		anim.play("walk")
		if not walk_sound.playing:
			walk_sound.play()
	else:
		if not is_on_floor() or abs(velocity.x) <= 1:
			anim.play("idle") # Or "fall"/"jump" depending on your logic
		
		# STOP SOUND IF STANDING STILL OR IN AIR
		walk_sound.stop()

func _on_anim_animation_finished():
	if anim.animation == "attack":
		_attacking = false
		Global.player_current_attack = false
		
		$Player_hitbox.monitoring = false

# -------------------------
# COMBAT & DAMAGE
# -------------------------
func enemy_attack():
	
	if enemy_inattack_range and enemy_attack_cooldown and not _hurt and player_alive:
		if current_enemy and current_enemy.is_harmful: 
			# --- ADD THIS CHECK HERE ---
			if _shielding:
				if not block_sound.playing:
					block_sound.play()
					# Optional: Add a tiny camera shake for feedback
					start_camera_shake(2.0)
				return 
			
			enemy_attack_cooldown = false
			hurt_and_reset(last_enemy_hit_position)
			get_tree().create_timer(1.2).timeout.connect(func(): enemy_attack_cooldown = true)

func hurt_and_reset(from_x: float):
	if _hurt or not player_alive:
		return
	
	hurt_sound.play()
	start_camera_shake(shake_strength)
	Global.lose_life(1)
	
	if Global.lives <= 0:
		die()
		return
	
	_hurt = true
	_hurt_timer = hurt_fall_time
	_attacking = false
	_shielding = false
	
	var dir = -1 if global_position.x > from_x else 1
	velocity.x = dir * hurt_push_x
	velocity.y = hurt_knockup
	
	if anim.sprite_frames.has_animation("hurt"):
		anim.play("hurt")
		
	_start_throb()

func _process_hurt(delta: float):
	_hurt_timer -= delta

	var knockback_friction := 100
	if velocity.x > 0:
		velocity.x = max(velocity.x - knockback_friction * delta, 0)
	elif velocity.x < 0:
		velocity.x = min(velocity.x + knockback_friction * delta, 0)

	velocity.y += gravity * delta
	move_and_slide()

	if _hurt_timer <= 0 and is_on_floor():
		_hurt = false
		anim.play("idle")
		anim.scale = _normal_scale

# -------------------------
# DEATH
# -------------------------
func die():
	player_alive = false
	start_camera_shake(25.0)
	Global.restart_current_level()

# -------------------------
# EFFECTS
# -------------------------
func start_camera_shake(amount: float = shake_strength):
	_shake_amount = amount

func _update_camera_shake(delta: float):
	if not cam: return
	if _shake_amount > 0:
		_noise_time += delta * shake_noise_speed
		cam.offset = Vector2(sin(_noise_time), cos(_noise_time * 1.3)) * _shake_amount
		_shake_amount = lerp(_shake_amount, 0.0, shake_decay * delta)
	else:
		cam.offset = Vector2.ZERO

func _update_camera_follow(delta: float):
	if not cam:
		return
	
	var target = 0.0
	
	if abs(velocity.x) > 10:
		target = sign(velocity.x) * look_ahead_distance
	
	_look_ahead = lerp(_look_ahead, target, look_ahead_speed * delta)
	
	cam.offset.x = _look_ahead

func _check_landing():
	if not _was_on_floor and is_on_floor():
		land_sound.play()
		
		if landing_dust:
			landing_dust.restart()
			
		# Tikko piezemējās
		if velocity.y > landing_velocity_threshold:
			var strength = clamp(velocity.y / 180.0, 0, landing_shake_strength)
			start_camera_shake(strength)
	
	_was_on_floor = is_on_floor()
		
func _start_throb():
	var tween = create_tween()
	tween.tween_property(anim, "scale", _normal_scale * hurt_throb_scale, hurt_throb_time)
	tween.tween_property(anim, "scale", _normal_scale, hurt_throb_time)

# -------------------------
# SIGNALS
# -------------------------
func _on_player_hitbox_body_entered(body):
	if _attacking and body.has_method("hit"):
		body.hit()
		return # Stop here so we don't trigger enemy logic on a barrel
		
		
	if body.has_method("take_damage") and _attacking:
		body.take_damage()
		return 
	
	if body.has_method("enemy"): 
		enemy_inattack_range = true
		current_enemy = body # Store the reference!
		last_enemy_hit_position = body.global_position.x

	# Letter detection
	if body.has_method("letter"):
		current_letter = body
		if body.has_node("Popup"):
			body.get_node("Popup").visible = true
			
	if body.is_in_group("door"):
# Check if the door is locked (you need to make sure your Door scene is in the "door" group)
# and check the Global variable for the key
		if not Global.has_key:
			door_label.text = "I need a key first"
			door_label.visible = true
		else:
			# If they have the key, you might want to show a different prompt or nothing
			door_label.text = "Press E to Enter" 
			door_label.visible = true

# -------------------------
# LETTER PICKUP
# -------------------------
func show_letter_detail():
	var letter_ui = preload("res://letter_close_up.tscn").instantiate()
	get_tree().current_scene.add_child(letter_ui)
	
func pickup_letter():
	if current_letter and current_letter.has_node("Popup"):
		current_letter.get_node("Popup").visible = false
	current_letter = null
	show_letter_detail()
	
# -------------------------
# DUST
# -------------------------

func _update_dust():
	if not dust:
		return

	var moving = is_on_floor() and abs(velocity.x) > 20

	var target_amount := 20.0 if moving else 0.0
	dust.amount = max(1, int(move_toward(dust.amount, target_amount, 2.0)))
	dust.emitting = dust.amount > 1

	if moving:
		var mat := dust.process_material
		if mat:
			var dir = sign(velocity.x)

			dust.position.x = -dir * 10
			mat.direction = Vector3(-dir, -0.3, 0)

			mat.spread = 20.0
			mat.initial_velocity_min = 20.0
			mat.initial_velocity_max = 40.0
			mat.gravity = Vector3(0, 150, 0)

		
func _check_void_fall():
	if global_position.y > void_y_level and player_alive:
		die()

func show_door_cutscene(door_pos: Vector2) -> void:
	if not cam: return
	
	var original_zoom = cam.zoom
	var target_zoom = Vector2(1.4, 1.4) 
	var offset_to_door = door_pos - global_position
	
	await get_tree().create_timer(0.5).timeout
	
	# --- 1. CAMERA MOVES TO DOOR ---
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cam, "offset", offset_to_door, 1.5)
	tween.tween_property(cam, "zoom", target_zoom, 1.5)
	
	await tween.finished
	
	# --- 2. TRIGGER DOOR ANIMATION ---
	# We search for the door at that position to play the animation
	for door in get_tree().get_nodes_in_group("door"):
		if door.global_position.distance_to(door_pos) < 10:
			if door.has_method("play_open_animation"):
				door.play_open_animation() # Call the new function we'll add below
	
	# Pause so player can see the door opening
	await get_tree().create_timer(1.5).timeout
	
	# --- 3. CAMERA RETURNS ---
	var back_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	back_tween.tween_property(cam, "offset", Vector2.ZERO, 1.0)
	back_tween.tween_property(cam, "zoom", original_zoom, 1.0)
	
	await back_tween.finished
