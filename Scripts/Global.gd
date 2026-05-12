extends Node

var player_current_attack = false
signal lives_changed(lives: int)
signal key_changed(has_key: bool)

# --- SETTINGS ---
@export var default_max_lives: int = 5
@export var max_lives_cap: int = 6

# --- STATE (These persist between levels) ---
var max_lives: int = 5 
var lives: int = 5
var _has_key: bool = false
var current_level: int = 1
var text_box: String = ""

var has_key: bool:
	get: return _has_key
	set(value):
		_has_key = value
		key_changed.emit(_has_key)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Initialize game state once
	max_lives = default_max_lives
	lives = max_lives

func lose_life(amount: int = 1) -> void:
	lives = max(lives - amount, 0)
	lives_changed.emit(lives)

# Call this ONLY when starting a brand new game from the Main Menu
func reset_run() -> void:
	max_lives = default_max_lives
	lives = max_lives
	has_key = false
	lives_changed.emit(lives)

# Call this when the player dies or goes to a new level
func restart_current_level() -> void:
	# Refill lives to whatever the CURRENT max is (5 or 6)
	lives = max_lives 
	has_key = false # Usually you lose keys on death, remove this line if you want to keep them
	lives_changed.emit(lives)
	get_tree().call_deferred("reload_current_scene")

# Call this when the player drinks the potion
func gain_life(amount: int = 1) -> void:
	max_lives = max_lives_cap
	lives = max_lives # Heals player to full
	lives_changed.emit(lives)

func set_music_paused(is_paused: bool):
	if is_instance_valid(Music):
		Music.stream_paused = is_paused
	elif has_node("BGMusic"):
		$BGMusic.stream_paused = is_paused
