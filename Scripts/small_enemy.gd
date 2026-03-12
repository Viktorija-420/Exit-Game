extends CharacterBody2D

@export var speed = 160 
@export var death_gravity = 1000.0 
var player = null
var _is_bursting = false
var _hover_offset = Vector2.ZERO
var _time_passed = 0.0
var _is_dead = false

func _ready():
	scale = Vector2(0.2, 0.2)
	player = get_tree().get_first_node_in_group("player")
	_hover_offset = Vector2(randf_range(-40, 40), randf_range(-50, -10))

func apply_burst(burst_vel: Vector2):
	velocity = burst_vel
	_is_bursting = true
	await get_tree().create_timer(0.4).timeout
	_is_bursting = false

func _physics_process(delta):
	if _is_dead:
		# Only apply gravity if we aren't already resting on the floor
		if not is_on_floor():
			velocity.y += death_gravity * delta
		else:
			velocity.y = 0
			velocity.x = move_toward(velocity.x, 0, 500 * delta) # Friction on floor
		
		move_and_slide()
		return 
	
	_time_passed += delta
	
	if _is_bursting:
		velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
	elif player:
		var wobble = Vector2(sin(_time_passed * 6) * 15, cos(_time_passed * 4) * 15)
		var target_pos = player.global_position + _hover_offset + wobble
		var direction = (target_pos - global_position).normalized()
		velocity = velocity.move_toward(direction * speed, 1200 * delta)
	
	if $Anim.sprite_frames.has_animation("Attack"):
		$Anim.play("Attack")
	
	$Anim.flip_h = velocity.x < 0
	move_and_slide()

func take_damage():
	if _is_dead: return
	_is_dead = true
	
	# 1. DISABLE PLAYER COLLISION
	# This stops the player from getting stuck. 
	# Layer 0/Mask 0 means it won't collide with anything anymore...
	# HOWEVER, if you want it to still hit the floor, use collision_mask = 1 (or whatever your floor layer is)
	collision_layer = 0
	collision_mask = 1 # Keep this as your TileMap/Floor layer so it doesn't fall through the world
	
	# 2. STOP ANIMATION
	if $Anim:
		$Anim.stop() 
		$Anim.z_index = -1 # Send it behind the player so it doesn't cover the player's feet
	
	# 3. SET VISUALS
	modulate = Color.DARK_GRAY 
	
	# 4. SET INITIAL FALL ARC
	velocity = Vector2(randf_range(-80, 80), -250)
	
	# 5. PHYSICS ROTATION (Optional touch: makes it look dead)
	rotation = PI # Flips the bat upside down

func is_bat(): return true
