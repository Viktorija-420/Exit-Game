extends CharacterBody2D

@export var speed = 160
@export var death_gravity = 1000.0

@onready var squeak: AudioStreamPlayer2D = $Squeak

var player = null
var _is_bursting = false
var _hover_offset = Vector2.ZERO
var _time_passed = 0.0
var _is_dead = false

# Cik ilgi pēc parādīšanās sikspārnis ir neievainojams (lai grūdiens
# neizsauktu tūlītēju pārklāšanos ar spēlētāja hitbox, pirms sikspārnis aizlido)
@export var spawn_grace_period: float = 0.3
var _grace_timer: float = 0.0

func _ready():
	scale = Vector2(0.2, 0.2)
	player = get_tree().get_first_node_in_group("player")
	_hover_offset = Vector2(randf_range(-40, 40), randf_range(-50, -10))
	_grace_timer = spawn_grace_period

func apply_burst(burst_vel: Vector2):
	velocity = burst_vel
	_is_bursting = true
	await get_tree().create_timer(0.4).timeout
	_is_bursting = false

func _physics_process(delta):
	if player and not is_instance_valid(player):
		player = null
		return
	# Skaita uz leju žēlastības periodu
	if _grace_timer > 0:
		_grace_timer -= delta

	if _is_dead:
		if not is_on_floor():
			velocity.y += death_gravity * delta
		else:
			velocity.y = 0
			velocity.x = move_toward(velocity.x, 0, 500 * delta)
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

# Izauc spēlētāja hitbox ar kreiso klikšķi — viens sitiens nogalina
func take_damage():
	if _is_dead:
		return

	squeak.play()
	_is_dead = true

	# Pārtrauc sadursmes ar spēlētāju, bet saglabā sadursmi ar grīdu
	collision_layer = 0
	collision_mask = 1

	if $Anim:
		$Anim.stop()
		$Anim.z_index = -1

	modulate = Color.DARK_GRAY
	velocity = Vector2(randf_range(-80, 80), -250)
	rotation = PI

# Ļauj spēlētāja skriptam identificēt šo kā sikspārni / mazo pretinieku
func is_bat(): return true
