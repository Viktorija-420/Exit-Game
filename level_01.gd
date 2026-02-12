extends Node2D   # or Node3D if your level is 3D

@onready var pop_level: Panel = $Panel

@export var fade_in_time: float = 0.6
@export var visible_time: float = 1.5
@export var fade_out_time: float = 0.6

func _ready() -> void:
	show_popup()

func show_popup() -> void:
	pop_level.visible = true
	pop_level.modulate.a = 0.0
	
	var tween = create_tween()
	
	# Fade in
	tween.tween_property(pop_level, "modulate:a", 1.0, fade_in_time)
	
	# Wait
	tween.tween_interval(visible_time)
	
	# Fade out
	tween.tween_property(pop_level, "modulate:a", 0.0, fade_out_time)
	
	# Hide after fade
	tween.tween_callback(func(): pop_level.visible = false)
