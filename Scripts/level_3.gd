extends Node2D

# -------------------- NODES --------------------
@onready var fade_rect: ColorRect = $CanvasLayer/Fade
@onready var pop_level: Label = $CanvasLayer/popLevel

# -------------------- SETTINGS --------------------
@export var level_fade_time: float = 0.8

# -------------------- READY --------------------
func _ready() -> void:
	# 1. Reset the game state for the new level
	Global.has_key = false 
	
	# 2. Clear the black screen left over from Level 2
	_fade_in_level()
	
	# 3. Show the level name
	show_popup()

func _fade_in_level() -> void:
	if not fade_rect: 
		return
		
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0 # Start fully black
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, level_fade_time)
	await tween.finished
	fade_rect.visible = false

func show_popup() -> void:
	if not pop_level: 
		return
		
	pop_level.text = "Level 3" # Make sure this is set
	pop_level.visible = true
	pop_level.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(pop_level, "modulate:a", 1.0, 0.6)
	tween.tween_interval(1.5)
	tween.tween_property(pop_level, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): pop_level.visible = false)
