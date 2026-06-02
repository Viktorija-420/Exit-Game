extends Control

# -------------------- CONFIGURATION --------------------
@export var type_speed: float = 0.03 # Seconds per character (lower is faster)

# -------------------- NODES (FIXED PATHS) --------------------
@onready var background: TextureRect = $Background
@onready var speaker_label: Label = $DialogueCanvas/SpeakerLabel
@onready var text_label: Label = $DialogueCanvas/TextLabel
@onready var choice_container: Panel = $DialogueCanvas/ChoiceContainer
@onready var choice_button_1: Button = $DialogueCanvas/ChoiceContainer/ChoiceButton1
@onready var choice_button_2: Button = $DialogueCanvas/ChoiceContainer/ChoiceButton2

# -------------------- ASSETS --------------------
@export var dream_texture: Texture2D
@export var wizard_texture: Texture2D

# -------------------- VARIABLES --------------------
var current_step: int = 0
var tween: Tween

func _ready() -> void:
	# Hide choices initially
	choice_container.visible = false
	
	# Connect button signals
	choice_button_1.pressed.connect(_on_choice_1_pressed)
	choice_button_2.pressed.connect(_on_choice_2_pressed)
	
	# Start the cutscene
	_advance_dialogue()

# Detect mouse clicks or 'ui_accept' (Space/Enter) to progress text
func _input(event: InputEvent) -> void:
	if choice_container.visible:
		return # Disable manual progression when choices are on screen
		
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		# If text is still typing, skip to the end of the line instead of advancing the step
		if tween and tween.is_running():
			tween.kill()
			text_label.visible_characters = -1 # Show all characters immediately
		else:
			_advance_dialogue()

func _advance_dialogue() -> void:
	current_step += 1
	
	match current_step:
		1:
			background.texture = dream_texture
			speaker_label.text = "Player"
			_type_text("Damn, this feels like a dream...")
		2:
			speaker_label.text = "Player"
			_type_text("I still have no idea where I am.")
		3:
			background.texture = wizard_texture
			speaker_label.text = "Wizard"
			_type_text("Don't get ahead of yourself. There is no exit.")
		4:
			speaker_label.text = "Player"
			_type_text("What do you mean? There is a door right behind you...")
		5:
			speaker_label.text = ""
			_type_text("*Awkward silence*")
		6:
			speaker_label.text = "Wizard"
			_type_text("Uhm well about that. Tell me the code first.")
		7:
			# Present Choice 1
			_show_choices("What code?", "3452")
		
		# --- WIZARD TALKS AFTER THE CODE REVEAL ---
		8:
			speaker_label.text = "Wizard"
			_type_text("The code to get out...")
		9:
			# Present Choice 2
			_show_choices("9867", "7049")

# --- TYPEWRITER CORE LOGIC ---
func _type_text(new_text: String) -> void:
	# Kill any running tween to avoid overlapping animations
	if tween:
		tween.kill()
		
	text_label.text = new_text
	text_label.visible_characters = 0 # Hide all text initially
	
	# Calculate total typing time based on character count
	var duration = new_text.length() * type_speed
	
	# Create and run the tween animation
	tween = create_tween()
	tween.tween_property(text_label, "visible_characters", new_text.length(), duration).set_trans(Tween.TRANS_LINEAR)

func _show_choices(choice1_text: String, choice2_text: String) -> void:
	choice_button_1.text = choice1_text
	choice_button_2.text = choice2_text
	choice_container.visible = true

func _on_choice_1_pressed() -> void:
	choice_container.visible = false
	
	if text_label.text == "Uhm well about that. Tell me the code first.":
		_advance_dialogue()
	elif choice_button_1.text == "9867":
		_trigger_bad_ending()

func _on_choice_2_pressed() -> void:
	choice_container.visible = false
	
	if choice_button_2.text == "3452":
		_trigger_bad_ending()
	elif choice_button_2.text == "7049":
		_trigger_good_ending()

func _trigger_bad_ending() -> void:
	speaker_label.text = "Wizard"
	_type_text("Well that's wrong. Too bad.")
	
	await get_tree().create_timer(2.5).timeout
	
	print("Teleporting back to Level 1...")
	get_tree().change_scene_to_file("res://Level_01.tscn")

func _trigger_good_ending() -> void:
	speaker_label.text = "Wizard"
	_type_text("Looks like you have been paying attention.")
	
	await get_tree().create_timer(2.5).timeout
	
	_type_text("Fine, leave. I don't want to see you here anymore.")
	
	await get_tree().create_timer(3.0).timeout
	
	print("Game Cleared! Returning to menu.")
	get_tree().change_scene_to_file("res://MainMenu.tscn")
