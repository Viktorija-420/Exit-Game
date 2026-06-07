extends Node2D

@export_file("*.tscn") var main_menu_scene := "res://MainMenu.tscn"

# --- Custom Button Colors & Visual States ---
const COLOR_NORMAL := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_HOVER  := Color(0.75, 0.75, 0.75, 1.0)
const COLOR_PRESSED := Color(0.85, 0.65, 0.75, 1.0)

var config = ConfigFile.new()

# --- Initialization ---
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if has_node("Panel/BackButton"):
		_setup_button_visuals($Panel/BackButton)
	elif has_node("BackButton"):
		_setup_button_visuals($BackButton)
		
	if has_node("Panel/MuteCheckBox"):
		$Panel/MuteCheckBox.focus_mode = Control.FOCUS_NONE
	elif has_node("MuteCheckBox"):
		$MuteCheckBox.focus_mode = Control.FOCUS_NONE
		
	await get_tree().process_frame
	load_settings_to_ui()
	print("--- Settings UI Synchronized with Config ---")

## Helper function for button visuals
func _setup_button_visuals(btn: Button) -> void:
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE

	var tex_rect := btn.get_child(0) as TextureRect
	if not tex_rect: return

	var is_hovered := false

	btn.mouse_entered.connect(func(): 
		is_hovered = true
		tex_rect.modulate = COLOR_HOVER
		btn.self_modulate = COLOR_HOVER
	)
	btn.mouse_exited.connect(func(): 
		is_hovered = false
		tex_rect.modulate = COLOR_NORMAL
		btn.self_modulate = COLOR_NORMAL
	)
	btn.button_down.connect(func(): 
		tex_rect.modulate = COLOR_PRESSED
		btn.self_modulate = COLOR_PRESSED
	)
	btn.button_up.connect(func(): 
		var target_color := COLOR_HOVER if is_hovered else COLOR_NORMAL
		tex_rect.modulate = target_color
		btn.self_modulate = target_color
	)

# --- Audio Logic ---
func _on_master_slider_value_changed(value: float) -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
	save_settings()

func _on_music_slider_value_changed(value: float) -> void:
	var music_bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(value))
	save_settings()

func _on_sfx_slider_value_changed(value: float) -> void:
	var sfx_bus = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value))
	save_settings()

func _on_check_box_toggled(toggled_on: bool) -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus, toggled_on)
	save_settings()

# --- Video Quality Logic ---
func _on_quality_dropdown_item_selected(index: int) -> void:
	Global.apply_video_settings(index)
	save_settings()

# --- Window & Resolution Logic ---
func _on_window_mode_dropdown_item_selected(index: int) -> void:
	Global.apply_window_mode(index)
	
	var res_dropdown = $Panel/ResolutionDropdown if has_node("Panel/ResolutionDropdown") else ($ResolutionDropdown if has_node("ResolutionDropdown") else null)
	if index == 0: # Windowed
		if res_dropdown:
			res_dropdown.disabled = false
			Global.apply_resolution(res_dropdown.selected if res_dropdown.selected >= 0 else 2)
	else: # Fullscreen
		if res_dropdown:
			res_dropdown.disabled = true
			
	save_settings()

func _on_resolution_dropdown_item_selected(index: int) -> void:
	Global.apply_resolution(index)
	save_settings()

# --- Save/Load UI Sync ---
func save_settings():
	var master_bus = AudioServer.get_bus_index("Master")
	var music_bus = AudioServer.get_bus_index("Music")
	var sfx_bus = AudioServer.get_bus_index("SFX")

	config.set_value("audio", "master_vol", db_to_linear(AudioServer.get_bus_volume_db(master_bus)))
	config.set_value("audio", "music_vol", db_to_linear(AudioServer.get_bus_volume_db(music_bus)))
	config.set_value("audio", "sfx_vol", db_to_linear(AudioServer.get_bus_volume_db(sfx_bus)))
	config.set_value("audio", "mute", AudioServer.is_bus_mute(master_bus))
	
	if has_node("Panel/QualityDropdown"): config.set_value("video", "quality_index", $Panel/QualityDropdown.selected)
	if has_node("Panel/WindowModeDropdown"): config.set_value("video", "window_mode", $Panel/WindowModeDropdown.selected)
	if has_node("Panel/ResolutionDropdown"): config.set_value("video", "res_index", $Panel/ResolutionDropdown.selected)
	
	config.save(Global.SAVE_PATH)

func load_settings_to_ui():
	var err = config.load(Global.SAVE_PATH)
	
	var m_vol = config.get_value("audio", "master_vol", 0.5)
	var mus_vol = config.get_value("audio", "music_vol", 0.5)
	var s_vol = config.get_value("audio", "sfx_vol", 0.5)
	var is_muted = config.get_value("audio", "mute", false)
	var qual = config.get_value("video", "quality_index", 1)
	var win = config.get_value("video", "window_mode", 0)
	var res = config.get_value("video", "res_index", 2)

	# Sinhronizējam UI slīdņus un dropdownus ar reālajiem datiem
	if has_node("Panel/MasterSlider"): $Panel/MasterSlider.value = m_vol
	if has_node("Panel/MusicSlider"): $Panel/MusicSlider.value = mus_vol
	if has_node("Panel/SFXSlider"):   $Panel/SFXSlider.value = s_vol
	if has_node("Panel/MuteCheckBox"): $Panel/MuteCheckBox.button_pressed = is_muted
	if has_node("Panel/QualityDropdown"): $Panel/QualityDropdown.selected = qual
	if has_node("Panel/WindowModeDropdown"): $Panel/WindowModeDropdown.selected = win
	
	var res_dropdown = $Panel/ResolutionDropdown if has_node("Panel/ResolutionDropdown") else ($ResolutionDropdown if has_node("ResolutionDropdown") else null)
	if res_dropdown:
		res_dropdown.selected = res
		res_dropdown.disabled = (win != 0)

func _on_back_button_pressed() -> void:
	save_settings()
	# Check if we are an overlay inside the UI CanvasLayer
	if get_parent() and get_parent() != get_tree().root:
		for node in get_tree().get_nodes_in_group("ui"):
			if node.has_method("_remove_settings_overlay"):
				node._remove_settings_overlay()
		return
	# Standalone scene (opened from main menu) — go back normally
	var destination = Global.settings_return_path if Global.settings_return_path != "" else main_menu_scene
	if ResourceLoader.exists(destination):
		get_tree().change_scene_to_file(destination)
