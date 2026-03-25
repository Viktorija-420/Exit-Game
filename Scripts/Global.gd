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
	# Ensure the Global script itself can run while the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	# We assume 'Music' is another Autoload or a child node here
	# Music.play_music("res://Assets/Sound/Game.mp3") 
	reset_run()

func set_music_paused(is_paused: bool):
	# FIX: Use the correct node name. 
	# If your music is playing via the 'Music' autoload:
	if is_instance_valid(Music):
		# If 'Music' is an AudioStreamPlayer:
		Music.stream_paused = is_paused
	# OR if you have a child node named 'BGMusic' inside this Global script:
	elif has_node("BGMusic"):
		$BGMusic.stream_paused = is_paused

# --- Existing Functionality (Do not change) ---
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
	max_lives = max_lives_cap
	lives = max_lives
	lives_changed.emit(lives)
