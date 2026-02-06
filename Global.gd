extends Node

signal lives_changed(lives: int)
signal key_changed(has_key: bool)

@export var max_lives: int = 3

var lives: int = 0
var current_level: int = 1
var text_box: String = ""

var has_key: bool = false:
	set(value):
		has_key = value
		key_changed.emit(has_key)

func _ready() -> void:
	reset_run()

func lose_life(amount: int = 1) -> void:
	lives = max(lives - amount, 0)
	lives_changed.emit(lives)

func reset_run() -> void:
	lives = max_lives
	current_level = 1
	has_key = false # will emit key_changed(false)
	lives_changed.emit(lives)
