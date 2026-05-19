extends CharacterBody2D

# -------------------------
# STATES
# -------------------------
enum State { INTRO, PATROL, CHASE, THROW, DEFENSE, RETREAT, STATIONARY_PHASE, FINAL_PHASE }
var current_state: State = State.INTRO

# -------------------------
# VARIABLES & SETTINGS
# -------------------------
@export_group("Stats & Health")
@export var max_health: int = 9
var current_health: int = max_health
var can_take_damage: bool = true
var _is_jolting: bool = false

@export_group("Movement")
@export var speed: float = 80.0
@export_group("Chase Settings")
@export var chase_speed: float = 140.0
@export_group("Defense Settings")
@export var defense_speed: float = 110.0
@export_group("Movement Boundaries")
@export var movement_range: float = 200.0

@export_group("Backflip Jump Settings")
@export var backflip_speed: float = 280.0
@export_group("Backflip Jump Settings")
@export var backflip_jump_force: float = -420.0
@export_group("Backflip Jump Settings")
@export var gravity_scale: float = 980.0
@export_group("Defense Settings")
@export var close_attack_threshold: float = 55.0

@export_group("Combat Loop Times")
@export var chase_duration: float = 2.0
@export_group("Defense Settings")
@export var defense_duration: float = 1.2

@export_group("Projectiles")
@export var potion_1_scene: PackedScene
@export var potion_2_scene: PackedScene

@export_group("Smart Aim Settings")
@export var aim_prediction_factor: float = 0.5
@export_group("Smart Aim Settings")
@export var base_throw_time: float = 0.6
@export_range(0.0, 1.0) var double_throw_chance: float = 0.4
@export_group("Smart Aim Settings")
@export var double_throw_spread: float = 60.0

@export_group("Phase 2 Settings")
@export var phase_trigger_health: int = 5
@export_group("Phase 2 Locations")
@export var phase_left_position: Vector2 = Vector2(101, 421)
@export_group("Phase 2 Locations")
@export var phase_right_position: Vector2 = Vector2(1069, 428)
@export_group("Phase 2 Settings")
@export var phase_move_speed: float = 380.0
@export_group("Phase 2 Settings")
@export var phase_throw_cooldown: float = 0.45

# Phase 2 camera zoom settings
@export_group("Phase 2 Camera")
@export var phase_2_zoom_out: Vector2 = Vector2(0.7, 0.7)
@export var phase_2_zoom_speed: float = 2.5
@export var phase_2_camera_offset: Vector2 = Vector2.ZERO

# Final Phase (health <= 2)
@export_group("Final Phase")
@export var ghost_enemy_scene: PackedScene
@export var final_center_position: Vector2 = Vector2(585, 420)   # middle of the map
var is_final_phase_triggered: bool = false
var is_final_phase_active: bool = false
var spawned_ghosts: Array = []
var ghosts_alive: int = 0
var final_phase_ghosts_defeated: bool = false

# Key drop
@export_group("Key Drop")
@export var key_scene: PackedScene   # Assign the key scene in the inspector
var key_dropped: bool = false        # Prevent multiple drops

var is_harmful: bool = false
var direction: int = -1
var start_x: float
var is_intro_done: bool = false
var attack_loop_active: bool = false
var _skip_intro: bool = false

# Phase 2 tracking variables
var is_in_stationary_phase: bool = false
var current_phase_side: String = "left"
var hit_received_during_phase: bool = false

# Phase 2 camera tracking
var _phase2_camera_anchor: Node2D = null
var _phase2_zoom_tween: Tween = null
var _player_camera: Camera2D = null

var target_player: CharacterBody2D = null
var boss_camera: Camera2D = null

# -------------------------
# NODES
# -------------------------
@onready var anim: AnimatedSprite2D = $Anim
@onready var dialogue_label: Label = $DialogueLabel
@onready var enemy_hitbox: Area2D = $skelet_enemy_hitbox
@onready var detection_area: Area2D = $DetArea
@onready var hearts: Node2D = $Hearts_skelet

