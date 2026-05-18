extends CharacterBody2D

# -------------------------
# STATES
# -------------------------
enum State { INTRO, PATROL, CHASE, THROW, DEFENSE }
var current_state: State = State.INTRO

# -------------------------
# VARIABLES & SETTINGS
# -------------------------
@export_group("Movement")
@export var speed: float = 80.0
@export_group("Chase Settings")
@export var chase_speed: float = 140.0     # Running speed when chasing player
@export var defense_speed: float = 110.0    # Speed when fleeing away from player
@export var movement_range: float = 200.0

@export_group("Combat Loop Times")
@export var chase_duration: float = 2.0      # How long it walks toward player before throwing
@export var defense_duration: float = 1.2    # Seconds to spend running away after a throw

@export_group("Projectiles")
@export var potion_1_scene: PackedScene      # Assign first potion scene here
@export_group("Smart Aim Settings")
@export var potion_2_scene: PackedScene      # Assign second potion scene here
@export var aim_prediction_factor: float = 0.3 # Cik agresīvi paredzēt spēlētāja kustību (0.0 = bez prognozes)
@export var base_throw_time: float = 0.6       # Cik sekundes pote pavada gaisā (kontrolē loka augstumu)

var is_harmful: bool = false               # Keep false during intro speech!
var direction: int = -1
var start_x: float
var is_intro_done: bool = false 
var attack_loop_active: bool = false

var target_player: CharacterBody2D = null   # Keeps track of the player node

# -------------------------
# NODES (Salāgots ar attēlu)
# -------------------------
@onready var anim: AnimatedSprite2D = $Anim
@onready var dialogue_label: Label = $DialogueLabel
@onready var enemy_hitbox: Area2D = $skelet_enemy_hitbox
@onready var detection_area: Area2D = $DetArea
@onready var hearts: Node2D = $Hearts_skelet

# -------------------------
# READY
# -------------------------
# Fixed _ready() inside skeleton.gd
func _ready():
	start_x = global_position.x
	if dialogue_label:
		dialogue_label.text = ""
	if anim:
		anim.play("idle_front")
		
	if enemy_hitbox:
		enemy_hitbox.monitoring = false
		enemy_hitbox.monitorable = false

	if detection_area:
		# Added !is_connected checks to prevent duplicate connection crashes
		if not detection_area.body_entered.is_connected(_on_det_area_body_entered):
			detection_area.body_entered.connect(_on_det_area_body_entered)
		if not detection_area.body_exited.is_connected(_on_det_area_body_exited):
			detection_area.body_exited.connect(_on_det_area_body_exited)
		
	if hearts:
		hearts.visible = false
		
# -------------------------
# MAIN LOOP
# -------------------------
func _physics_process(delta: float):
	match current_state:
		State.PATROL:
			velocity.x = direction * speed
			_handle_boss_patrol_boundaries()
			_update_boss_sprite_direction()
			_safely_play_boss_animation("walk")
			move_and_slide()
			
		State.CHASE:
			_handle_boss_chase_logic()
			_update_boss_sprite_direction()
			_safely_play_boss_animation("walk")
			move_and_slide()
			
		State.THROW:
			velocity.x = 0 
			
		State.DEFENSE:
			_handle_boss_defense_logic()
			_update_boss_sprite_direction() 
			_safely_play_boss_animation("walk")
			move_and_slide()
			
		State.INTRO:
			velocity.x = 0

# -------------------------
# CINEMATIC INTRO
# -------------------------
func play_boss_intro() -> void:
	is_intro_done = false
	current_state = State.INTRO
	
	if dialogue_label:
		dialogue_label.text = "Who are you??"
	
	await get_tree().create_timer(2.0).timeout
	if anim:
		_safely_play_boss_animation("idle_side")
		anim.flip_h = true 
		
	if dialogue_label:
		dialogue_label.text = "you know what.."
	
	await get_tree().create_timer(1.8).timeout
	if dialogue_label:
		dialogue_label.text = "I dont care"
	
	await get_tree().create_timer(1.8).timeout
	if dialogue_label:
		dialogue_label.text = "You know there is no exit right?"
	
	await get_tree().create_timer(2.5).timeout
	if dialogue_label:
		dialogue_label.text = "RAAAGHHH!"
	
	_trigger_boss_camera_shake(35.0) 
	
	await get_tree().create_timer(1.5).timeout
	if dialogue_label:
		dialogue_label.text = ""
	
	if hearts:
		hearts.visible = true
	
	is_harmful = true
	if enemy_hitbox:
		enemy_hitbox.monitoring = true
		enemy_hitbox.monitorable = true
		
	is_intro_done = true
	
	if target_player:
		_start_boss_combat_loop()
	else:
		current_state = State.PATROL
		_safely_play_boss_animation("walk")

func _trigger_boss_camera_shake(intensity: float):
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].start_camera_shake(intensity)

