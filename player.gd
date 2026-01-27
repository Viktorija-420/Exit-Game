# Player.gd (attach to Player = CharacterBody2D)
extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_force: float = -400.0
@export var gravity: float = 1000.0

# hurt / reset tuning
@export var hurt_throb_scale: float = 1.18
@export var hurt_throb_time: float = 0.10
@export var hurt_fall_time: float = 0.80
@export var hurt_knockup: float = -220.0
@export var hurt_push_x: float = 120.0
# @export var hurt_push_y: float = -120.0

@onready var anim: AnimatedSprite2D = $Anim

var start_pos: Vector2
var _normal_scale: Vector2

var _hurt: bool = false
var _hurt_timer: float = 0.0

func _ready() -> void:
	start_pos = global_position
	_normal_scale = anim.scale if anim else Vector2.ONE
	if anim:
		anim.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if _hurt:
		_hurt_timer -= delta
		move_and_slide()

		if _hurt_timer <= 0.0 and is_on_floor():
			_finish_hurt_and_reset()
		elif _hurt_timer <= -0.25:
			_finish_hurt_and_reset()
		return

	# ---- normal controls ----
	var dir := Input.get_action_strength("Right") - Input.get_action_strength("Left")
	velocity.x = dir * speed

	if Input.is_action_just_pressed("Up") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()

	# ---- normal animation ----
	if anim:
		if not is_on_floor():
			pass
		elif abs(velocity.x) > 1:
			if anim.animation != "walk":
				anim.play("walk")
			anim.flip_h = velocity.x < 0
		else:
			if anim.animation != "idle":
				anim.play("idle")

# touch spike
func hurt_and_reset(from_x: float = 0.0) -> void:
	if _hurt:
		return

	_hurt = true
	_hurt_timer = hurt_fall_time

	# small knockback + pop up
	var dir_x := 1.0
	if from_x != 0.0:
		dir_x = sign(global_position.x - from_x)
		if dir_x == 0: dir_x = 1.0

	velocity.x = dir_x * hurt_push_x
	velocity.y = hurt_knockup

	# play hurt anim if exists
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("hurt"):
		anim.play("hurt")

	# throb effect (scale up/down quickly)
	_start_throb()

func _start_throb() -> void:
	if not anim:
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	anim.scale = _normal_scale
	tween.tween_property(anim, "scale", _normal_scale * hurt_throb_scale, hurt_throb_time)
	tween.tween_property(anim, "scale", _normal_scale, hurt_throb_time)
	tween.tween_property(anim, "scale", _normal_scale * hurt_throb_scale, hurt_throb_time)
	tween.tween_property(anim, "scale", _normal_scale, hurt_throb_time)

func _finish_hurt_and_reset() -> void:
	_hurt = false
	reset_to_start()

func reset_to_start() -> void:
	global_position = start_pos
	velocity = Vector2.ZERO
	if anim:
		anim.scale = _normal_scale
		anim.play("idle")
