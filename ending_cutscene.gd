extends Control

# -------------------- CONFIGURATION --------------------
@export var type_speed: float = 0.03 # Seconds per character
@export var fade_duration: float = 1.0 # Cik sekundes ilgst fade efekts

# -------------------- NODES (FIXED & NEW PATHS) --------------------
@onready var background: TextureRect = $Background
@onready var speaker_label: Label = $DialogueCanvas/SpeakerLabel
@onready var text_label: Label = $DialogueCanvas/TextLabel
@onready var choice_container: Panel = $DialogueCanvas/ChoiceContainer
@onready var choice_button_1: Button = $DialogueCanvas/ChoiceContainer/ChoiceButton1
@onready var choice_button_2: Button = $DialogueCanvas/ChoiceContainer/ChoiceButton2

# FADE LOGS - No jauna attēla redzams, ka tas atrodas zem DialogueCanvas
@onready var fade_rect: ColorRect = $DialogueCanvas/FadeRect

# THE END MEZGLS - No jauna attēla redzams, ka tas atrodas tieši zem EndingCutscene root
@onready var the_end_label: Label = $TheEndLabel

# -------------------- ASSETS --------------------
@export var dream_texture: Texture2D
@export var wizard_texture: Texture2D
@export var the_end_texture: Texture2D
@onready var talk_sound: AudioStreamPlayer2D = $TalkSound

# -------------------- VARIABLES --------------------
var current_step: int = 0
var tween: Tween
var is_ending_sequence: bool = false # Bloķē peles klikšķus pašās beigās

func _ready() -> void:
	if talk_sound:
		talk_sound.process_mode = Node.PROCESS_MODE_ALWAYS
	choice_container.visible = false
	the_end_label.visible = false # Sākumā paslēpjam beigu uzrakstu
	
	# Sagatavojam fade logu (sākumā caurspīdīgu, bet redzamu)
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	
	choice_button_1.pressed.connect(_on_choice_1_pressed)
	choice_button_2.pressed.connect(_on_choice_2_pressed)
	
	_advance_dialogue()

func _input(event: InputEvent) -> void:
	if choice_container.visible or is_ending_sequence:
		return 
		
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if tween and tween.is_running():
			tween.kill()
			text_label.visible_characters = -1 
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
			_show_choices("What code?", "3452")
		8:
			speaker_label.text = "Wizard"
			_type_text("The code to get out...")
		9:
			_show_choices("9867", "7049")

func _type_text(new_text: String) -> void:
	if tween:
		tween.kill()
		
	text_label.text = new_text
	text_label.visible_characters = 0 
	
	# Loop through characters to play sound
	for i in range(new_text.length()):
		text_label.visible_characters = i + 1
		
		# Play sound if character is not a space
		if new_text[i] != " ":
			# Optional: Adjust pitch based on the speaker
			if speaker_label.text == "Wizard":
				talk_sound.pitch_scale = randf_range(1.8, 1.0)
			else:
				talk_sound.pitch_scale = randf_range(1.1, 1.3)
				
			talk_sound.play()
		
		# Wait for the duration of the type_speed
		await get_tree().create_timer(type_speed).timeout
	
	# Ensure the label is fully visible at the end
	text_label.visible_characters = -1
	talk_sound.stop()
	
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

# -------------------- BEIGU SCENĀRIJI --------------------

func _trigger_bad_ending() -> void:
	speaker_label.text = "Wizard"
	_type_text("Well that's wrong. Too bad.")
	
	await get_tree().create_timer(2.5).timeout
	
	# Melns fade uz Level 1
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	await fade_tween.finished
	
	get_tree().change_scene_to_file("res://Level_01.tscn")


func _trigger_good_ending() -> void:
	is_ending_sequence = true # Apturam spēlētāja klikšķus, lai nevar skippot beigas
	
	speaker_label.text = "Wizard"
	_type_text("Looks like you have been paying attention.")
	await get_tree().create_timer(2.5).timeout
	
	_type_text("Fine, leave. I don't want to see you here anymore.")
	await get_tree().create_timer(3.0).timeout
	
	# 1. Fade OUT uz melnu ekrānu (izmantojot FadeRect, kas atrodas iekš DialogueCanvas)
	var fade_out = create_tween()
	fade_out.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	await fade_out.finished
	
	# 2. Kamēr viss ir melns, paslēpjam VISUS dialogu elementus
	speaker_label.visible = false
	text_label.visible = false
	
	# Paslēpjam pārējās etiķetes un dekoratīvās bildes no DialogueCanvas, lai tās nerēgojas fonā
	if has_node("DialogueCanvas/Label"): $DialogueCanvas/Label.visible = false
	if has_node("DialogueCanvas/WizLabel"): $DialogueCanvas/WizLabel.visible = false
	if has_node("DialogueCanvas/PlayLabel"): $DialogueCanvas/PlayLabel.visible = false
	if has_node("DialogueCanvas/TextureRect"): $DialogueCanvas/TextureRect.visible = false
	if has_node("DialogueCanvas/TextureRect2"): $DialogueCanvas/TextureRect2.visible = false
	
	# Nomainām galveno fonu uz "The End" tekstūru un ieslēdzam "The End" uzrakstu
	background.texture = the_end_texture 
	the_end_label.visible = true
	
	# 3. Fade IN (Noņemam melnumu. Tā kā FadeRect ir DialogueCanvas bērns, tas smuki atklās jauno fonu un TheEndLabel)
	var fade_in = create_tween()
	fade_in.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
	await fade_in.finished
	
	# 4. Spēlētājs skatās uz beigu bildi un uzrakstu 5 sekundes
	await get_tree().create_timer(5.0).timeout
	
	# 5. Gala Fade OUT pirms galvenās izvēlnes
	var final_fade = create_tween()
	final_fade.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	await final_fade.finished
	
	print("Spēle pabeigta! Atgriežamies galvenajā izvēlnē.")
	get_tree().change_scene_to_file("res://MainMenu.tscn")