# -------------------------
# READY
# -------------------------
func _ready():
	start_x = global_position.x
	current_health = max_health
	update_hearts()

	_setup_internal_boss_camera()

	if dialogue_label:
		dialogue_label.text = ""
	if anim:
		anim.play("idle_front")

	if enemy_hitbox:
		enemy_hitbox.monitoring = false
		enemy_hitbox.monitorable = false
		if not enemy_hitbox.area_entered.is_connected(_on_enemy_hitbox_area_entered):
			enemy_hitbox.area_entered.connect(_on_enemy_hitbox_area_entered)

	if detection_area:
		if not detection_area.body_entered.is_connected(_on_det_area_body_entered):
			detection_area.body_entered.connect(_on_det_area_body_entered)
		if not detection_area.body_exited.is_connected(_on_det_area_body_exited):
			detection_area.body_exited.connect(_on_det_area_body_exited)

	if hearts:
		hearts.visible = false

# -------------------------
# COMPONENT SETUP
# -------------------------
func _setup_internal_boss_camera():
	boss_camera = Camera2D.new()
	boss_camera.enabled = true
	boss_camera.position_smoothing_enabled = true
	boss_camera.position_smoothing_speed = 6.5
	add_child(boss_camera)

func _setup_phase2_camera_anchor():
	if _phase2_camera_anchor and is_instance_valid(_phase2_camera_anchor):
		return
	_phase2_camera_anchor = Node2D.new()
	_phase2_camera_anchor.name = "Phase2CameraAnchor"
	get_parent().add_child(_phase2_camera_anchor)

func _teardown_phase2_camera_anchor():
	if _phase2_camera_anchor and is_instance_valid(_phase2_camera_anchor):
		_phase2_camera_anchor.queue_free()
		_phase2_camera_anchor = null

# -------------------------
# INPUT TRACKING
# -------------------------
func _unhandled_input(event: InputEvent) -> void:
	if current_state == State.INTRO and not is_intro_done:
		if event.is_action_pressed("ui_accept"):
			_skip_intro = true
			get_viewport().set_input_as_handled()

# -------------------------
# MAIN LOOP
# -------------------------
func _physics_process(delta: float):
	if not is_on_floor() and current_state != State.STATIONARY_PHASE and current_state != State.FINAL_PHASE:
		velocity.y += gravity_scale * delta

	if _is_jolting:
		velocity.x = move_toward(velocity.x, 0, 800 * delta)
		move_and_slide()
		return

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
			if target_player:
				var dir_to_player = 1 if (target_player.global_position.x - global_position.x) > 0 else -1
				direction = dir_to_player
				velocity.x = direction * (speed * 0.6)
			else:
				velocity.x = move_toward(velocity.x, 0, 400 * delta)

			_update_boss_sprite_direction()
			move_and_slide()

		State.DEFENSE:
			_handle_boss_defense_logic()
			_update_boss_sprite_direction()
			_safely_play_boss_animation("walk")
			move_and_slide()

		State.RETREAT:
			if is_on_floor():
				velocity.x = move_toward(velocity.x, 0, 800 * delta)
			if is_on_wall():
				velocity.x = 0
			move_and_slide()

		State.INTRO, State.STATIONARY_PHASE, State.FINAL_PHASE:
			# No movement during these states
			pass

# -------------------------
# CINEMATIC INTRO
# -------------------------
func play_boss_intro() -> void:
	is_intro_done = false
	_skip_intro = false
	current_state = State.INTRO

	if dialogue_label:
		dialogue_label.text = "Who are you??"
	if await _wait_or_skip(2.0): return

	if anim:
		_safely_play_boss_animation("idle_side")
		anim.flip_h = true
	if dialogue_label:
		dialogue_label.text = "you know what.."
	if await _wait_or_skip(1.8): return

	if dialogue_label:
		dialogue_label.text = "I dont care"
	if await _wait_or_skip(1.8): return

	if dialogue_label:
		dialogue_label.text = "You know there is no exit right?"
	if await _wait_or_skip(2.5): return

	if dialogue_label:
		dialogue_label.text = "RAAAGHHH!"
	_trigger_boss_camera_shake(35.0)
	if await _wait_or_skip(1.5): return

	_complete_intro()

func _wait_or_skip(duration: float) -> bool:
	var elapsed = 0.0
	while elapsed < duration:
		if _skip_intro:
			_complete_intro()
			return true
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	return false

func _complete_intro() -> void:
	if dialogue_label:
		dialogue_label.text = ""

	update_hearts()
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
# MOVEMENT AI
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
	if abs(direction_to_player) < 10.0:
		velocity.x = move_toward(velocity.x, 0, 400 * get_physics_process_delta_time())
		return
	direction = 1 if direction_to_player > 0 else -1
	velocity.x = direction * chase_speed

