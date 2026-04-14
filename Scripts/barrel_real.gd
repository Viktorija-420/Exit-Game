extends StaticBody2D

@export var loot_scene: PackedScene
@onready var anim = $AnimatedSprite2D

var is_broken = false

func _ready():
	add_to_group("destructible")
	anim.play("Idle")

func hit():
	if not is_broken:
		break_object()

func break_object():
	await get_tree().create_timer(0.3).timeout
	is_broken = true
	
	if anim.sprite_frames.has_animation("Broken"):
		anim.play("Broken")
	
	$CollisionShape2D.set_deferred("disabled", true)
	
	await get_tree().create_timer(1.5).timeout
	queue_free()
	spawn_loot()

func spawn_loot():
	# Try the exported variable first, then fallback to load()
	var temp_loot = loot_scene if loot_scene else load("res://loot_item.tscn")
	
	if temp_loot:
		var loot = temp_loot.instantiate()
		# Use call_deferred to avoid physics thread issues
		get_parent().call_deferred("add_child", loot)
		# Set position after adding to parent
		loot.global_position = global_position
	else:
		print("FATAL ERROR: No loot scene found!")
