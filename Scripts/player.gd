extends CharacterBody2D

signal charge_progress_changed(progress: float, charging: bool)

var _charge_ready: bool = false
var controls_enabled: bool = true  # <-- new flag to enable/disable controls

@onready var anim: AnimatedSprite2D = $Anim
@onready var arrow_spawn: Node2D = $ArrowSpawn

@export var speed: float = 200.0
@export var jump_force: float = -400.0
@export var gravity: float = 1000.0

# hurt tuning
@export var hurt_throb_scale: float = 1.18
@export var hurt_throb_time: float = 0.10
@export var hurt_fall_time: float = 0.80
@export var hurt_knockup: float = -220.0
@export var hurt_push_x: float = 120.0

# shield
@export var shield_action: StringName = &"Shield"
@export var shield_speed_mult: float = 0.55
var _shielding: bool = false

# shooting + charge
@export var arrow_scene: PackedScene
@export var shoot_action: StringName = &"Shoot"
@export var shoot_cooldown: float = 0.20
@export var charge_time: float = 1.0
@export var charge_cooldown: float = 2.0
@export var normal_damage: int = 1
@export var charged_damage: int = 2

var _shoot_timer: float = 0.0
var _charge_cd_timer: float = 0.0
var _charging: bool = false
var _charge_timer: float = 0.0

# misc
var _normal_scale: Vector2
var _hurt: bool = false
var _hurt_timer: float = 0.0

@export_multiline var text: String = ""

func _ready() -> void:
	_normal_scale = anim.scale if anim else Vector2.ONE
	if anim:
		anim.play("idle")

func is_hurt() -> bool:
	return _hurt

func is_shielding() -> bool:
	return _shielding

func _physics_process(delta: float) -> void:
	if not controls_enabled:
		# skip movement/input while dialog is active
		return

	# timers
	if _shoot_timer > 0.0:
		_shoot_timer -= delta
	if _charge_cd_timer > 0.0:
		_charge_cd_timer -= delta

	# shield state
	_shielding = Input.is_action_pressed(shield_action) and not _hurt

	# charging logic
	_handle_shooting(delta)

	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# hurt state
	if _hurt:
		_hurt_timer -= delta
		move_and_slide()

		if _hurt_timer <= 0.0 and is_on_floor():
			_finish_hurt()
		elif _hurt_timer <= -0.25:
			_finish_hurt()
		return

	# movement
	var dir := Input.get_action_strength("Right") - Input.get_action_strength("Left")
	var move_speed := speed * (shield_speed_mult if _shielding else 1.0)
	velocity.x = dir * move_speed

	# jump
	if Input.is_action_just_pressed("Up") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()
	_update_animation()

func _handle_shooting(delta: float) -> void:
	if _hurt or not controls_enabled:
		_charging = false
		_charge_timer = 0.0
		_charge_ready = false
		emit_signal("charge_progress_changed", 0.0, false)
		return

	if Input.is_action_just_pressed(shoot_action):
		_charging = true
		_charge_timer = 0.0
		_charge_ready = false
		emit_signal("charge_progress_changed", 0.0, true)

	if _charging and Input.is_action_pressed(shoot_action):
		if not _charge_ready:
			_charge_timer += delta
			if _charge_timer >= charge_time:
				_charge_timer = charge_time
				_charge_ready = true

		var progress := 0.0
		if charge_time > 0.0:
			progress = clamp(_charge_timer / charge_time, 0.0, 1.0)

		emit_signal("charge_progress_changed", progress, true)

	if _charging and Input.is_action_just_released(shoot_action):
		_charging = false
		if _charge_ready and _charge_cd_timer <= 0.0:
			_shoot_arrow(charged_damage)
			_charge_cd_timer = charge_cooldown
			_shoot_timer = shoot_cooldown
		else:
			if _shoot_timer <= 0.0:
				_shoot_arrow(normal_damage)
				_shoot_timer = shoot_cooldown

		_charge_timer = 0.0
		_charge_ready = false
		emit_signal("charge_progress_changed", 0.0, false)

func _update_animation() -> void:
	if not anim:
		return

	if _shielding and is_on_floor():
		if anim.sprite_frames and anim.sprite_frames.has_animation("shield"):
			if anim.animation != "shield":
				anim.play("shield")
		if abs(velocity.x) > 1:
			anim.flip_h = velocity.x < 0
		return

	if not is_on_floor():
		return
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

	Global.lose_life(1)

	if Global.lives <= 0:
		Global.restart_current_level()
		return

	_hurt = true
	_hurt_timer = hurt_fall_time
	_shielding = false
	_charging = false
	_charge_timer = 0.0

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

func _finish_hurt() -> void:
	_hurt = false
	if anim:
		anim.scale = _normal_scale
		anim.play("idle")

func _shoot_arrow(dmg: int) -> void:
	if arrow_scene == null:
		push_error("Player: arrow_scene not assigned!")
		return
	if arrow_spawn == null:
		push_error("Player: ArrowSpawn not found!")
		return

	var arrow := arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = arrow_spawn.global_position

	var mouse_pos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (mouse_pos - arrow_spawn.global_position).normalized()

	if arrow.has_method("set_direction"):
		arrow.set_direction(dir)
	else:
		if "direction" in arrow:
			arrow.direction = dir
		arrow.rotation = dir.angle()

	if "damage" in arrow:
		arrow.damage = dmg

func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