func _handle_boss_defense_logic():
	if not target_player: return
	direction = 1 if (global_position.x - target_player.global_position.x) > 0 else -1
	velocity.x = direction * defense_speed

func _update_boss_sprite_direction():
	if not anim or _is_jolting or current_state == State.RETREAT or current_state == State.STATIONARY_PHASE or current_state == State.FINAL_PHASE:
		return
	anim.flip_h = (direction == 1)

# -------------------------
# PHASE 2 CAMERA HELPERS
# -------------------------
func _enter_phase2_camera_mode():
	_setup_phase2_camera_anchor()
	if not _phase2_camera_anchor or not is_instance_valid(_phase2_camera_anchor):
		return

	var mid_x = (phase_left_position.x + phase_right_position.x) / 2.0
	var mid_y = (phase_left_position.y + phase_right_position.y) / 2.0
	_phase2_camera_anchor.global_position = Vector2(mid_x, mid_y) + phase_2_camera_offset

	if target_player:
		var player_cam = target_player.get_node_or_null("Camera2D")
		if player_cam and player_cam is Camera2D:
			_player_camera = player_cam
			_player_camera.enabled = false

	if boss_camera and boss_camera.is_inside_tree():
		boss_camera.reparent(_phase2_camera_anchor, true)
		boss_camera.global_position = _phase2_camera_anchor.global_position
		boss_camera.position = Vector2.ZERO

	if boss_camera:
		boss_camera.make_current()
		if _phase2_zoom_tween and _phase2_zoom_tween.is_valid():
			_phase2_zoom_tween.kill()
		_phase2_zoom_tween = create_tween()
		_phase2_zoom_tween.tween_property(boss_camera, "zoom", phase_2_zoom_out, 1.0 / phase_2_zoom_speed)

func _exit_phase2_camera_mode():
	if boss_camera and is_instance_valid(boss_camera):
		if _phase2_zoom_tween and _phase2_zoom_tween.is_valid():
			_phase2_zoom_tween.kill()
		_phase2_zoom_tween = create_tween()
		_phase2_zoom_tween.tween_property(boss_camera, "zoom", Vector2(1.0, 1.0), 1.0 / phase_2_zoom_speed)

		if boss_camera.get_parent() != self:
			boss_camera.reparent(self, false)
			boss_camera.position = Vector2.ZERO

	if _player_camera and is_instance_valid(_player_camera):
		_player_camera.enabled = true
		_player_camera = null

	_teardown_phase2_camera_anchor()

# -------------------------
# PLAYER FREEZE HELPERS (Phase 2 jumps & Final Phase)
# -------------------------
func _freeze_player_movement(freeze: bool):
	if not target_player:
		return
	if freeze:
		target_player.set_physics_process(false)
		target_player.set_process_unhandled_input(false)
		target_player.velocity = Vector2.ZERO
	else:
		target_player.set_physics_process(true)
		target_player.set_process_unhandled_input(true)

# -------------------------
# SAFE AWAIT HELPERS
# -------------------------
func _safe_await_frame() -> bool:
	if not is_inside_tree():
		return false
	await get_tree().process_frame
	return is_inside_tree()

func _safe_await_timer(duration: float) -> bool:
	if not is_inside_tree():
		return false
	await get_tree().create_timer(duration).timeout
	return is_inside_tree()

