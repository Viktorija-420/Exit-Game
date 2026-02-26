extends Node

signal lives_changed(lives: int)
signal key_changed(has_key: bool)

@export var max_lives: int = 3
@export var max_lives_cap: int = 4   # Maximum possible hearts

var lives: int = 0
var current_level: int = 1
var text_box: String = ""

var _has_key: bool = false

var has_key: bool:
	get:
		return _has_key
	set(value):
		if _has_key == value:
			return
		_has_key = value
		key_changed.emit(_has_key)

func _ready() -> void:
	reset_run()

func lose_life(amount: int = 1) -> void:
	lives = max(lives - amount, 0)
	lives_changed.emit(lives)

func gain_life(amount: int = 1) -> void:
	for i in range(amount):
		if lives < max_lives:
			lives += 1
		elif max_lives < max_lives_cap:
			max_lives += 1
			lives += 1

	lives = clamp(lives, 0, max_lives)
	lives_changed.emit(lives)

func reset_run() -> void:
	max_lives = min(max_lives, max_lives_cap)
	lives = max_lives
	current_level = 1
	_has_key = false
	text_box = ""
	lives_changed.emit(lives)
	key_changed.emit(_has_key)

func reset_level_state() -> void:
	max_lives = min(max_lives, max_lives_cap)
	lives = max_lives
	_has_key = false
	text_box = ""
	lives_changed.emit(lives)
	key_changed.emit(_has_key)

func restart_current_level() -> void:
	reset_level_state()
	get_tree().call_deferred("reload_current_scene")
