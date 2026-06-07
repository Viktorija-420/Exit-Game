# ============================================================
# Global.gd  —  full fixed file (no logic changes)
# ============================================================
extends Node

var player_current_attack = false
signal lives_changed(lives: int)
signal key_changed(has_key: bool)

@export var default_max_lives: int = 5
@export var max_lives_cap: int = 6

var max_lives: int = 5
var lives: int = 5
var _has_key: bool = false
var current_level: int = 1
var text_box: String = ""

var settings_return_path: String = "res://MainMenu.tscn"
var was_paused: bool = false

const SAVE_PATH = "user://settings.cfg"
var resolutions: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1280, 720),
	Vector2i(1024, 576),
]

var has_key: bool:
	get: return _has_key
	set(value):
		_has_key = value
		key_changed.emit(_has_key)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	max_lives = default_max_lives
	lives = max_lives
	apply_saved_settings_globally()

func lose_life(amount: int = 1) -> void:
	lives = max(lives - amount, 0)
	lives_changed.emit(lives)

func reset_run() -> void:
	max_lives = default_max_lives
	lives = max_lives
	has_key = false
	lives_changed.emit(lives)

func restart_current_level() -> void:
	lives = max_lives
	has_key = false
	settings_return_path = ""  # clear it so settings never loads as fallback
	lives_changed.emit(lives)
	get_tree().call_deferred("reload_current_scene")

func gain_life(amount: int = 1) -> void:
	max_lives = max_lives_cap
	lives = max_lives
	lives_changed.emit(lives)

func set_music_paused(is_paused: bool):
	if is_instance_valid(Music):
		Music.stream_paused = is_paused
	elif has_node("BGMusic"):
		$BGMusic.stream_paused = is_paused

func apply_saved_settings_globally() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err != OK:
		apply_audio_values(0.5, 0.5, 0.5, false)
		apply_video_settings(1)
		apply_window_mode(0)
		apply_resolution(2)
		return

	var m_vol   = config.get_value("audio", "master_vol",   0.5)
	var mus_vol = config.get_value("audio", "music_vol",    0.5)
	var s_vol   = config.get_value("audio", "sfx_vol",      0.5)
	var is_muted= config.get_value("audio", "mute",         false)
	var qual    = config.get_value("video", "quality_index", 1)
	var win     = config.get_value("video", "window_mode",   0)
	var res     = config.get_value("video", "res_index",     2)

	apply_audio_values(m_vol, mus_vol, s_vol, is_muted)
	apply_window_mode(win)
	if win == 0:
		apply_resolution(res)
	apply_video_settings(qual)

func apply_audio_values(m, mus, s, mute):
	var master_bus = AudioServer.get_bus_index("Master")
	var music_bus  = AudioServer.get_bus_index("Music")
	var sfx_bus    = AudioServer.get_bus_index("SFX")
	if master_bus != -1: AudioServer.set_bus_volume_db(master_bus, linear_to_db(m))
	if music_bus  != -1: AudioServer.set_bus_volume_db(music_bus,  linear_to_db(mus))
	if sfx_bus    != -1: AudioServer.set_bus_volume_db(sfx_bus,    linear_to_db(s))
	if master_bus != -1: AudioServer.set_bus_mute(master_bus, mute)

func apply_video_settings(index: int):
	if index < 0: return
	match index:
		0:
			get_viewport().scaling_3d_scale = 0.5
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		1:
			get_viewport().scaling_3d_scale = 0.75
			get_viewport().msaa_3d = Viewport.MSAA_2X
		2:
			get_viewport().scaling_3d_scale = 1.0
			get_viewport().msaa_3d = Viewport.MSAA_4X

func apply_window_mode(index: int):
	if index == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func apply_resolution(index: int):
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return
	if index >= 0 and index < resolutions.size():
		DisplayServer.window_set_size(resolutions[index])
		var screen_center = DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2)
		var window_size = DisplayServer.window_get_size()
		DisplayServer.window_set_position(screen_center - (window_size / 2))