# -------------------------
# PHASE 2: STATIONARY POSITIONING & BARRAGE
# -------------------------
func _run_stationary_potion_phase():
	if is_in_stationary_phase:
		return

	is_in_stationary_phase = true
	current_state = State.STATIONARY_PHASE
	velocity = Vector2.ZERO

	if not is_inside_tree():
		await ready

	_enter_phase2_camera_mode()

	var original_hearts_position: Vector2 = hearts.position if hearts else Vector2.ZERO

	while current_health <= phase_trigger_health and current_health > 0 and not is_final_phase_triggered:
		var destination = phase_left_position if current_phase_side == "left" else phase_right_position
		
		_safely_play_boss_animation("jump")
		if anim:
			anim.flip_h = (destination.x > global_position.x)

		_freeze_player_movement(true)

		var start_pos = global_position
		var total_distance = start_pos.distance_to(destination)

		while global_position.distance_to(destination) > 5.0:
			if current_health <= 0 or _is_jolting or is_final_phase_triggered: break
			if not await _safe_await_frame(): return

			if anim:
				anim.flip_h = (destination.x > global_position.x)

			global_position = global_position.move_toward(destination, phase_move_speed * get_process_delta_time())

			var current_dist = global_position.distance_to(destination)
			if total_distance > 0:
				var arc_height = sin((current_dist / total_distance) * PI) * 120.0
				anim.position.y = -arc_height
				if hearts:
					hearts.position.y = original_hearts_position.y - arc_height

		if anim:
			anim.position = Vector2.ZERO
		if hearts:
			hearts.position = original_hearts_position

		global_position = destination

		_freeze_player_movement(false)

		if current_health <= 0 or is_final_phase_triggered: break

		hit_received_during_phase = false

		while not hit_received_during_phase and current_health <= phase_trigger_health and current_health > 0 and not is_final_phase_triggered:
			if _is_jolting:
				if not await _safe_await_frame(): return
				continue

			if target_player:
				direction = 1 if (target_player.global_position.x - global_position.x) > 0 else -1
				if anim:
					anim.flip_h = (direction == 1)

				_safely_play_boss_animation("throw")
				_spawn_boss_smart_projectile(0.0)

				if randf() < 0.3:
					if not await _safe_await_timer(0.08): return
					_spawn_boss_smart_projectile(double_throw_spread if randf() > 0.5 else -double_throw_spread)

			if not await _safe_await_timer(phase_throw_cooldown): return

			if not hit_received_during_phase and not _is_jolting:
				_safely_play_boss_animation("idle_front")
			if not await _safe_await_frame(): return

		if current_health <= 0 or is_final_phase_triggered: break

	# Camera stays in Phase 2 mode – do NOT exit here
	is_in_stationary_phase = false

	if is_final_phase_triggered:
		# Final phase already handles the rest
		return

	if target_player:
		current_state = State.CHASE
		_start_boss_combat_loop()
	else:
		current_state = State.PATROL

func _restore_default_player_camera_context():
	if target_player:
		target_player.set_physics_process(true)
		target_player.set_process_unhandled_input(true)
		var player_camera = target_player.get_node_or_null("Camera2D")
		if player_camera and player_camera.is_inside_tree():
			player_camera.make_current()

# -------------------------
# PERFECT ORDERED COMBAT LOOP
# -------------------------
func _start_boss_combat_loop():
	if attack_loop_active or is_in_stationary_phase: return
	attack_loop_active = true

	while target_player and is_intro_done and not is_in_stationary_phase and not is_final_phase_triggered:
		await get_tree().process_frame

		if _is_jolting:
			while _is_jolting:
				await get_tree().process_frame
			continue

		if current_health <= phase_trigger_health or is_final_phase_triggered:
			break

		# --- CHASE ---
		current_state = State.CHASE
		var timer = 0.0
		var close_range_triggered = false

		while timer < chase_duration:
			if not target_player or not is_intro_done or current_health <= phase_trigger_health or is_final_phase_triggered: break
			if _is_jolting: break

			var current_dist = abs(target_player.global_position.x - global_position.x)
			if current_dist <= close_attack_threshold:
				close_range_triggered = true
				break

			await get_tree().process_frame
			timer += get_physics_process_delta_time()

		if not target_player or not is_intro_done or current_health <= phase_trigger_health or is_final_phase_triggered: break
		if _is_jolting: continue

		# --- ATTACK ---
		if close_range_triggered:
			current_state = State.RETREAT
			var retreat_direction = 1 if (global_position.x - target_player.global_position.x) > 0 else -1

			var primary_walled = test_move(transform, Vector2(retreat_direction * 20, 0))
			var fallback_walled = test_move(transform, Vector2(-retreat_direction * 20, 0))

			if primary_walled and fallback_walled:
				retreat_direction = 0
			elif primary_walled:
				retreat_direction = -retreat_direction

			if retreat_direction != 0:
				direction = retreat_direction
			if anim:
				anim.flip_h = (direction == -1)

			_safely_play_boss_animation("backflip")
			velocity.x = retreat_direction * backflip_speed
			velocity.y = backflip_jump_force

			await get_tree().create_timer(0.15).timeout

			var air_timer = 0.0
			var max_air_time = 1.2
			while air_timer < max_air_time:
				if _is_jolting or not is_intro_done or current_health <= phase_trigger_health or is_final_phase_triggered: break
				if is_on_floor(): break
				await get_tree().process_frame
				air_timer += get_physics_process_delta_time()

			velocity.x = 0
			if not target_player or not is_intro_done or _is_jolting or current_health <= phase_trigger_health or is_final_phase_triggered: continue

			current_state = State.THROW
			_safely_play_boss_animation("throw")
			await get_tree().create_timer(0.2).timeout

			if target_player and current_state == State.THROW and not _is_jolting:
				_spawn_boss_smart_projectile(0.0)

			await get_tree().create_timer(0.2).timeout

		else:
			current_state = State.THROW
			_safely_play_boss_animation("throw")
			await get_tree().create_timer(0.35).timeout

			if target_player and current_state == State.THROW and not _is_jolting:
				if randf() < double_throw_chance:
					var range_mod = double_throw_spread if randf() > 0.5 else -double_throw_spread
					_spawn_boss_smart_projectile(0.0)
					_spawn_boss_smart_projectile(range_mod)
				else:
					_spawn_boss_smart_projectile(0.0)

			await get_tree().create_timer(0.25).timeout

		if not target_player or not is_intro_done or current_health <= phase_trigger_health or is_final_phase_triggered: break
		if _is_jolting: continue

		# --- DEFENSE ---
		current_state = State.DEFENSE
		var def_timer = 0.0
		while def_timer < defense_duration:
			if _is_jolting or not target_player or current_health <= phase_trigger_health or is_final_phase_triggered: break
			await get_tree().process_frame
			def_timer += get_physics_process_delta_time()

	attack_loop_active = false

	if current_health <= phase_trigger_health and current_health > 0 and is_intro_done and not is_final_phase_triggered:
		_run_stationary_potion_phase()
	elif is_intro_done and not target_player:
		current_state = State.PATROL

