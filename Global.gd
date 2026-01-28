extends Node

@export var max_lives: int = 3
var lives: int
var current_level: int = 1

var text_box: String = ""
var has_key: bool = false

func _ready() -> void:
	reset_run()

func lose_life(amount: int = 1) -> void:
	lives = max(lives - amount, 0)

func reset_run() -> void:
	lives = max_lives
	current_level = 1
	
	
