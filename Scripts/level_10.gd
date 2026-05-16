extends Node2D

# -------------------- NODES --------------------
@onready var fade_rect: ColorRect = $CanvasLayer/Fade
@onready var pop_level: Label = $CanvasLayer/popLevel
@onready var door: Area2D = $Door 
@onready var skeleton_boss: CharacterBody2D = $Skeleton 

var _transitioning: bool = false
var intro_played: bool = false

# -------------------- SETTINGS --------------------
@export var level_fade_time: float = 0.8

# -------------------- READY --------------------
func _ready() -> void:
	Global.has_key = false 
	_fade_in_level()
	show_popup()
	
	if door:
		door.body_entered.connect(_on_door_entered)
		
	# FIXED PATH: Look inside the Skeleton node for the BossTrigger!
	if skeleton_boss and skeleton_boss.has_node("BossTrigger"):
		var trigger = skeleton_boss.get_node("BossTrigger")
		trigger.body_entered.connect(_on_boss_trigger_body_entered)

func _fade_in_level() -> void:
	if not fade_rect: 
		return
		
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, level_fade_time)
	await tween.finished
	fade_rect.visible = false

# -------------------- BOSS TRIGGER CUTSCENE --------------------
func _on_boss_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not intro_played and skeleton_boss:
		intro_played = true
		_run_boss_cutscene(body)

func _run_boss_cutscene(player: CharacterBody2D):
	# 1. Freeze the player completely
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	
	var cam = player.cam
	if not cam: return
	
	var original_zoom = cam.zoom
	var target_zoom = Vector2(1.3, 1.3)
	
	# Calculate exact relative camera positioning
	var offset_to_boss = skeleton_boss.global_position - player.global_position
	offset_to_boss.y -= 40 
	
	# 2. Smoothly slide camera over to the Boss
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cam, "offset", offset_to_boss, 1.5)
	tween.tween_property(cam, "zoom", target_zoom, 1.5)
	
	await tween.finished
	
	# 3. Start the dialogue sequence
	skeleton_boss.play_boss_intro()
	
	# 4. Wait safely inside a loop until the skeleton finishes talking
	while not skeleton_boss.is_intro_done:
		await get_tree().process_frame
	
	# 5. Extra dramatic pause after the big scream shake finishes
	await get_tree().create_timer(0.5).timeout
	
	# 6. Smoothly return camera focus to the player
	var back_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	back_tween.tween_property(cam, "offset", Vector2.ZERO, 1.2)
	back_tween.tween_property(cam, "zoom", original_zoom, 1.2)
	
	await back_tween.finished
	
	# 7. Release control locks! Fight begins!
	player.controls_enabled = true

# -------------------- LEVEL TRANSITION --------------------
func _on_door_entered(body: Node2D) -> void:
	if _transitioning: return

	if body.is_in_group("player"):
		if Global.has_key:
			_transitioning = true
			_start_level_transition()

func show_popup() -> void:
	if not pop_level: 
		return
		
	pop_level.text = "Level Ten"
	pop_level.visible = true
	pop_level.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(pop_level, "modulate:a", 1.0, 0.6)
	tween.tween_interval(1.5)
	tween.tween_property(pop_level, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): pop_level.visible = false)

func _start_level_transition() -> void:
	_transitioning = true

	if fade_rect:
		fade_rect.visible = true
		fade_rect.modulate.a = 0.0
		
		var t = create_tween()
		t.tween_property(fade_rect, "modulate:a", 1.0, 0.6)
		
		t.finished.connect(func():
			print("Level 10: Fade complete. Ready for next scene.")
			#get_tree().change_scene_to_file("res://level_11.tscn")
		)
	#else:
		#print("Level 10: No fade rect found, switching immediately.")
