extends Node2D

# -------------------- NODES --------------------
@onready var pop_level: Label = $CanvasLayer/popLevel
@onready var fade_rect: ColorRect = $CanvasLayer/Fade
@onready var door: Area2D = $Door # Make sure you have an Area2D named 'Door' in Level 2!

# -------------------- EXPORTS --------------------
@export_file("res://level_3.tscn") var level3_scene: String # Path to your Level 3

@export var fade_in_time: float = 0.6
@export var visible_time: float = 1.5
@export var fade_out_time: float = 0.6
@export var level_fade_time: float = 0.8

# -------------------- STATE --------------------
var _transitioning: bool = false

# -------------------- READY --------------------
func _ready() -> void:
	Global.has_key = false # Reset key for the new level
	_fade_in_level()
	show_popup()
	
	# Connect the door signal
	if door:
		door.body_entered.connect(_on_door_entered)

# -------------------- LEVEL FADE --------------------
func _fade_in_level() -> void:
	if not fade_rect: return
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, level_fade_time)
	await tween.finished
	fade_rect.visible = false

# -------------------- SHOW POPUP --------------------
func show_popup() -> void:
	if not pop_level: return
	pop_level.visible = true
	pop_level.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(pop_level, "modulate:a", 1.0, fade_in_time)
	tween.tween_interval(visible_time)
	tween.tween_property(pop_level, "modulate:a", 0.0, fade_out_time)
	tween.tween_callback(func(): pop_level.visible = false)

# -------------------- DOOR ENTER & TRANSITION --------------------
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

func _start_level_transition() -> void:
	print("Level 2: Transition triggered!")
	_transitioning = true

	if fade_rect:
		fade_rect.visible = true
		fade_rect.modulate.a = 0.0
		
		var t = create_tween()
		t.tween_property(fade_rect, "modulate:a", 1.0, 0.6)
		
		# Instead of 'await', we use a direct connection
		t.finished.connect(func():
			print("Level 2: Fade complete. Switching NOW.")
			get_tree().change_scene_to_file("res://level_3.tscn")
		)
	else:
		print("Level 2: No fade rect found, switching immediately.")
		get_tree().change_scene_to_file("res://level_3.tscn")
