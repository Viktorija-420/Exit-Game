extends Node2D

@export_file("*.tscn") var main_menu_scene := "res://MainMenu.tscn"

# --- Variables ---
@onready var master_bus = AudioServer.get_bus_index("Master")
@onready var music_bus = AudioServer.get_bus_index("Music")
@onready var sfx_bus = AudioServer.get_bus_index("SFX")

const SAVE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

# Resolution lookup table
var resolutions: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1280, 720),
	Vector2i(1024, 576)
]

# --- Initialization ---
func _ready() -> void:
	await get_tree().process_frame
	load_settings()
	print("--- All Settings Loaded & Applied ---")

# --- Audio Logic ---
func _on_master_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
	save_settings()

func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(value))
	save_settings()

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value))
	save_settings()

func _on_check_box_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(master_bus, toggled_on)
	save_settings()

# --- Video Quality Logic ---
func _on_quality_dropdown_item_selected(index: int) -> void:
	apply_video_settings(index)
	save_settings()

func apply_video_settings(index: int):
	if index < 0: return 
	match index:
		0: # Low
			get_viewport().scaling_3d_scale = 0.5
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		1: # Normal
			get_viewport().scaling_3d_scale = 0.75
			get_viewport().msaa_3d = Viewport.MSAA_2X
		2: # High
			get_viewport().scaling_3d_scale = 1.0
			get_viewport().msaa_3d = Viewport.MSAA_4X

# --- Window & Resolution Logic ---
func _on_window_mode_dropdown_item_selected(index: int) -> void:
	apply_window_mode(index)
	save_settings()

func apply_window_mode(index: int):
	if index == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# Ensure resolution is re-applied when going to windowed
		var res_idx = $Panel/ResolutionDropdown.selected if has_node("Panel/ResolutionDropdown") else 2
		apply_resolution(res_idx)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_resolution_dropdown_item_selected(index: int) -> void:
	apply_resolution(index)
	save_settings()

func apply_resolution(index: int):
	if index >= 0 and index < resolutions.size():
		DisplayServer.window_set_size(resolutions[index])
		# Center the window on the screen
		var screen_center = DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2)
		var window_size = DisplayServer.window_get_size()
		DisplayServer.window_set_position(screen_center - (window_size / 2))

# --- Save/Load System ---
func save_settings():
	# Audio
	config.set_value("audio", "master_vol", db_to_linear(AudioServer.get_bus_volume_db(master_bus)))
	config.set_value("audio", "music_vol", db_to_linear(AudioServer.get_bus_volume_db(music_bus)))
	config.set_value("audio", "sfx_vol", db_to_linear(AudioServer.get_bus_volume_db(sfx_bus)))
	config.set_value("audio", "mute", AudioServer.is_bus_mute(master_bus))
	
	# Video
	if has_node("Panel/QualityDropdown"):
		config.set_value("video", "quality_index", $Panel/QualityDropdown.selected)
	if has_node("Panel/WindowModeDropdown"):
		config.set_value("video", "window_mode", $Panel/WindowModeDropdown.selected)
	if has_node("Panel/ResolutionDropdown"):
		config.set_value("video", "res_index", $Panel/ResolutionDropdown.selected)
	
	config.save(SAVE_PATH)

func load_settings():
	var err = config.load(SAVE_PATH)
	
	if err != OK:
		# APPLY DEFAULTS
		apply_audio_values(0.5, 0.5, 0.5, false)
		apply_video_settings(1)
		apply_window_mode(0)
		apply_resolution(2) # Default to 720p
		update_ui(0.5, 0.5, 0.5, false, 1, 0, 2)
		return 
	
	# LOAD FROM FILE
	var m_vol = config.get_value("audio", "master_vol", 0.5)
	var mus_vol = config.get_value("audio", "music_vol", 0.5)
	var s_vol = config.get_value("audio", "sfx_vol", 0.5)
	var is_muted = config.get_value("audio", "mute", false)
	var qual = config.get_value("video", "quality_index", 1)
	var win = config.get_value("video", "window_mode", 0)
	var res = config.get_value("video", "res_index", 2)

	apply_audio_values(m_vol, mus_vol, s_vol, is_muted)
	apply_video_settings(qual)
	apply_window_mode(win)
	apply_resolution(res)
	update_ui(m_vol, mus_vol, s_vol, is_muted, qual, win, res)

func apply_audio_values(m, mus, s, mute):
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(m))
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(mus))
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(s))
	AudioServer.set_bus_mute(master_bus, mute)

func update_ui(m, mus, s, mute, qual, win, res):
	if has_node("Panel/MasterSlider"): $Panel/MasterSlider.value = m
	if has_node("Panel/MusicSlider"): $Panel/MusicSlider.value = mus
	if has_node("Panel/SFXSlider"):   $Panel/SFXSlider.value = s
	if has_node("Panel/MuteCheckBox"): $Panel/MuteCheckBox.button_pressed = mute
	if has_node("Panel/QualityDropdown"): $Panel/QualityDropdown.selected = qual
	if has_node("Panel/WindowModeDropdown"): $Panel/WindowModeDropdown.selected = win
	if has_node("Panel/ResolutionDropdown"): $Panel/ResolutionDropdown.selected = res

func _on_back_button_pressed() -> void:
	save_settings()
	if ResourceLoader.exists(main_menu_scene):
		get_tree().change_scene_to_file(main_menu_scene)
