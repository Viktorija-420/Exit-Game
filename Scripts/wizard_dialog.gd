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
@onready var talk_sound: AudioStreamPlayer2D = $TalkSound

# -------------------------
# DIALOG DATA & STATE
# -------------------------
var _dialog := [
	{"name": "Player", "text": "...Hello?"},
	{"name": "Wizard", "text": "Careful where you step."},
	{"name": "Player", "text": "Who are you? Some kind of... janitor?"},
	{"name": "Wizard", "text": "I am the Wizard of the Void. I keep this place in order"},
	
	{"name": "Player", "options": [
		{"text": "Okay, cool.. tell me how do I leave?", "next": 5},
		{"text": "Is there an exit nearby?", "next": 6}
	]},

	{"name": "Wizard", "text": "Leave? You speak as if there is a door to go to.", "next": 8},
	{"name": "Wizard", "text": "There was a door once. Now there is no exit."},
	{"name": "Wizard", "text": "You can't leave..", "next": 8},
	{"name": "Wizard", "text": "Now. Please leave me be."}
]

var _line_index := 0
var _typing := false
var _finished_line := false
var _full_text := ""
var _dialog_active := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if talk_sound:
		talk_sound.process_mode = Node.PROCESS_MODE_ALWAYS

# -------------------------
# PUBLIC METHODS
# -------------------------
func start_dialog() -> void:
	get_tree().paused = true
	if Global.has_method("set_music_paused"):
		Global.set_music_paused(true)
	
	_dialog_active = true
	visible = true
	
	enter_label.visible = false
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

	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(fade, "modulate:a", 0.0, fade_in_time)
	t.tween_callback(func(): _play_line(_line_index))

# -------------------------
# INPUT HANDLING
# -------------------------
func _unhandled_input(event: InputEvent) -> void:
	if not _dialog_active: return
	if option_button_1.visible: return
		
	if event.is_action_pressed("ui_accept"):
		if _typing:
			_finish_typing()
		elif _finished_line:
			_next_line()

# -------------------------
# DIALOG FLOW
# -------------------------
func _play_line(index: int) -> void:
	if index >= _dialog.size():
		_end_dialog()
		return

	_line_index = index
	var entry = _dialog[index]
	var speaker = str(entry.get("name", ""))
	
	if entry.has("options"):
		dialog_bg.visible = false
		text_label.visible = false
		enter_label.visible = false
		_set_speaker_portrait(speaker)
		_show_options(entry.options)
		return

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
	var s_lower = speaker.to_lower()
	if wiz_portrait: wiz_portrait.visible = (s_lower == "wizard")
	if player_portrait: player_portrait.visible = (s_lower == "player")

func _start_typing() -> void:
	_typing = true
	enter_label.visible = false
	
	var entry = _dialog[_line_index]
	var speaker_name = str(entry.get("name", "")).to_lower()

	for i in range(_full_text.length()):
		if not _typing or not _dialog_active:
			if talk_sound: talk_sound.stop()
			return
			
		text_label.text = _full_text.substr(0, i + 1)
		
		# Pārbaudām, vai ir jāspēlē skaņa (izlaižam atstarpes)
		if _full_text[i] != " " and talk_sound:
			# Iestatām pitch atkarībā no runātāja
			if speaker_name == "wizard":
				talk_sound.pitch_scale = randf_range(0.8, 1.0) # Zemāka balss burvim
			elif speaker_name == "player":
				talk_sound.pitch_scale = randf_range(1.1, 1.3) # Augstāka balss spēlētājam
			
			talk_sound.play()
			
		await get_tree().create_timer(type_speed, true, false, true).timeout

	_typing = false
	if talk_sound: talk_sound.stop()
	_finished_line = true
	enter_label.visible = true

func _finish_typing() -> void:
	_typing = false
	if talk_sound: talk_sound.stop()
	text_label.text = _full_text
	_finished_line = true
	enter_label.visible = true

func _next_line() -> void:
	if _dialog[_line_index].has("next"):
		_play_line(_dialog[_line_index].next)
	else:
		_play_line(_line_index + 1)

func _end_dialog() -> void:
	get_tree().paused = false
	if Global.has_method("set_music_paused"):
		Global.set_music_paused(false)
		
	_dialog_active = false
	visible = false
	
	if talk_sound: talk_sound.stop()

	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and player.has_method("set_controls_enabled"):
		player.set_controls_enabled(true)

# -------------------------
# ENTER LABEL BLINKING
# -------------------------
func _blink_enter_label() -> void:
	while _dialog_active:
		if _finished_line:
			enter_label.visible = !enter_label.visible
		else:
			enter_label.visible = false
		await get_tree().create_timer(enter_blink_speed, true, false, true).timeout

# -------------------------
# OPTIONS HANDLING
# -------------------------
func _show_options(options: Array) -> void:
	option_button_1.visible = true
	option_button_2.visible = true
	option_button_1.text = options[0].text
	option_button_2.text = options[1].text
	option_button_1.grab_focus()

	if option_button_1.pressed.is_connected(_on_option_selected):
		option_button_1.pressed.disconnect(_on_option_selected)
	if option_button_2.pressed.is_connected(_on_option_selected):
		option_button_2.pressed.disconnect(_on_option_selected)
		
	option_button_1.pressed.connect(_on_option_selected.bind(options[0].next))
	option_button_2.pressed.connect(_on_option_selected.bind(options[1].next))
	
func _on_option_selected(next_index: int) -> void:
	option_button_1.visible = false
	option_button_2.visible = false
	dialog_bg.visible = true
	_play_line(next_index)