# -------------------------
# MOVEMENT AI CALCULATIONS
# -------------------------
func _handle_boss_patrol_boundaries():
	var distance_from_start = global_position.x - start_x
	if direction == 1 and distance_from_start >= (movement_range / 2.0):
		direction = -1
	elif direction == -1 and distance_from_start <= -(movement_range / 2.0):
		direction = 1

func _handle_boss_chase_logic():
	if not target_player: return
	
	var direction_to_player = target_player.global_position.x - global_position.x
	if direction_to_player > 0:
		direction = 1
	elif direction_to_player < 0:
		direction = -1
		
	velocity.x = direction * chase_speed

func _handle_boss_defense_logic():
	if not target_player: return
	direction = 1 if (global_position.x - target_player.global_position.x) > 0 else -1
	velocity.x = direction * defense_speed

func _update_boss_sprite_direction():
	if not anim: return
	anim.flip_h = (direction == 1)

# -------------------------
# PERFECT ORDERED LOOP MECHANIC
# -------------------------
func _start_boss_combat_loop():
	if attack_loop_active: return
	attack_loop_active = true
	
	while target_player and is_intro_done:
		current_state = State.CHASE
		await get_tree().create_timer(chase_duration).timeout
		
		if not target_player or not is_intro_done: break
		
		current_state = State.THROW
		direction = 1 if (target_player.global_position.x - global_position.x) > 0 else -1
		if anim:
			anim.flip_h = (direction == 1)
		
		_safely_play_boss_animation("throw") 
		await get_tree().create_timer(0.35).timeout
		
		if target_player and current_state == State.THROW:
			_spawn_boss_smart_projectile()
			
		await get_tree().create_timer(0.25).timeout
		if not target_player or not is_intro_done: break
		
		current_state = State.DEFENSE
		await get_tree().create_timer(defense_duration).timeout
		
	attack_loop_active = false
	if is_intro_done and not target_player:
		current_state = State.PATROL

# -------------------------
# SMART AIM PROJECTILE SPARK
# -------------------------
func _spawn_boss_smart_projectile():
	var available_projectiles = []
	if potion_1_scene: available_projectiles.append(potion_1_scene)
	if potion_2_scene: available_projectiles.append(potion_2_scene)
	
	if available_projectiles.size() == 0:
		print("Warning: No potions assigned!")
		return
		
	var chosen_scene = available_projectiles[randi() % available_projectiles.size()]
	var projectile = chosen_scene.instantiate()
	
	var spawn_pos = global_position + Vector2(direction * 16, -8)
	projectile.global_position = spawn_pos
	
	var target_pos = target_player.global_position
	if "velocity" in target_player:
		target_pos.x += target_player.velocity.x * aim_prediction_factor
	
	var distance_x = target_pos.x - spawn_pos.x
	var distance_y = target_pos.y - spawn_pos.y
	
	var flight_time = base_throw_time + (abs(distance_x) / 500.0)
	var p_gravity = projectile.get("potion_gravity") if projectile.get("potion_gravity") != null else 700.0
	
	var calculated_velocity_y = (distance_y - (0.5 * p_gravity * flight_time * flight_time)) / flight_time
	var calculated_speed = abs(distance_x / flight_time)
	
	projectile.direction = 1 if distance_x > 0 else -1
	projectile.speed = calculated_speed
	projectile.initial_throw_force = calculated_velocity_y
	
	if "velocity_y" in projectile:
		projectile.velocity_y = calculated_velocity_y
		
	get_parent().add_child(projectile)

# -------------------------
# SAFE ANIMATION HANDLER
# -------------------------
func _safely_play_boss_animation(anim_name: String):
	if not anim: return
	if current_state == State.THROW and anim_name != "throw" and anim_name != "Throw":
		return
	if anim.animation == anim_name:
		return
	
	if not anim.sprite_frames.has_animation(anim_name):
		var capitalized = anim_name.capitalize()
		if anim.sprite_frames.has_animation(capitalized):
			anim.play(capitalized)
			return
		elif anim.sprite_frames.has_animation(anim_name.to_upper()):
			anim.play(anim_name.to_upper())
			return
		else:
			print("Error: Animation '" + anim_name + "' missing on AnimatedSprite2D!")
			return

	anim.play(anim_name)

# -------------------------
# DETECTION SIGNALS (Pārsaukti)
# -------------------------
func _on_det_area_body_entered(body: Node2D):
	if body.is_in_group("player"):
		target_player = body
		if is_intro_done:
			_start_boss_combat_loop()

func _on_det_area_body_exited(body: Node2D):
	if body == target_player:
		target_player = null
		if current_state != State.INTRO:
			current_state = State.PATROL
			start_x = global_position.x 

# -------------------------
# INTERACTION FALLBACKS
# -------------------------
func boss_enemy():
	return true

func boss_hit():
	if current_state != State.INTRO:
		print("Skeleton boss took a hit!")
