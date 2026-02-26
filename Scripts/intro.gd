extends CanvasLayer

@export_file("*.tscn") var first_level_scene: String = "res://Level_01.tscn"

@export var fade_in_time: float = 0.6
@export var fade_out_time: float = 0.6
@export var type_speed: float = 0.05

@onready var story_label: Label = $StoryLabel
@onready var press_enter: Label = $EnterLabel
@onready var fade: ColorRect = $Fade

var _blink_time := 0.0
var _full_text := ""
var _typing := false
var _finished := false
var _transitioning := false

func _ready() -> void:
	if fade:
		fade.visible = true
		fade.color = Color.BLACK
		fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		fade.modulate.a = 1.0

	_full_text = story_label.text
	story_label.text = ""
	press_enter.visible = false

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(fade, "modulate:a", 0.0, fade_in_time)
	t.tween_callback(_start_typewriter)

func _process(delta: float) -> void:
	if _finished:
		_blink_time += delta
		press_enter.visible = int(_blink_time * 1.5) % 2 == 0

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return

	if _typing:
		_finish_typewriter()
	elif _finished:
		_start_game()

func _start_typewriter() -> void:
	_typing = true

	for i in range(_full_text.length()):
		if not _typing:
			return
		story_label.text = _full_text.substr(0, i + 1)
		await get_tree().create_timer(type_speed).timeout

	_typing = false
	_finished = true
	press_enter.visible = true

func _finish_typewriter() -> void:
	story_label.text = _full_text
	_typing = false
	_finished = true
	press_enter.visible = true

func _start_game() -> void:
	if _transitioning:
		return
	_transitioning = true

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(fade, "modulate:a", 1.0, fade_out_time)
	t.tween_callback(func(): get_tree().change_scene_to_file(first_level_scene))
