extends AnimatableBody2D

@export var move_to: Vector2 = Vector2(200, 0) # Relative distance to move
@export var speed: float = 2.0 

var phase: float = 0.0
@onready var start_position: Vector2 = position # This saves the editor placement!

func _physics_process(delta: float) -> void :
	phase += delta * (PI / speed)
	
	# Calculate the 0.0 to 1.0 range for the animation
	var movement_factor = (sin(phase) + 1.0) / 2.0
	
	# NEW: Add the movement to the start_position instead of replacing it
	var target_goal = start_position + move_to
	position = start_position.lerp(target_goal, movement_factor)
