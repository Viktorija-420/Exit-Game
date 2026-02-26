extends CharacterBody2D

@export var speed: float = 80.0
@export var gravity: float = 900.0
@export var direction: int = 1  # 1 right, -1 left

@export var max_hp: int = 3
@export var invincibility_time: float = 0.10

@onready var anim: Sprite2D = get_node_or_null("Anim") as Sprite2D
@onready var hearts_root: Node2D = get_node_or_null("Hearts") as Node2D
@onready var hearts: Array[Sprite2D] = [
	get_node_or_null("Hearts/Heart1") as Sprite2D,
	get_node_or_null("Hearts/Heart2") as Sprite2D,
	get_node_or_null("Hearts/Heart3") as Sprite2D
]

var hp: int
var _base_scale: Vector2 = Vector2.ONE
var _invincible: bool = false

func _ready() -> void:
	hp = max_hp
	if anim:
		_base_scale = anim.scale
	_update_hearts()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	velocity.x = direction * speed
	move_and_slide()

	if anim:
		anim.flip_h = velocity.x < 0

	if is_on_wall():
		direction *= -1

func _update_hearts() -> void:
	for i in range(hearts.size()):
		if hearts[i]:
			hearts[i].visible = i < hp

func take_damage(amount: int = 1) -> void:
	if _invincible:
		return

	hp -= amount
	hp = clamp(hp, 0, max_hp)
	_update_hearts()

	if hearts_root:
		hearts_root.scale = Vector2.ONE * 1.2
		var tw := create_tween()
		tw.tween_property(hearts_root, "scale", Vector2.ONE, 0.08)

	if anim:
		anim.scale = _base_scale * 0.9
		var t := create_tween()
		t.tween_property(anim, "scale", _base_scale, 0.08)

	_invincible = true
	get_tree().create_timer(invincibility_time).timeout.connect(func() -> void:
		_invincible = false
	)

	if hp <= 0:
		queue_free()

func _on_hurt_area_body_entered(body: Node2D) -> void:
	print("ENEMY HurtArea ENTER:", body)

	if body == null:
		return
	if body.name != "Player":
		return

	if body.has_method("is_shielding") and body.is_shielding():
		print("Player is shielding, ignoring enemy damage")
		return

	if body.has_method("is_hurt") and body.is_hurt():
		print("Player already hurt, ignoring")
		return

	if body.has_method("hurt_and_reset"):
		print("Calling player.hurt_and_reset()")
		body.hurt_and_reset(global_position.x)
		return

	# fallback if player script differs
	print("Player has no hurt_and_reset, fallback 1-heart damage")
	Global.lose_life(1)

	# ✅ if dead, restart current level (not main menu)
	if Global.lives <= 0:
		Global.restart_current_level()
