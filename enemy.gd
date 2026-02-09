extends CharacterBody2D

@export var speed: float = 80.0
@export var gravity: float = 900.0
@export var direction: int = 1  # 1 right, -1 left

@export var max_hp: int = 3
@export var invincibility_time: float = 0.10  # prevents multi-hit in one overlap

@onready var anim: Sprite2D = $Anim

var hp: int
var _base_scale: Vector2 = Vector2.ONE
var _invincible: bool = false

func _ready() -> void:
	hp = max_hp
	if anim:
		_base_scale = anim.scale

func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# patrol
	velocity.x = direction * speed
	move_and_slide()

	# flip sprite
	if anim:
		anim.flip_h = velocity.x < 0

	# turn around on wall
	if is_on_wall():
		direction *= -1

func take_damage(amount: int = 1) -> void:
	if _invincible:
		return

	hp -= amount

	# tiny hit feedback (relative to original scale)
	if anim:
		anim.scale = _base_scale * 0.9
		var t := create_tween()
		t.tween_property(anim, "scale", _base_scale, 0.08)

	# brief i-frames so one arrow overlap doesn't hit multiple times
	_invincible = true
	get_tree().create_timer(invincibility_time).timeout.connect(func() -> void:
		_invincible = false
	)

	if hp <= 0:
		queue_free()

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.has_method("hurt_and_reset"):
		body.hurt_and_reset(global_position.x)
