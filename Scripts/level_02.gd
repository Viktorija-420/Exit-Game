extends Node2D

# -------------------- NODES --------------------
@onready var pop_level: Label = $CanvasLayer/popLevel
@onready var fade_rect: ColorRect = $CanvasLayer/Fade
@onready var door: Area2D = $Door # Make sure you have an Area2D named 'Door' in Level 2!

# -------------------- EXPORTS --------------------
@export_file("*.tscn") var level3_scene: String # Path to your Level 3

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
	if _transitioning: return

	# Change this condition if Level 2 doesn't require a key!
	if body.is_in_group("player") and Global.has_key:
		_transitioning = true
		_start_level_transition()

func _start_level_transition() -> void:
	if fade_rect:
		fade_rect.visible = true
		fade_rect.modulate.a = 0.0
		var t = create_tween()
		t.tween_property(fade_rect, "modulate:a", 1.0, 0.6)
		t.tween_callback(func(): 
			SceneManager.change_scene_safe(level3_scene)
		)
	else:
		SceneManager.change_scene_safe(level3_scene)
