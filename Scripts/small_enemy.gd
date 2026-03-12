extends CharacterBody2D

@export var speed = 70 
@export var gravity = 900
@export var lunge_speed = 300.0 
@export var retreat_speed = 150.0
var lives = 1 

var player_chase = false
var player = null
var player_attack_zone = false
var can_take_damage = true 
var _is_jolting = false 
var _is_retreating = false 
var _retreat_dir = 0 # New: Stores which way to run

@onready var hearts_container = $Hearts 
@onready var anim = $Anim

func _ready():
	update_hearts() 
	if not anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.connect(_on_anim_finished)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	
	deal_with_damage()

	if not _is_jolting:
		if _is_retreating:
			# FIX: Force the velocity to stay active during the retreat
			velocity.x = _retreat_dir * retreat_speed
			anim.play("Walk")
			anim.flip_h = velocity.x < 0
		elif player_chase and player:
			var dist = global_position.distance_to(player.global_position)
			
			if dist < 120 and anim.animation != "Attack":
				_lunge_at_player()
			elif anim.animation != "Attack":
				velocity.x = move_toward(velocity.x, 0, speed)
				anim.play("Idle")
				anim.flip_h = (player.global_position.x < global_position.x)
		else:
			_play_standard_idle()
	else:
		velocity.x = move_toward(velocity.x, 0, 500 * delta)

	move_and_slide()

func _play_standard_idle():
	if not _is_retreating:
		velocity.x = move_toward(velocity.x, 0, speed)
		if anim.animation != "Hurt":
			anim.play("Idle")

func _lunge_at_player():
	if not player or _is_retreating: return
	
	anim.play("Attack")
	var dir = sign(player.global_position.x - global_position.x)
	anim.flip_h = dir < 0
	velocity.x = dir * lunge_speed
	velocity.y = -150 

func _on_anim_finished():
	if anim.animation == "Attack":
		_start_retreat()

func _start_retreat():
	if _is_retreating: return
	
	# Determine direction ONCE at the start of the retreat
	if player:
		_retreat_dir = -sign(player.global_position.x - global_position.x)
	else:
		_retreat_dir = 1
		
	_is_retreating = true
	
	# Run away for 0.8 seconds (increased slightly to make it visible)
	await get_tree().create_timer(0.8).timeout
	
	_is_retreating = false
	velocity.x = 0
	anim.play("Idle")

func deal_with_damage():
	if player_attack_zone and Global.player_current_attack and can_take_damage:
		_is_retreating = false 
		lives -= 1 
		update_hearts() 
		_start_damage_cooldown()

func update_hearts():
	if not hearts_container: return
	var heart_sprites = hearts_container.get_children()
	for i in range(heart_sprites.size()):
		heart_sprites[i].visible = i < lives

func _start_damage_cooldown():
	can_take_damage = false
	_is_jolting = true 
	modulate = Color(10, 1, 1) 
	
	var knockback_dir = 1 if player and global_position.x > player.global_position.x else -1
	velocity.x = knockback_dir * 300 
	velocity.y = -250               
	
	if anim.sprite_frames.has_animation("Hurt"):
		anim.play("Hurt")

	await get_tree().create_timer(0.3).timeout
	
	if lives <= 0:
		self.queue_free()
	else:
		modulate = Color(1, 1, 1) 
		_is_jolting = false 
		can_take_damage = true

func enemy(): pass 

# --- SIGNAL CONNECTIONS ---
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): 
		player = body
		player_chase = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		player_chase = false

func _on_enemy_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_attack_zone = true

func _on_enemy_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_attack_zone = false
