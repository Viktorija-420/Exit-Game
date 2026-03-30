extends Node2D

@export_file("*.tscn") var main_menu_scene := "res://MainMenu.tscn"

# --- Variables ---
@onready var master_bus = AudioServer.get_bus_index("Master")
const SAVE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

# --- Initialization ---
func _ready() -> void:
	# 1. Load saved settings from file
	load_settings()
	
	# 2. Sync UI to current volume
	var current_db = AudioServer.get_bus_volume_db(master_bus)
	if has_node("Panel/HSlider"):
		$Panel/HSlider.value = db_to_linear(current_db)

# --- Audio Logic ---
func _on_h_slider_value_changed(value: float) -> void:
	var db_volume = linear_to_db(value)
	AudioServer.set_bus_volume_db(master_bus, db_volume)
	AudioServer.set_bus_mute(master_bus, value < 0.01)
	save_settings()

func _on_check_box_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(master_bus, toggled_on)
	save_settings()

# --- Video Quality Logic ---
func _on_quality_dropdown_item_selected(index: int) -> void:
	apply_video_settings(index)
	save_settings()

func apply_video_settings(index: int):
	match index:
		0: # Low
			# Lower internal resolution scale
			get_viewport().scaling_3d_scale = 0.5
			# Disable Anti-aliasing
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		1: # Normal
			get_viewport().scaling_3d_scale = 0.75
			get_viewport().msaa_3d = Viewport.MSAA_2X
		2: # High
			get_viewport().scaling_3d_scale = 1.0
			get_viewport().msaa_3d = Viewport.MSAA_4X
	
	print("Quality set to: ", index)

# --- Save/Load System ---
func save_settings():
	# Save Audio
	if has_node("Panel/HSlider"):
		config.set_value("audio", "volume", $Panel/HSlider.value)
	config.set_value("audio", "mute", AudioServer.is_bus_mute(master_bus))
	
	# Save Video Quality Index
	if has_node("Panel/QualityDropdown"):
		config.set_value("video", "quality_index", $Panel/QualityDropdown.selected)
	
	config.save(SAVE_PATH)

func load_settings():
	var err = config.load(SAVE_PATH)
	if err != OK:
		return 
	
	# Load Audio
	var vol = config.get_value("audio", "volume", 0.5)
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(vol))
	if has_node("Panel/HSlider"):
		$Panel/HSlider.value = vol
	
	var is_muted = config.get_value("audio", "mute", false)
	AudioServer.set_bus_mute(master_bus, is_muted)
	if has_node("Panel/CheckBox"):
		$Panel/CheckBox.button_pressed = is_muted
		
	# Load Video Quality
	var quality = config.get_value("video", "quality_index", 1) # Default to Normal (1)
	apply_video_settings(quality)
	if has_node("Panel/QualityDropdown"):
		$Panel/QualityDropdown.selected = quality

func _on_back_button_pressed() -> void:
	# Save one last time before leaving
	save_settings()
	
	# Change back to the main menu
	if main_menu_scene != "" and ResourceLoader.exists(main_menu_scene):
		get_tree().change_scene_to_file(main_menu_scene)
	else:
		print("Error: Main Menu scene path is incorrect!")
