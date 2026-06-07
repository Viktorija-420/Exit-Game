extends Area2D

@export var speed: float = 250.0
@export var damage: int = 1

@export_group("Arc & Gravity")
@export var potion_gravity: float = 700.0      
@export var initial_throw_force: float = -250.0 

var velocity_y: float = 0.0
var direction: int = 1
var shooter: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var splash_particles: CPUParticles2D = $SplashParticles
@onready var break_sound: AudioStreamPlayer2D = $Break

func set_shooter(node: Node2D):
	shooter = node

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
	# Ignorējam sadursmes ar skeletu, kurš meta šo poti
	if body == shooter:
		return

	if body.is_in_group("player"):
		# Nododam bojājumu skaitu un potes atrašanās vietu knockback aprēķinam
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position.x)
		elif body.has_method("hit"):
			body.hit()
		elif "health" in body:
			body.health -= damage
			
		_shatter_potion()
	
	elif not body.is_in_group("enemy"):
		_shatter_potion()

func _shatter_potion():
	if splash_particles:
		var global_pos = splash_particles.global_position
		remove_child(splash_particles)
		get_parent().add_child(splash_particles)
		splash_particles.global_position = global_pos
		splash_particles.emitting = true
		get_tree().create_timer(splash_particles.lifetime).timeout.connect(splash_particles.queue_free)
	
	# Atskaņojam saplīšanas skaņu pirms objekta atbrīvošanas (free)
	if break_sound:
		break_sound.reparent(get_parent())
		break_sound.play()
		get_tree().create_timer(break_sound.stream.get_length()).timeout.connect(break_sound.queue_free)
	
	queue_free()
