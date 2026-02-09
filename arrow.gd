extends Area2D

@export var speed: float = 800.0
var direction: Vector2 = Vector2.RIGHT

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()  # optional: makes arrow face the direction

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy and enemy.has_method("take_damage"):
		enemy.take_damage(1)
		queue_free()
