extends Node2D

@onready var pop_level: Panel = $CanvasLayer/Panel
@onready var door: Area2D = $Door
@onready var keys_anim: AnimatedSprite2D = $KeysAnimation  # moved outside panel, directly under CanvasLayer

@export_file("*.tscn") var level2_scene: String = "res://level_02.tscn"

@export var fade_in_time: float = 0.6
@export var visible_time: float = 5.0
@export var fade_out_time: float = 0.6

var _transitioning: bool = false


func _ready() -> void:
	show_popup()

	if door:
		door.body_entered.connect(_on_door_entered)


func show_popup() -> void:
	# Show the panel (follows player)
	pop_level.visible = true
	pop_level.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(pop_level, "modulate:a", 1.0, fade_in_time)
	tween.tween_interval(visible_time)
	tween.tween_property(pop_level, "modulate:a", 0.0, fade_out_time)
	tween.tween_callback(func(): pop_level.visible = false)

	# Show keys animation (screen fixed)
	if keys_anim:
		keys_anim.visible = true
		keys_anim.modulate.a = 1.0
		keys_anim.play("Keys")

		var key_tween = create_tween()
		key_tween.tween_interval(fade_in_time + visible_time)  # fade after panel
		key_tween.tween_property(keys_anim, "modulate:a", 0.0, 0.6)
		key_tween.tween_callback(func(): keys_anim.visible = false)


func _on_door_entered(body: Node2D) -> void:
	if _transitioning:
		return

	if body.is_in_group("player") and Global.has_key:
		call_deferred("_transition_to_level2")


func _transition_to_level2() -> void:
	if _transitioning:
		return

	_transitioning = true

	var fade_node: ColorRect = null
	var ui_nodes = get_tree().get_nodes_in_group("UI") if get_tree() else []

	if ui_nodes.size() > 0:
		fade_node = ui_nodes[0].fade if ui_nodes[0].has_method("Fade") else null

	if fade_node:
		fade_node.visible = true
		fade_node.modulate.a = 0.0

		var t = create_tween()
		t.tween_property(fade_node, "modulate:a", 1.0, 0.6)
		t.tween_callback(func(): call_deferred("_change_to_level2"))
	else:
		call_deferred("_change_to_level2")


func _change_to_level2() -> void:
	if get_tree() and level2_scene != "":
		get_tree().change_scene_to_file(level2_scene)
	else:
		push_error("Cannot change to level2: get_tree() is null or level2_scene is empty")
