extends CanvasLayer

# -------------------------
# EXPORTS
# -------------------------
@export var fade_in_time: float = 0.6
@export var fade_out_time: float = 0.6
@export var type_speed: float = 0.04
@export var enter_blink_speed: float = 0.8

# -------------------------
# NODES
# -------------------------
@onready var fade: ColorRect = $Fade
@onready var text_label: Label = $TextLabel
@onready var enter_label: Label = $EnterLabel
@onready var wiz_portrait: CanvasItem = get_node_or_null("WizLabel")
@onready var player_portrait: CanvasItem = get_node_or_null("PlayLabel")
@onready var option_button_1: Button = $Option1
@onready var option_button_2: Button = $Option2

@onready var dialog_bg: TextureRect = $Dialog

# -------------------------
# DIALOG DATA & STATE
# -------------------------
var _dialog := [
	{"name": "Player", "text": "...Hello?"},
	{"name": "Wizard", "text": "Careful where you step."},
	{"name": "Player", "text": "Who are you? Some kind of... janitor?"},
	{"name": "Wizard", "text": "I am the Wizard of the Void. I keep this place in order"},
	
	# BRANCHING POINT (Index 4)
	{"name": "Player", "options": [
		{"text": "Okay, cool.. tell me how do I leave?", "next": 5},
		{"text": "Is there an exit nearby?", "next": 6}
	]},

	# OPTION 1: AGGRESSIVE/DIRECT (Index 5)
	{"name": "Wizard", "text": "Leave? You speak as if there is a door to go to.", "next": 8},

	# OPTION 2: CURIOUS/POLITE (Index 6)
	{"name": "Wizard", "text": "There was a door once. Now there is no exit."},
	{"name": "Wizard", "text": "You can't leave..", "next": 8},

	# CONCLUSION (Index 8)
	{"name": "Wizard", "text": "Now. Please leave me be."}
]

var _line_index := 0
var _typing := false
var _finished_line := false
var _full_text := ""
var _dialog_active := false
var _blink_task = null

# -------------------------
# PUBLIC METHODS
# -------------------------
func start_dialog() -> void:
	_dialog_active = true
	visible = true
	enter_label.visible = true
	text_label.text = ""
	option_button_1.visible = false
	option_button_2.visible = false

	if fade:
		fade.visible = true
		fade.modulate.a = 1.0

	_line_index = 0
	_finished_line = false
	_typing = false

	_blink_enter_label()

	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and player.has_method("set_controls_enabled"):
		player.set_controls_enabled(false)

	var t := create_tween()
	t.tween_property(fade, "modulate:a", 0.0, fade_in_time)
	t.tween_callback(func(): _play_line(_line_index))

# -------------------------
# INPUT HANDLING
# -------------------------
func _unhandled_input(event: InputEvent) -> void:
	if not _dialog_active:
		return
		
	if option_button_1.visible:
		return
		
	if not event.is_action_pressed("ui_accept"):
		return

	if _typing:
		_finish_typing()
		return

	if _finished_line:
		_next_line()

# -------------------------
# DIALOG FLOW
# -------------------------
func _play_line(index: int) -> void:
	if index >= _dialog.size():
		_end_dialog()
		return

	var entry = _dialog[index]
	var speaker = str(entry.get("name", ""))
	
	# Pārbaudām, vai šī ir izvēļu rinda
	if entry.has("options"):
		dialog_bg.visible = false
		text_label.visible = false
		enter_label.visible = false    # Paslēpjam mirgojošo bultiņu
		_set_speaker_portrait(speaker)      # Paslēpjam portretus
		_show_options(entry.options)
		return

	# Ja tas ir parasts teksts, parādām visu atpakaļ
	dialog_bg.visible = true
	text_label.visible = true
	_set_speaker_portrait(speaker)
	
	option_button_1.visible = false
	option_button_2.visible = false
	_finished_line = false
	
	_full_text = str(entry.get("text", ""))
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
	visible = false
	dialog_bg.visible = true
	enter_label.visible = true
	text_label.text = ""
	option_button_1.visible = false
	option_button_2.visible = false
	if fade:
		fade.visible = false

	if _blink_task and _blink_task.is_valid():
		_blink_task = null

	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and player.has_method("set_controls_enabled"):
		player.set_controls_enabled(true)

# -------------------------
# ENTER LABEL BLINKING
# -------------------------
func _blink_enter_label() -> void:
	while _dialog_active:
		enter_label.visible = not enter_label.visible
		await get_tree().create_timer(enter_blink_speed).timeout
		enter_label.visible = true

# -------------------------
# OPTIONS HANDLING
# -------------------------
# -------------------------
# OPTIONS HANDLING
# -------------------------
func _show_options(options: Array) -> void:
	option_button_1.visible = true
	option_button_2.visible = true
	option_button_1.text = options[0].text
	option_button_2.text = options[1].text

	option_button_1.grab_focus()
	# 1. Disconnect previous connections to avoid stacking calls
	# We use 'is_connected' with the Signal object itself in Godot 4
	for connection in option_button_1.pressed.get_connections():
		option_button_1.pressed.disconnect(connection.callable)
	for connection in option_button_2.pressed.get_connections():
		option_button_2.pressed.disconnect(connection.callable)

	# 2. Connect using the new Callable.bind() syntax
	option_button_1.pressed.connect(_on_option_selected.bind(options[0].next))
	option_button_2.pressed.connect(_on_option_selected.bind(options[1].next))
	
func _on_option_selected(next_index: int) -> void:
	option_button_1.visible = false
	option_button_2.visible = false
	
	dialog_bg.visible = true
	
	_line_index = next_index
	_play_line(_line_index)
	
