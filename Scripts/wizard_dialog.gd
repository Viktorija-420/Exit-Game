extends CanvasLayer

@export_file("*.tscn") var next_scene: String = "res://level_02.tscn"

@export var fade_in_time: float = 0.6
@export var fade_out_time: float = 0.6
@export var type_speed: float = 0.04

@onready var fade: ColorRect = $Fade
@onready var panel: Panel = $DialogPanel
@onready var text_label: Label = $DialogPanel/TextLabel
@onready var enter_label: Label = $DialogPanel/EnterLabel

# ✅ portraits (they can be TextureRect / Sprite2D / any CanvasItem)
@onready var wiz_portrait: CanvasItem = get_node_or_null("WizLabel") as CanvasItem
@onready var player_portrait: CanvasItem = get_node_or_null("PlayLabel") as CanvasItem

var _dialog := [
	{"name":"Wizard", "text":"So. You made it this far."},
	{"name":"Player", "text":"Move. I’m leaving."},
	{"name":"Wizard", "text":"Leaving? There is no exit. Not a real one."},
	{"name":"Player", "text":"Then why does it feel like you’re hiding something?"},
	{"name":"Wizard", "text":"Because I am."}
]

var _line_index := 0
var _typing := false
var _finished_line := false
var _transitioning := false
var _full_text := ""

func _ready() -> void:
	# Fade setup
	if fade:
		fade.visible = true
		fade.color = Color.BLACK
		fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		fade.modulate.a = 1.0
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel.visible = true
	enter_label.visible = false
	text_label.text = ""

	# ✅ start with both hidden until first line decides
	_set_speaker_portrait("")

	# fade in then start first line
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(fade, "modulate:a", 0.0, fade_in_time)
	t.tween_callback(func(): _play_line(_line_index))

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return

	if _typing:
		_finish_typing()
		return

	if _finished_line:
		_next_line()

func _play_line(index: int) -> void:
	if index >= _dialog.size():
		_go_next_scene()
		return

	_finished_line = false
	enter_label.visible = false

	var speaker := str(_dialog[index]["name"])

	# ✅ swap portraits based on speaker
	_set_speaker_portrait(speaker)

	_full_text = str(_dialog[index]["text"])
	text_label.text = ""

	_start_typing()

func _set_speaker_portrait(speaker: String) -> void:
	# Show only the current speaker portrait. Hide the other.
	# If speaker is unknown, hide both.
	if wiz_portrait:
		wiz_portrait.visible = (speaker.to_lower() == "wizard")
	if player_portrait:
		player_portrait.visible = (speaker.to_lower() == "player")

func _start_typing() -> void:
	_typing = true

	for i in range(_full_text.length()):
		if not _typing:
			return
		text_label.text = _full_text.substr(0, i + 1)
		await get_tree().create_timer(type_speed).timeout

	_typing = false
	_finished_line = true
	enter_label.visible = true

func _finish_typing() -> void:
	text_label.text = _full_text
	_typing = false
	_finished_line = true
	enter_label.visible = true

func _next_line() -> void:
	_line_index += 1
	_play_line(_line_index)

func _go_next_scene() -> void:
	if _transitioning:
		return
	_transitioning = true

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(fade, "modulate:a", 1.0, fade_out_time)
	t.tween_callback(func(): get_tree().change_scene_to_file(next_scene))