# -------------------------
# SMART AIM PROJECTILE (with ceiling clamp)
# -------------------------
func _spawn_boss_smart_projectile(range_modifier: float = 0.0):
	var available_projectiles = []
	if potion_1_scene: available_projectiles.append(potion_1_scene)
	if potion_2_scene: available_projectiles.append(potion_2_scene)

	if available_projectiles.size() == 0:
		return

	var chosen_scene = available_projectiles[randi() % available_projectiles.size()]
	var projectile = chosen_scene.instantiate()

	if projectile.has_method("set_shooter"):
		projectile.set_shooter(self)

	var spawn_pos = global_position + Vector2(direction * 16, -8)
	projectile.global_position = spawn_pos

	var target_pos = global_position + Vector2(direction * 100, 0)
	if target_player:
		target_pos = target_player.global_position
		if "velocity" in target_player:
			target_pos.x += target_player.velocity.x * aim_prediction_factor

	target_pos.x += range_modifier * direction

	var distance_x = target_pos.x - spawn_pos.x
	var distance_y = target_pos.y - spawn_pos.y

	var flight_time = base_throw_time + (abs(distance_x) / 500.0)
	var p_gravity = projectile.get("potion_gravity") if projectile.get("potion_gravity") != null else 700.0

	var calculated_velocity_y = (distance_y - (0.5 * p_gravity * flight_time * flight_time)) / flight_time
	var calculated_speed = abs(distance_x / flight_time)

	const CEILING_Y: float = 75.0
	if calculated_velocity_y < 0.0 and spawn_pos.y > CEILING_Y:
		var max_upward_speed = sqrt(2.0 * p_gravity * (spawn_pos.y - CEILING_Y))
		if -calculated_velocity_y > max_upward_speed:
			calculated_velocity_y = -max_upward_speed

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
	if _is_jolting and anim_name != "hurt" and anim_name != "jump":
		return
	if anim.animation == anim_name: return

	if not anim.sprite_frames.has_animation(anim_name):
		var capitalized = anim_name.capitalize()
		if anim.sprite_frames.has_animation(capitalized):
			anim.play(capitalized)
			return
		elif anim.sprite_frames.has_animation(anim_name.to_upper()):
			anim.play(anim_name.to_upper())
			return
		else:
			return

	anim.play(anim_name)

# -------------------------
# SIGNALS & DETECTION
# -------------------------
func _on_det_area_body_entered(body: Node2D):
	if body.is_in_group("player"):
		target_player = body
		if is_intro_done:
			if current_health <= phase_trigger_health:
				if not is_in_stationary_phase and not is_final_phase_triggered:
					_run_stationary_potion_phase()
			else:
				_start_boss_combat_loop()

