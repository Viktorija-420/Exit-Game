extends CanvasLayer

# Where to go when the monologue ends
@export_file("*.tscn") var next_level_scene: String = "res://level_6.tscn"

@export var fade_in_time: float = 0.6
@export var fade_out_time: float = 0.6
@export var type_speed: float = 0.05

@onready var story_label: Label = $StoryLabel
@onready var fade: ColorRect = $Fade

# The dialogue breakdown line-by-line
var dialogue_lines: Array[String] = [
	"*noises in the tower*",
	"How long is this going to take?",
	"It smells bad in here, I need to get out."
]

var current_line_index: int = 0
var _blink_time := 0.0
var _current_full_text := ""
var _typing := false
var _finished_line := false
var _transitioning := false

func _ready() -> void:
	if fade:
		fade.visible = true
		fade.modulate.a = 1.0 # Start completely black

	story_label.text = ""

	# Fade out the black screen to reveal the cutscene background
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(fade, "modulate:a", 0.0, fade_in_time)
	t.tween_callback(_display_current_line)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return

	if _typing:
		# Skip typing animation and show full line immediately
		_finish_typewriter()
	elif _finished_line:
		# Move to next line or exit scene if dialogue is over
		_advance_dialogue()

func _display_current_line() -> void:
	_finished_line = false
	_typing = true
	_current_full_text = dialogue_lines[current_line_index]
	story_label.text = ""
	
	# Typewriter effect loop
	for i in range(_current_full_text.length()):
		if not _typing:
			return
		story_label.text = _current_full_text.substr(0, i + 1)
		await get_tree().create_timer(type_speed).timeout

	_typing = false
	_finished_line = true

func _finish_typewriter() -> void:
	story_label.text = _current_full_text
	_typing = false
	_finished_line = true

func _advance_dialogue() -> void:
	current_line_index += 1
	
	# If there are more lines, type the next one
	if current_line_index < dialogue_lines.size():
		_display_current_line()
	else:
		# All lines are read, proceed to Level 6
		_exit_cutscene()

func _exit_cutscene() -> void:
	if _transitioning:
		return
	_transitioning = true

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(fade, "modulate:a", 1.0, fade_out_time)
	t.tween_callback(func(): 
		get_tree().change_scene_to_file(next_level_scene)
	)
