extends Node2D

@onready var fade_rect: ColorRect = $CanvasLayer/Fade
@onready var pop_level: Label = $CanvasLayer/popLevel
@onready var door: Area2D = $Door
var _transitioning: bool = false

@export var level_fade_time: float = 0.8

func _ready() -> void:
	Global.has_key = false 
	
	_fade_in_level()
	show_popup()
	
	if door:
		door.body_entered.connect(_on_door_entered)

func _fade_in_level() -> void:
	if not fade_rect: 
		return
		
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, level_fade_time)
	await tween.finished
	fade_rect.visible = false
	
func _on_door_entered(body: Node2D) -> void:
	print("Something touched the door: ", body.name) # Debug 1
	
	if _transitioning: return

	if body.is_in_group("player"):
		print("Player is at the door! Has key: ", Global.has_key) # Debug 2
		if Global.has_key:
			_transitioning = true
			_start_level_transition()
		else:
			print("Access denied: You need the key!")

func show_popup() -> void:
	if not pop_level: 
		return
		
	pop_level.text = "Level Nine"
	pop_level.visible = true
	pop_level.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(pop_level, "modulate:a", 1.0, 0.6)
	tween.tween_interval(1.5)
	tween.tween_property(pop_level, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): pop_level.visible = false)

func _start_level_transition() -> void:
	print("Level 9: Transition triggered!")
	_transitioning = true

	if fade_rect:
		fade_rect.visible = true
		fade_rect.modulate.a = 0.0
		
		var t = create_tween()
		t.tween_property(fade_rect, "modulate:a", 1.0, 0.6)
		
		t.finished.connect(func():
			print("Level 9: Fade complete. Switching NOW.")
			get_tree().change_scene_to_file("res://level_10.tscn")
		)
	else:
		print("Level 9: No fade rect found, switching immediately.")
		get_tree().change_scene_to_file("res://level_10.tscn")
