extends CharacterBody2D

@onready var fade: ColorRect = get_node_or_null("Fade") as ColorRect

@export var speed: float = 200.0
@export var jump_force: float = -400.0
@export var gravity: float = 1000.0

# hurt / reset tuning
@export var hurt_throb_scale: float = 1.18
@export var hurt_throb_time: float = 0.10
@export var hurt_fall_time: float = 0.80
@export var hurt_knockup: float = -220.0
@export var hurt_push_x: float = 120.0

@onready var anim: AnimatedSprite2D = $Anim

var start_pos: Vector2
var _normal_scale: Vector2

var _hurt: bool = false
var _hurt_timer: float = 0.0

var _fade_tween: Tween

@export_multiline var text: String = ""

# -------------------- SHOOTING (ADDED) --------------------
@export var arrow_scene: PackedScene
@export var shoot_cooldown: float = 0.20
@export var shoot_action: StringName = &"Shoot"
@onready var arrow_spawn: Node2D = $ArrowSpawn

var _shoot_timer: float = 0.0
# ----------------------------------------------------------

func _ready() -> void:
	start_pos = global_position
	_normal_scale = anim.scale if anim else Vector2.ONE
	if anim:
		anim.play("idle")

	if fade:
		fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		fade.z_index = 999
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fade.visible = false
		fade.modulate.a = 0.0

func is_hurt() -> bool:
	return _hurt

func _physics_process(delta: float) -> void:
	# -------------------- SHOOTING (ADDED) --------------------
	if _shoot_timer > 0.0:
		_shoot_timer -= delta

	if Input.is_action_just_pressed(shoot_action) and _shoot_timer <= 0.0 and not _hurt:
		_shoot_arrow()
		_shoot_timer = shoot_cooldown

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

	var dir := Input.get_action_strength("Right") - Input.get_action_strength("Left")
	velocity.x = dir * speed

	if Input.is_action_just_pressed("Up") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()

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

func hurt_and_reset(from_x: float = 0.0) -> void:
	if _hurt:
		return

	_hurt = true
	_hurt_timer = hurt_fall_time

	# small knockback
	var dir_x := 1.0
	if from_x != 0.0:
		dir_x = sign(global_position.x - from_x)
		if dir_x == 0:
			dir_x = 1.0

	velocity.x = dir_x * hurt_push_x
	velocity.y = hurt_knockup

	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("hurt"):
		anim.play("hurt")

	_start_throb()
	_fade_flash(0.15)

func _fade_flash(time: float = 0.15) -> void:
	if not fade:
		return

	if _fade_tween:
		_fade_tween.kill()

	fade.visible = true
	fade.modulate.a = 0.6

	_fade_tween = create_tween()
	_fade_tween.tween_property(fade, "modulate:a", 0.0, time)
	_fade_tween.finished.connect(func() -> void:
		fade.visible = false
	)

func _start_throb() -> void:
	if not anim:
		return

	var tween: Tween = create_tween()
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

func _on_key_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Global.text_box = text

func _on_key_body_exited(body: Node2D) -> void:
	if body.name == "Player" and Global.text_box == text:
		Global.text_box = ""

# arrow shoot
func _shoot_arrow() -> void:
	if arrow_scene == null:
		push_error("Player: arrow_scene not assigned!")
		return

	if arrow_spawn == null:
		push_error("Player: ArrowSpawn not found!")
		return

	var arrow := arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow)

	# Spawn position
	arrow.global_position = arrow_spawn.global_position

	# Calculate direction toward mouse
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (mouse_pos - arrow_spawn.global_position).normalized()

	# Set arrow direction (your arrow script must have `var direction`)
	arrow.direction = dir

	# Rotate arrow to face movement direction
	arrow.rotation = dir.angle()
