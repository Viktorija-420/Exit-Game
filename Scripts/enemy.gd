extends CharacterBody2D

# --- SPAWN SETTINGS ---
@export var small_enemy_scene: PackedScene
var _is_attacking = false

# --- MOVEMENT SETTINGS ---
@export var speed = 50
@export var gravity = 900
@export var lunge_speed = 300.0
@export var retreat_speed = 150.0
var lives = 3

# --- STATES ---
var player_chase = false
var player = null
var can_take_damage = true
var _is_jolting = false
var _is_retreating = false
var _retreat_dir = 0

@onready var hearts_container = $Hearts
@onready var anim = $Anim

# --- SOUNDS ---
@onready var enemy_hit_sound: AudioStreamPlayer2D = $EnemyAttack

# is_harmful controls whether touching the player deals damage.
# It is ONLY true during the lunge window so the player is safe at all other times.
var is_harmful: bool = false

func _ready():
	update_hearts()
	if not anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.connect(_on_anim_finished)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	# PRIORITY 1: Taking Damage (Jolting)
	if _is_jolting:
		velocity.x = move_toward(velocity.x, 0, 500 * delta)

	# PRIORITY 2: Attacking (Lunge)
	elif _is_attacking:
		velocity.x = move_toward(velocity.x, 0, 200 * delta)

	# PRIORITY 3: Retreating
	elif _is_retreating:
		velocity.x = _retreat_dir * retreat_speed
		anim.play("Walk")
		anim.flip_h = velocity.x < 0

	# PRIORITY 4: Chasing / Idle
	elif player_chase and player:
		var dist = global_position.distance_to(player.global_position)
		if dist < 120:
			_lunge_at_player()
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			anim.play("Idle")
			anim.flip_h = (player.global_position.x < global_position.x)
	else:
		_play_standard_idle()

	move_and_slide()

func _play_standard_idle():
	if not _is_retreating:
		velocity.x = move_toward(velocity.x, 0, speed)
		if anim.animation != "Hurt":
			anim.play("Idle")

func _lunge_at_player():
	if _is_attacking or _is_retreating or _is_jolting:
		return

	_is_attacking = true
	is_harmful = true          # Only dangerous during the lunge
	anim.play("Attack")
	enemy_hit_sound.play()

	var dir = sign(player.global_position.x - global_position.x)
	anim.flip_h = dir < 0
	velocity.x = dir * lunge_speed
	velocity.y = -150

func _on_anim_finished():
	if anim.animation == "Attack":
		_is_attacking = false
		is_harmful = false     # No longer harmful once the attack animation ends
		_start_retreat()

func _start_retreat():
	if _is_retreating:
		return
	if player:
		_retreat_dir = -sign(player.global_position.x - global_position.x)
	else:
		_retreat_dir = 1
	_is_retreating = true
	await get_tree().create_timer(0.8).timeout
	_is_retreating = false
	velocity.x = 0
	anim.play("Idle")

# Called by the player's hitbox — left-click attack
func take_damage(_amount: int, _from_x: float):
	if not can_take_damage:
		return

	lives -= 1
	update_hearts()
	_start_damage_cooldown()

func update_hearts():
	if not hearts_container:
		return
	var heart_sprites = hearts_container.get_children()
	for i in range(heart_sprites.size()):
		heart_sprites[i].visible = i < lives

func _start_damage_cooldown():
	can_take_damage = false
	_is_jolting = true
	is_harmful = false         # Can't hurt the player while being knocked back
	modulate = Color(10, 1, 1)

	var knockback_dir = 1 if player and global_position.x > player.global_position.x else -1
	velocity.x = knockback_dir * 300
	velocity.y = -250

	if anim.sprite_frames.has_animation("Hurt"):
		anim.play("Hurt")

	await get_tree().create_timer(0.3).timeout

	if lives <= 0:
		spawn_minions()
		queue_free()
	else:
		modulate = Color(1, 1, 1)
		_is_jolting = false
		can_take_damage = true

func spawn_minions():
	if small_enemy_scene == null:
		return

	var spawn_origin = global_position + Vector2(0, -25)
	var num_bats = 4

	for i in range(num_bats):
		var bat = small_enemy_scene.instantiate()
		bat.global_position = spawn_origin

		var angle = i * (PI * 2 / num_bats)
		var burst_velocity = Vector2(cos(angle), sin(angle)) * 350.0

		get_tree().root.add_child(bat)

		if bat.has_method("apply_burst"):
			bat.apply_burst(burst_velocity)

# Used by the player's contact-damage system to know this is a big enemy
func enemy(): pass

# -------------------------
# SIGNALS
# -------------------------
func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body
		player_chase = true

func _on_detection_area_body_exited(body):
	if body == player:
		player = null
		player_chase = false

# Enemy's own body hitbox — this tells the PLAYER it is being touched.
# The player's take_damage is called only when is_harmful is true (during lunge).
func _on_enemy_hitbox_body_entered(body):
	if body.is_in_group("player") and is_harmful:
		body.take_damage(1, global_position.x)

func _on_enemy_hitbox_body_exited(_body):
	pass
