extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_force: float = -400.0
@export var gravity: float = 1000.0

var start_pos: Vector2

func _ready() -> void:
	start_pos = global_position

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Left / Right movement
	var direction := Input.get_action_strength("Right") - Input.get_action_strength("Left")
	velocity.x = direction * speed

	# Jump (UP key)
	if Input.is_action_just_pressed("Up") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()

func reset_to_start() -> void:
	global_position = start_pos
	velocity = Vector2.ZERO