func _on_det_area_body_exited(body: Node2D):
	if body == target_player:
		if is_in_stationary_phase or is_final_phase_active:
			return
		target_player = null
		if current_state != State.INTRO and not is_in_stationary_phase:
			current_state = State.PATROL
			start_x = global_position.x

func _on_enemy_hitbox_area_entered(area: Area2D):
	if area.name == "Player_hitbox" and Global.player_current_attack and can_take_damage:
		var player_node = area.get_parent()
		take_damage(1, player_node.global_position.x)

# -------------------------
# DAMAGE & COMBAT LOGIC
# -------------------------
func take_damage(amount: int, from_x: float):
	if current_state == State.INTRO or current_health <= 0 or not can_take_damage:
		return

	current_health -= amount
	update_hearts()

	# Trigger final phase when health becomes 2 or lower
	if current_health <= 2 and not is_final_phase_triggered and is_intro_done:
		_start_final_phase()
		return   # Damage handling stops here, final phase takes over

	if is_in_stationary_phase:
		hit_received_during_phase = true
		current_phase_side = "right" if current_phase_side == "left" else "left"

	_start_damage_cooldown(from_x)

func update_hearts():
	if not hearts: return
	var heart_sprites = hearts.get_children()
	if heart_sprites.size() > 0:
		for i in range(heart_sprites.size()):
			heart_sprites[i].visible = i < current_health
	elif hearts.has_method("update_hearts"):
		hearts.update_hearts(current_health)

func _start_damage_cooldown(from_x: float):
	can_take_damage = false
	_is_jolting = true
	modulate = Color(10, 1, 1)

	var knockback_dir = 1 if global_position.x > from_x else -1
	velocity.x = knockback_dir * 250
	velocity.y = 0

	if anim:
		if anim.sprite_frames.has_animation("hurt"):
			anim.play("hurt")

	await get_tree().create_timer(0.3).timeout

	if current_health <= 0:
		_die()
	else:
		modulate = Color(1, 1, 1)
		_is_jolting = false
		can_take_damage = true

		if not is_in_stationary_phase:
			if current_health <= phase_trigger_health and not is_final_phase_triggered:
				_run_stationary_potion_phase()
			elif not attack_loop_active:
				if target_player:
					current_state = State.CHASE
					_start_boss_combat_loop()
				else:
					current_state = State.PATROL

# -------------------------
# FINAL PHASE (health <= 2)
# -------------------------
func _start_final_phase():
	if is_final_phase_triggered or not is_intro_done:
		return
	is_final_phase_triggered = true
	is_final_phase_active = true
	can_take_damage = false          # Boss cannot be damaged during this sequence
	attack_loop_active = false
	final_phase_ghosts_defeated = false

	# Make player pass through skeleton (like ghosts pass through players)
	if target_player:
		add_collision_exception_with(target_player)

	# Interrupt any ongoing stationary phase, but KEEP the phase‑2 camera active
	is_in_stationary_phase = false

	current_state = State.FINAL_PHASE
	velocity = Vector2.ZERO
	_safely_play_boss_animation("idle_front")

	# Dialogue sequence (camera stays zoomed out)
	await _final_phase_dialogue()
	if not is_inside_tree(): return

	# Jump to the center (player movement frozen during jump)
	_freeze_player_movement(true)
	await _jump_to_position(final_center_position)
	_freeze_player_movement(false)
	if not is_inside_tree(): return

	# Spawn three ghost enemies
	_spawn_ghosts()

	# Boss stays idle, invincible until all ghosts are dead.
	current_state = State.FINAL_PHASE
	_safely_play_boss_animation("idle_front")

func _final_phase_dialogue():
	if not dialogue_label:
		return
	dialogue_label.text = "AHH okey man"
	if not await _safe_await_timer(1.2): return
	dialogue_label.text = "Lets calm down now"
	if not await _safe_await_timer(1.2): return
	dialogue_label.text = "leave me be"
	if not await _safe_await_timer(2.0): return
	dialogue_label.text = "AHAHA NEVERMIND."
	if not await _safe_await_timer(1.2): return
	dialogue_label.text = "THIS WHAT YOU GET"
	if not await _safe_await_timer(1.2): return
	dialogue_label.text = ""

