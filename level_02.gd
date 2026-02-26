extends Node2D

@onready var pop_level: Panel = $Panel

@export var fade_in_time: float = 0.6
@export var visible_time: float = 1.5
@export var fade_out_time: float = 0.6

func _ready() -> void:
	show_popup()
	# Reset key for next level if needed
	Global.has_key = false

func show_popup() -> void:
	pop_level.visible = true
	pop_level.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(pop_level, "modulate:a", 1.0, fade_in_time)
	tween.tween_interval(visible_time)
	tween.tween_property(pop_level, "modulate:a", 0.0, fade_out_time)
	tween.tween_callback(func(): pop_level.visible = false)
