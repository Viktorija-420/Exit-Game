extends Node

signal lives_changed(lives: int)
signal key_changed(has_key: bool)

@export var max_lives: int = 3
@export var max_lives_cap: int = 4  # allow up to 4 hearts

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

# ✅ NEW: heal logic
# - if lives < max_lives: heal +1
# - else if lives == max_lives and max_lives < 4: add a 4th heart and fill it
func gain_life(amount: int = 1) -> void:
	for i in range(amount):
		if lives < max_lives:
			lives += 1
		elif max_lives < max_lives_cap:
			max_lives += 1
			lives += 1
		# else: already full and at cap, do nothing

	lives = clamp(lives, 0, max_lives)
	lives_changed.emit(lives)

func reset_run() -> void:
	max_lives = min(max_lives, max_lives_cap)
	lives = max_lives
	current_level = 1
	has_key = false
	lives_changed.emit(lives)
