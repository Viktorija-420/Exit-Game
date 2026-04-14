extends Area2D

# -------------------- NODES & SETTINGS --------------------
@onready var letter_ui: CanvasLayer = $Letter2 
@onready var letter_container = $Letter2/LetterContainer
@onready var title_label = $Letter2/LetterContainer/Title
@onready var text_label = $Letter2/LetterContainer/Text
@onready var type_sound = $Letter2/Type
@onready var collect_sound = $Letter2/CollectLetter

# Added: SubViewport for the 3D Card
@onready var subview: SubViewportContainer = $Letter2/LetterContainer/SubViewportContainer

@export var type_speed: float = 0.04

# Added: Mouse Rotation/Zoom State
var _dragging: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _rotate_speed: float = 0.5
var _zoom_speed: float = 0.2
var _min_zoom: float = 0.5
var _max_zoom: float = 3.0
var _current_zoom: float = 1.0

# Added: Bop Animation for 3D View
var _bop_amplitude: float = 0.04
var _bop_speed: float = 1.0
var _bop_time: float = 0.0
var _original_position: Vector3 = Vector3.ZERO

var player_in_range: bool = false
var is_typing: bool = false
var time = 0.0
var ui_canvas: CanvasLayer = null

func _ready():
	ui_canvas = get_tree().get_first_node_in_group("ui") 
	letter_ui.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	letter_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Cache the original 3D position for the bop effect
	var letter_node = _get_letter_node()
	if letter_node:
		_original_position = letter_node.position

func _process(delta):
	# 1. WORLD INTERACTION (If UI is closed)
	if not letter_ui.visible:
		time += delta
		if has_node("Sprite2D"):
			$Sprite2D.position.y = sin(time * 5) * 2
		
		if player_in_range and Input.is_action_just_pressed("interact"):
			open_letter()
		return

	# 2. UI VIEW MODE LOGIC (If UI is open)
	var letter_node = _get_letter_node()
	if not letter_node: return

	# Handle 3D Rotation (Mouse Drag)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_viewport().get_mouse_position()
		if _dragging:
			var delta_mouse = mouse_pos - _last_mouse_pos
			letter_node.rotation_degrees.y += delta_mouse.x * _rotate_speed
			letter_node.rotation_degrees.x += delta_mouse.y * _rotate_speed
		else:
			_dragging = true
		_last_mouse_pos = mouse_pos
	else:
		_dragging = false

	# Handle 3D Bop & Zoom
	letter_node.scale = Vector3.ONE * _current_zoom
	_bop_time += delta
	var bop_offset = sin(_bop_time * _bop_speed) * _bop_amplitude
	letter_node.position = _original_position + Vector3(0, bop_offset, 0)

func _input(event):
	if not letter_ui.visible: return
	
	# --- ADD THIS TO HANDLE ESC KEY ---
	if event.is_action_pressed("ui_cancel"): # "ui_cancel" is usually ESC by default
		_on_exit_btn_pressed()
		return
	
	# Your existing zoom logic...
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_current_zoom += _zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_current_zoom -= _zoom_speed
		_current_zoom = clamp(_current_zoom, _min_zoom, _max_zoom)

# Helper to find the 3D model inside your viewport
func _get_letter_node() -> Node3D:
	# Based on your scene tree: LetterContainer -> SubViewportContainer -> SubViewport -> spades-A Cards
	if subview and subview.has_node("SubViewport/spades-A Cards"):
		return subview.get_node("SubViewport/spades-A Cards")
	return null

# -------------------- LETTER LOGIC --------------------

func open_letter():
	if letter_ui.visible: return 
	if collect_sound: collect_sound.play()
	
	if has_node("Sprite2D"): $Sprite2D.visible = false
	if has_node("CollisionShape2D"): $CollisionShape2D.set_deferred("disabled", true)
	
	letter_ui.visible = true
	get_tree().paused = true
	
	# Reset 3D card view state
	var letter_node = _get_letter_node()
	if letter_node:
		letter_node.rotation_degrees = Vector3.ZERO
		_current_zoom = 1.0
	
	get_tree().call_group("ui", "hide_for_letter", true)
	get_tree().call_group("ui", "show_collect_label", false)
	
	start_sequence()

func start_sequence():
	is_typing = true
	await type_text(title_label, "Ace of Diamonds")
	if is_typing:
		await get_tree().create_timer(0.1, true, false, true).timeout
		await type_text(text_label, "This card also has a number behind it.. These cards usefull. atleast for something")
	is_typing = false

func type_text(label_node, full_string):
	label_node.text = ""
	for i in range(full_string.length()):
		if not is_typing: 
			if type_sound: type_sound.stop()
			return
		
		label_node.text += full_string[i]
		
		# Only play if it's not a space
		if full_string[i] != " " and type_sound:
			type_sound.pitch_scale = randf_range(0.9, 1.1)
			type_sound.play()
		
		# Wait for the next character
		await get_tree().create_timer(type_speed, true, false, true).timeout

	# --- MOVE STOP OUTSIDE THE LOOP ---
	# This ensures it only stops once the whole text is done
	if type_sound:
		type_sound.stop()

func _on_exit_btn_pressed():
	is_typing = false
	# Kill the sound immediately when exiting
	if type_sound: 
		type_sound.stop()
	
	get_tree().paused = false
	get_tree().call_group("ui", "hide_for_letter", false)
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		get_tree().call_group("ui", "show_collect_label", true)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		get_tree().call_group("ui", "show_collect_label", false)