func _jump_to_position(target_pos: Vector2):
	if not is_inside_tree():
		return
	var start_pos = global_position
	var total_distance = start_pos.distance_to(target_pos)
	var original_hearts_position = hearts.position if hearts else Vector2.ZERO

	_safely_play_boss_animation("jump")
	if anim:
		anim.flip_h = (target_pos.x > start_pos.x)

	while global_position.distance_to(target_pos) > 5.0:
		if not await _safe_await_frame(): return
		if anim:
			anim.flip_h = (target_pos.x > global_position.x)
		global_position = global_position.move_toward(target_pos, phase_move_speed * get_process_delta_time())

		var current_dist = global_position.distance_to(target_pos)
		if total_distance > 0:
			var arc_height = sin((current_dist / total_distance) * PI) * 120.0
			anim.position.y = -arc_height
			if hearts:
				hearts.position.y = original_hearts_position.y - arc_height

	if anim:
		anim.position = Vector2.ZERO
	if hearts:
		hearts.position = original_hearts_position
	global_position = target_pos

func _spawn_ghosts():
	if not ghost_enemy_scene:
		print("Ghost enemy scene not assigned!")
		return
	ghosts_alive = 0
	spawned_ghosts.clear()
	var offsets = [Vector2(-60, -20), Vector2(60, -20), Vector2(0, -40)]
	for offset in offsets:
		var ghost = ghost_enemy_scene.instantiate()
		ghost.global_position = global_position + offset
		get_parent().add_child(ghost)
		
		# Ghost should pass through player and skeleton boss
		if target_player:
			ghost.add_collision_exception_with(target_player)
		ghost.add_collision_exception_with(self)
		
		ghosts_alive += 1
		spawned_ghosts.append(ghost)
		if ghost.tree_exited.is_connected(_on_ghost_died):
			ghost.tree_exited.disconnect(_on_ghost_died)
		ghost.tree_exited.connect(_on_ghost_died)

func _on_ghost_died():
	ghosts_alive -= 1
	if ghosts_alive <= 0 and is_final_phase_active and not final_phase_ghosts_defeated:
		await _final_phase_post_ghosts_dialogue()

func _final_phase_post_ghosts_dialogue():
	if not is_inside_tree() or not dialogue_label:
		return
	
	final_phase_ghosts_defeated = true
	
	dialogue_label.text = "Damn youre really wanna get out"
	if not await _safe_await_timer(1.5): return
	
	dialogue_label.text = "Well good luck later on"
	if not await _safe_await_timer(1.5): return
	
	dialogue_label.text = "but please"
	if not await _safe_await_timer(1.0): return
	
	dialogue_label.text = "put me out of my missery now.."
	if not await _safe_await_timer(1.8): return
	
	dialogue_label.text = ""
	
	# Boss becomes vulnerable – player can now land the killing blow
	can_take_damage = true
	
	# Keep the boss idle and invincible otherwise (no movement, no attacks)
	current_state = State.FINAL_PHASE
	_safely_play_boss_animation("idle_front")

# -------------------------
# DEATH
# -------------------------
# -------------------------
# DEATH
# -------------------------
func _die():
	if not is_inside_tree():
		return
	
	print("Skeleton boss defeated!")
	is_intro_done = false
	attack_loop_active = false
	is_in_stationary_phase = false
	is_final_phase_active = false

	for g in spawned_ghosts:
		if is_instance_valid(g) and not g.tree_exited.is_connected(_on_ghost_died):
			g.queue_free()

	_exit_phase2_camera_mode()
	_restore_default_player_camera_context()

	# --- Drop the key (robust version) ---
	if not key_dropped:
		key_dropped = true
		if key_scene == null:
			print("ERROR...")
		else:
			var key = key_scene.instantiate()
			get_tree().root.add_child(key)
			key.global_position = Vector2(595, 88)   # <-- START POSITION
			if key is RigidBody2D:
				key.gravity_scale = 1.0
				key.linear_velocity = Vector2(0, 50)
			else:
				var tween = create_tween()
				tween.tween_property(key, "global_position:y", 463, 1.0)  # <-- END Y & DURATION
				await get_tree().create_timer(0.1).timeout

		# --- Death animation and removal ---
		if anim and anim.sprite_frames.has_animation("dead"):
			anim.play("dead")
			await anim.animation_finished
		else:
			if is_inside_tree():
				await get_tree().create_timer(0.2).timeout

	if is_inside_tree():
		queue_free()
		
		
# -------------------------
# INTERACTION FALLBACKS
# -------------------------
func boss_enemy():
	return true

func boss_hit():
	if current_state != State.INTRO and can_take_damage and not is_final_phase_active:
		take_damage(1, global_position.x - 1.0)
