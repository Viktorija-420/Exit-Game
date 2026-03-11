extends CharacterBody2D

@export var speed: float = 80.0
@export var gravity: float = 900.0

@export var max_hp: int = 3
@export var invincibility_time: float = 0.10

@export var detection_distance: float = 500.0
@export var attack_distance: float = 120.0

@export var attack_jump_force: float = -260.0
@export var attack_push: float = 220.0
@export var attack_cooldown: float = 1.0

@onready var anim: AnimatedSprite2D = $Anim
@onready var hearts_root: Node2D = $Hearts
@onready var hurt_area: Area2D = $HurtArea

@onready var hearts: Array[Sprite2D] = [
	$Hearts/Heart1,
	$Hearts/Heart2,
	$Hearts/Heart3
]

var player: Node2D
var hp: int
var _invincible := false
var _base_scale: Vector2

var attacking := false
var attack_cd := 0.0
var attack_dir := 1


func _ready() -> void:
	hp = max_hp
	player = get_tree().get_first_node_in_group("player")

	_base_scale = anim.scale
	anim.play("Idle")

	anim.frame_changed.connect(_on_anim_frame_changed)
	anim.animation_finished.connect(_on_anim_finished)

	_update_hearts()


func _physics_process(delta: float) -> void:
	# find player if missing
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return

	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# attack cooldown
	if attack_cd > 0.0:
		attack_cd -= delta

	# horizontal distance
	var dist = abs(player.global_position.x - global_position.x)

	# direction to player
	var dir = sign(player.global_position.x - global_position.x)
	if dir == 0:
		dir = 1

	# always face player
	if not attacking:
		anim.flip_h = dir > 0

	# -------- ATTACK CHECK (always active) --------
	if dist <= attack_distance and attack_cd <= 0.0 and not attacking:
		anim.flip_h = dir > 0
		start_attack()

	# -------- MOVEMENT --------
	if attacking:
		move_and_slide()
		return

	# walk toward player
	if dist <= detection_distance:
		velocity.x = dir * (speed * 0.5)
		if anim.animation != "Walk":
			anim.play("Walk")
	else:
		velocity.x = 0
		if anim.animation != "Idle":
			anim.play("Idle")

	move_and_slide()
	
func start_attack():
	attacking = true

	if player.global_position.x > global_position.x:
		attack_dir = 1
		anim.flip_h = true
	else:
		attack_dir = -1
		anim.flip_h = false

	velocity.x = 0.0
	anim.play("Attack")

func _on_anim_frame_changed():
	if anim.animation == "Attack" and anim.frame == 2:
		velocity.x = attack_dir * attack_push
		velocity.y = attack_jump_force


func _on_anim_finished():
	if anim.animation == "Attack":
		attacking = false
		attack_cd = attack_cooldown
		anim.play("Idle")


func _update_hearts():
	for i in range(hearts.size()):
		hearts[i].visible = i < hp


func take_damage(amount := 1):
	if _invincible:
		return

	hp -= amount
	hp = clamp(hp, 0, max_hp)
	_update_hearts()

	if hearts_root:
		hearts_root.scale = Vector2.ONE * 1.2
		var tw = create_tween()
		tw.tween_property(hearts_root, "scale", Vector2.ONE, 0.08)

	anim.scale = _base_scale * 0.9
	var t = create_tween()
	t.tween_property(anim, "scale", _base_scale, 0.08)

	_invincible = true
	get_tree().create_timer(invincibility_time).timeout.connect(func():
		_invincible = false
	)

	if hp <= 0:
		queue_free()


func _on_hurt_area_body_entered(body: Node2D):
	if body == null:
		return

	if body.name != "Player":
		return

	if body.has_method("is_shielding") and body.is_shielding():
		return

	if body.has_method("is_hurt") and body.is_hurt():
		return

	if body.has_method("hurt_and_reset"):
		body.hurt_and_reset(global_position.x)
		return

	Global.lose_life(1)

	if Global.lives <= 0:
		Global.restart_current_level()

func face_player():
	if player == null:
		return

	if player.global_position.x > global_position.x:
		anim.flip_h = true
	else:
		anim.flip_h = false
