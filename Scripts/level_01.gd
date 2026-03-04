extends Node2D

@onready var pop_level: Panel = $CanvasLayer/Panel
@onready var door: Area2D = $Door

@export_file("*.tscn") var level2_scene: String = "res://level_02.tscn"

@export var fade_in_time: float = 0.6
@export var visible_time: float = 1.5
@export var fade_out_time: float = 0.6

var _transitioning: bool = false

func _ready() -> void:
	# Show level popup
	show_popup()
	# Connect the door signal safely
	if door:
		door.body_entered.connect(_on_door_entered)

func show_popup() -> void:
	pop_level.visible = true
	pop_level.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(pop_level, "modulate:a", 1.0, fade_in_time)
	tween.tween_interval(visible_time)
	tween.tween_property(pop_level, "modulate:a", 0.0, fade_out_time)
	tween.tween_callback(func(): pop_level.visible = false)

func _on_door_entered(body: Node2D) -> void:
	if _transitioning:
		return
	if body.is_in_group("player") and Global.has_key:
		# defer the transition to avoid physics callback issues
		call_deferred("_transition_to_level2")

func _transition_to_level2() -> void:
	if _transitioning:
		return
	_transitioning = true

	# Optional: fade via UI if you have it
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
	# SAFE: check if get_tree exists
	if get_tree() and level2_scene != "":
		get_tree().change_scene_to_file(level2_scene)
	else:
		push_error("Cannot change to level2: get_tree() is null or level2_scene is empty")
