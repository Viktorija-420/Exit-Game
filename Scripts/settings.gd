extends Node

const SAVE_PATH = "user://Settings.cfg"
var config = ConfigFile.new()

func _ready():
	load_settings()

func save_setting(section: String, key: String, value):
	config.set_value(section, key, value)
	config.save(SAVE_PATH)

func load_settings():
	var error = config.load(SAVE_PATH)
	
	# 1. Handle Fullscreen (Default: false)
	var is_full = config.get_value("Video", "fullscreen", false)
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if is_full else Window.MODE_WINDOWED
	
	# 2. Handle Volume (Default: 0.5 for 50%)
	var vol = config.get_value("Audio", "master_volume", 0.5) 
	AudioServer.set_bus_volume_db(0, linear_to_db(vol))
