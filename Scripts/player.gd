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

# -------------------------
# NODES
# -------------------------
@onready var anim: AnimatedSprite2D = $Anim
@onready var cam: Camera2D = $Camera2D

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

@export_group("Camera Shake")
@export var shake_strength: float = 15.0 
@export var shake_decay: float = 8.0
@export var shake_noise_speed: float = 25.0
var _shake_amount: float = 0.0
var _noise_time: float = 0.0

@export_group("Shield Settings")
@export var shield_action: StringName = &"Shield"
@export var shield_speed_mult: float = 0.55

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
	_update_camera_shake(delta)

	if not controls_enabled or not player_alive:
		return

	_apply_gravity(delta)

	if _hurt:
		_process_hurt(delta)
		return 

	_shielding = Input.is_action_pressed(shield_action) and not _attacking
	_handle_attack_input()
	
	_handle_movement()
	_handle_jump()

	move_and_slide()
	_update_animation()
	enemy_attack()

# -------------------------
# MOVEMENT FUNCTIONS
# -------------------------

func _handle_movement():
	var dir := Input.get_action_strength("Right") - Input.get_action_strength("Left")
	var move_speed := speed * (shield_speed_mult if _shielding else 1.0)
	
	velocity.x = dir * move_speed
	
	if abs(velocity.x) > 1:
		anim.flip_h = velocity.x < 0

func _handle_jump():
	if Input.is_action_just_pressed("Up") and is_on_floor():
		velocity.y = jump_force

func _apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta

func _handle_attack_input():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _attacking and not _shielding:
		_attacking = true
		Global.player_current_attack = true 
		anim.play("attack")

func _update_animation():
	if not anim or _hurt: return
	
	if _attacking:
		return

	if _shielding and is_on_floor():
		anim.play("shield")
		return

	if not is_on_floor():
		return

	if abs(velocity.x) > 1:
		anim.play("walk")
	else:
		anim.play("idle")

func _on_anim_animation_finished():
	if anim.animation == "attack":
		_attacking = false
		Global.player_current_attack = false 

# -------------------------
# COMBAT & DAMAGE
# -------------------------

func enemy_attack():
	if enemy_inattack_range and enemy_attack_cooldown and not _hurt:
		# Double check that we aren't currently attacking (optional, but safer)
		enemy_attack_cooldown = false
		hurt_and_reset(last_enemy_hit_position)
		await get_tree().create_timer(1.2).timeout
		enemy_attack_cooldown = true

func hurt_and_reset(from_x: float):
	if _hurt or not player_alive: return
	
	start_camera_shake(shake_strength)
	Global.lose_life(1)
	
	if Global.lives <= 0:
		die()
		return
		
	_hurt = true
	_hurt_timer = hurt_fall_time
	_attacking = false
	_shielding = false
	
	var dir = 1 if global_position.x > from_x else -1
	velocity.x = dir * hurt_push_x
	velocity.y = hurt_knockup
	
	move_and_slide()
	
	if anim.sprite_frames.has_animation("hurt"): 
		anim.play("hurt")
		
	_start_throb()

func _process_hurt(delta: float):
	_hurt_timer -= delta
	velocity.x = move_toward(velocity.x, 0, 600 * delta)
	move_and_slide()
	
	if _hurt_timer <= 0 and is_on_floor():
		_hurt = false
		anim.play("idle")
		anim.scale = _normal_scale

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

func _start_throb():
	var tween = create_tween()
	tween.tween_property(anim, "scale", _normal_scale * hurt_throb_scale, hurt_throb_time)
	tween.tween_property(anim, "scale", _normal_scale, hurt_throb_time)

# -------------------------
# SIGNALS
# -------------------------

func _on_player_hitbox_body_entered(body):
	# KILL LOGIC FOR BATS (AND OTHER ENEMIES)
	if body.has_method("take_damage") and _attacking:
		body.take_damage()
		return # Stop here so we don't also take damage from the same body
	
	# DAMAGE LOGIC FOR HOSTILE ENEMIES
	if body.has_method("enemy"): 
		enemy_inattack_range = true
		last_enemy_hit_position = body.global_position.x

func _on_player_hitbox_body_exited(body):
	if body.has_method("enemy"): 
		enemy_inattack_range = false

func player(): pass
