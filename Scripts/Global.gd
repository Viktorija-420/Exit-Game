extends Node

var player_current_attack = false

signal lives_changed(lives: int)
signal key_changed(has_key: bool)

@export var max_lives: int = 5
@export var max_lives_cap: int = 6

var lives: int = 5
var current_level: int = 1
var text_box: String = ""
var _has_key: bool = false

var has_key: bool:
	get: return _has_key
	set(value):
		_has_key = value
		key_changed.emit(_has_key)

func _ready() -> void:
	reset_run()

func lose_life(amount: int = 1) -> void:
	lives = max(lives - amount, 0)
	lives_changed.emit(lives)

func reset_run() -> void:
	max_lives = 5
	lives = max_lives
	_has_key = false
	lives_changed.emit(lives)

func restart_current_level() -> void:
	reset_run()
	get_tree().reload_current_scene()

func gain_life(amount: int = 1) -> void:
	# Full heal + unlock max hearts
	max_lives = max_lives_cap
	lives = max_lives
	lives_changed.emit(lives)
