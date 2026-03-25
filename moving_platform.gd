extends AnimatableBody2D

@export var move_to: Vector2 = Vector2(200, 0) # Relative distance to move

# -------------------- RANDOM SPEED SETTINGS --------------------
@export var min_speed: float = 3.0  # Fastest (seconds per cycle)
@export var max_speed: float = 6.0  # Slowest (seconds per cycle)

var speed: float = 2.0 
var phase: float = 0.0
@onready var start_position: Vector2 = position

func _ready() -> void:
	# Initialize the random number generator
	randomize() 
	
	# Pick a random speed between your min and max
	speed = randf_range(min_speed, max_speed)
	
	# Optional: Start at a random point in the animation so 
	# multiple platforms don't move in perfect sync
	phase = randf_range(0, TAU) 

func _physics_process(delta: float) -> void:
	# We use TAU (2*PI) because one full sine wave cycle is 2*PI radians
	phase += delta * (TAU / speed)
	
	# Calculate the 0.0 to 1.0 range (Sine wave goes -1 to 1, so we normalize it)
	var movement_factor = (sin(phase) + 1.0) / 2.0
	
	var target_goal = start_position + move_to
	position = start_position.lerp(target_goal, movement_factor)
