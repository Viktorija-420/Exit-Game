extends CanvasLayer

@export var fade_in_time: float = 0.6
@export var fade_out_time: float = 0.6
@export var type_speed: float = 0.04

@onready var fade: ColorRect = $Fade
@onready var panel: Panel = $DialogPanel
@onready var text_label: Label = $DialogPanel/TextLabel
@onready var enter_label: Label = $DialogPanel/EnterLabel
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
var _full_text := ""
var _dialog_active := false

func start_dialog() -> void:
	_dialog_active = true
	visible = true  # Show the dialog CanvasLayer
	panel.visible = true
	enter_label.visible = false
	text_label.text = ""
	if fade:
		fade.visible = true
		fade.modulate.a = 1.0

	_line_index = 0
	_finished_line = false
	_typing = false

	# Pause player controls
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and player.has_method("set_controls_enabled"):
		player.set_controls_enabled(false)

	# fade in then show first line
	var t := create_tween()
	t.tween_property(fade, "modulate:a", 0.0, fade_in_time)
	t.tween_callback(func(): _play_line(_line_index))

func _unhandled_input(event: InputEvent) -> void:
	if not _dialog_active:
		return
	if not event.is_action_pressed("ui_accept"):
		return

	if _typing:
		_finish_typing()
		return

	if _finished_line:
		_next_line()

func _play_line(index: int) -> void:
	if index >= _dialog.size():
		_end_dialog()
		return

	_finished_line = false
	enter_label.visible = false

	var speaker := str(_dialog[index]["name"])
	_set_speaker_portrait(speaker)

	_full_text = str(_dialog[index]["text"])
	text_label.text = ""
	_start_typing()

func _set_speaker_portrait(speaker: String) -> void:
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

func _end_dialog() -> void:
	_dialog_active = false

	# hide entire dialog CanvasLayer
	visible = false

	# reset UI for next time
	panel.visible = false
	enter_label.visible = false
	text_label.text = ""
	if fade:
		fade.visible = false

	# Re-enable player controls
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and player.has_method("set_controls_enabled"):
		player.set_controls_enabled(true)
