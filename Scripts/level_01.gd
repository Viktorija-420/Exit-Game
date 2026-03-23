extends Node2D

# -------------------- NODES --------------------
@onready var collect_label: Label = $CanvasLayer/popLevel
@onready var door: Area2D = $Door
@onready var keys_anim: AnimatedSprite2D = $KeysAnimation
@onready var fade_rect: ColorRect = $CanvasLayer/Fade   # <-- ADD THIS NODE\
@export var fade_time: float = 0.3

# -------------------- EXPORTS --------------------
@export_file("*.tscn") var level2_scene: String

@export var fade_in_time: float = 0.6
@export var visible_time: float = 3.0
@export var fade_out_time: float = 0.6

# -------------------- STATE --------------------
var _transitioning: bool = false

# -------------------- READY --------------------
func _ready() -> void:
	show_popup()
	
	if fade_rect:
		fade_rect.visible = true
		fade_rect.modulate.a = 1.0
		_fade_in()
		
	if door:
		door.body_entered.connect(_on_door_entered)

# -------------------- POPUP PANEL & KEYS --------------------
func show_popup() -> void:
	# Show panel
	collect_label.visible = true
	collect_label.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(collect_label, "modulate:a", 1.0, fade_in_time)
	tween.tween_interval(visible_time)
	tween.tween_property(collect_label, "modulate:a", 0.0, fade_out_time)
	tween.tween_callback(func() -> void:
		collect_label.visible = false
	)

	# Show keys animation
	if keys_anim:
		keys_anim.visible = true
		keys_anim.modulate.a = 1.0
		keys_anim.play("Keys")

		var key_tween = create_tween()
		key_tween.tween_interval(fade_in_time + visible_time)
		key_tween.tween_property(keys_anim, "modulate:a", 0.0, 0.6)
		key_tween.tween_callback(func() -> void:
			keys_anim.visible = false
		)

# -------------------- DOOR ENTER --------------------
func _on_door_entered(body: Node2D) -> void:
	if _transitioning:
		return

	if body.is_in_group("player") and Global.has_key:
		_transitioning = true
		_start_level2_transition()

# -------------------- FADE & LEVEL TRANSITION --------------------
func _start_level2_transition() -> void:
	var fade_node: ColorRect = null
	var ui_nodes = get_tree().get_nodes_in_group("UI") if get_tree() else []
	if ui_nodes.size() > 0 and ui_nodes[0].has_node("fade"):
		fade_node = ui_nodes[0].get_node("fade") as ColorRect

	if fade_node:
		fade_node.visible = true
		fade_node.modulate.a = 0.0

		var t = create_tween()
		t.tween_property(fade_node, "modulate:a", 1.0, 0.6)
		t.tween_callback(func() -> void:
			SceneManager.change_scene_safe(level2_scene)
		)
	else:
		SceneManager.change_scene_safe(level2_scene)
		
func _fade_out() -> void:
	if not fade_rect:
		return

	fade_rect.visible = true
	var t = create_tween()
	t.tween_property(fade_rect, "modulate:a", 1.0, fade_time)
	await t.finished

func _fade_in() -> void:
	if not fade_rect:
		return

	var t = create_tween()
	t.tween_property(fade_rect, "modulate:a", 0.0, fade_time)
	await t.finished
