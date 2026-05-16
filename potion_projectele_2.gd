extends Area2D

@export var speed: float = 250.0
@export var slowness_amount: float = 0.5   
@export var slow_duration: float = 3.0     

@export_group("Arc & Gravity")
@export var potion_gravity: float = 700.0      
@export var initial_throw_force: float = -250.0 

# Track vertical movement velocity
var velocity_y: float = 0.0

# This variable is set dynamically by the skeleton when it instantiates the scene!
var direction: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var splash_particles: CPUParticles2D = $SplashParticles

func _ready():
	velocity_y = initial_throw_force
	
	if sprite:
		sprite.flip_h = (direction == -1)
		
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(4.0).timeout.connect(queue_free)

func _physics_process(delta: float):
	velocity_y += potion_gravity * delta
	global_position.x += direction * speed * delta
	global_position.y += velocity_y * delta

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		_apply_slowness_effect(body)
		_shatter_potion()
		
	elif not body.is_in_group("enemy"):
		_shatter_potion()

func _apply_slowness_effect(player: Node2D):
	if "speed" in player:
		var original_speed = player.speed
		player.speed = original_speed * slowness_amount
		
		if player.has_node("Sprite2D"):
			player.get_node("Sprite2D").modulate = Color(0.4, 0.6, 1.0, 1.0)
		elif player.has_node("Anim"):
			player.get_node("Anim").modulate = Color(0.4, 0.6, 1.0, 1.0)
		
		# Hide bottle visuals, turn off collision, and stop processing physics loop
		set_physics_process(false)
		visible = false
		set_deferred("monitoring", false)
		
		await get_tree().create_timer(slow_duration).timeout
		
		player.speed = original_speed
		if player.has_node("Sprite2D"):
			player.get_node("Sprite2D").modulate = Color.WHITE
		elif player.has_node("Anim"):
			player.get_node("Anim").modulate = Color.WHITE
			
		# Potion object cleans itself up here fully once the debuff timer completes
		queue_free()

func _shatter_potion():
	# Run splash effect processing
	if splash_particles:
		var global_pos = splash_particles.global_position
		remove_child(splash_particles)
		get_parent().add_child(splash_particles)
		splash_particles.global_position = global_pos
		
		splash_particles.emitting = true
		get_tree().create_timer(splash_particles.lifetime).timeout.connect(splash_particles.queue_free)
		
	# If this hit a wall/floor, delete it right away. 
	# If it hit the player, apply_slowness_effect hides it and deletes it later.
	if visible:
		queue_free()
