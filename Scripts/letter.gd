extends Area2D

# -------------------- NODES --------------------
@onready var player_near: bool = false
var player_ref: Node = null
var letter_container: Control = null
var subview: SubViewportContainer = null

# Rotation state
var _dragging: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _rotate_speed: float = 0.5

# Zoom settings
var _zoom_speed: float = 0.2
var _min_zoom: float = 0.5
var _max_zoom: float = 3.0
var _current_zoom: float = 1.0

# Bop animation
var _bop_amplitude: float = 0.04
var _bop_speed: float = 1.0
var _bop_time: float = 0.0
var _original_position: Vector3 = Vector3.ZERO

# Typewriter settings
@export var type_speed: float = 0.03
@export var pause_between_title_text: float = 0.3
@onready var title_label: Label = null
@onready var text_label: Label = null

var _typing: bool = false
var _full_title: String = ""
var _full_text: String = ""

@onready var glow_light: PointLight2D = $PointLight2D
@export var blink_speed: float = 2.0      # how fast it blinks
@export var light_on_energy: float = 2.0  # strong glow
@export var light_off_energy: float = 0.0 # fully off
var blink_time: float = 0.0
@onready var sprite: Sprite2D = $Letter2

@export var collect_label_path: NodePath
@onready var label: CanvasItem = get_node_or_null(collect_label_path) as CanvasItem

func _ready():
	if label:
		label.visible = false
		
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect signals manually if they aren't connected in the editor
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	if has_node("CanvasLayer/LetterContainer"):
		letter_container = $CanvasLayer/LetterContainer
		letter_container.visible = false
		letter_container.process_mode = Node.PROCESS_MODE_ALWAYS

		if letter_container.has_node("Title"):
			title_label = letter_container.get_node("Title")
		if letter_container.has_node("Text"):
			text_label = letter_container.get_node("Text")

		if letter_container.has_node("SubViewportContainer"):
			subview = letter_container.get_node("SubViewportContainer")
			subview.process_mode = Node.PROCESS_MODE_ALWAYS

			var letter_node = _get_letter_node()
			if letter_node and letter_node is MeshInstance3D:
				_original_position = letter_node.position
				var mat := StandardMaterial3D.new()
				mat.emission_enabled = true
				mat.emission = Color(1, 0.3, 0.3)
				mat.emission_energy = 1.0
				letter_node.material_override = mat
	else:
		push_warning("LetterContainer not found! Check hierarchy!")
		
func _process(_delta: float) -> void:
	# Handle Blinking (Glow and Sprite Modulate)
	blink_time += _delta
	if glow_light:
		# sin() fluctuates between -1 and 1. 
		# We add 1 and divide by 2 to get a smooth 0.0 to 1.0 range.
		var raw_sine = sin(blink_time * blink_speed)
		var breathing_value = (raw_sine + 1.0) / 2.0
		
		# Use lerp (Linear Interpolation) to move smoothly between your off and on values
		glow_light.energy = lerp(light_off_energy, light_on_energy, breathing_value)
		
		if sprite:
			# This pulses the sprite brightness from normal (1.0) to glowing (1.5)
			var pulse_color = lerp(1.0, 1.5, breathing_value)
			sprite.modulate = Color(pulse_color, pulse_color, pulse_color)

	# --- (The rest of your interaction and UI logic remains the same) ---
	var ui_open = letter_container and letter_container.visible
	if player_near and not ui_open:
		if Input.is_action_just_pressed("Collect"):
			pickup()
		return # Exit here because we aren't in "View Mode" yet

	# --- 2. UI / VIEW MODE LOGIC (Only runs if the letter is being inspected) ---

	# Exit early if the UI is hidden
	if not ui_open:
		return

	# Handle Close Input
	if Input.is_action_just_pressed("ui_cancel"):
		close_letter_view()
		return

	# Reference the 3D model inside the SubViewport
	var letter_node = _get_letter_node()
	if not letter_node:
		return

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

	# Handle 3D Bop (Floating animation in the UI)
	letter_node.scale = Vector3.ONE * _current_zoom
	_bop_time += _delta
	var bop_offset = sin(_bop_time * _bop_speed) * _bop_amplitude
	letter_node.position = _original_position + Vector3(0, bop_offset, 0)
	
func _input(event):
	if not letter_container or not letter_container.visible:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_current_zoom += _zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_current_zoom -= _zoom_speed
		_current_zoom = clamp(_current_zoom, _min_zoom, _max_zoom)

func _get_letter_node() -> Node3D:
	if subview and subview.has_node("SubViewport/LetterModel"):
		return subview.get_node("SubViewport/LetterModel")
	return null

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_near = true
		player_ref = body
		# CALL GROUP INSTEAD OF DIRECT PATH
		get_tree().call_group("ui", "show_collect_label", true)
		if body.has_method("set_current_letter"):
			body.current_letter = self
		if label:
				label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_near = false
		player_ref = null
		# CALL GROUP INSTEAD OF DIRECT PATH
		get_tree().call_group("ui", "show_collect_label", false)
		if body.get("current_letter") == self:
			body.current_letter = null
		if label:
			label.visible = false

func pickup():
	if not player_ref:
		return
	
	# Hide label via group
	get_tree().call_group("ui", "show_collect_label", false)

	visible = false
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = true

	if letter_container:
		letter_container.visible = true
	if subview:
		subview.visible = true
		var letter_node = _get_letter_node()
		if letter_node:
			letter_node.rotation_degrees = Vector3.ZERO
			letter_node.scale = Vector3.ONE
			_current_zoom = 1.0
			_original_position = letter_node.position

	_dragging = false
	get_tree().call_group("ui", "hide_for_letter", true)
	get_tree().paused = true

	if title_label and text_label:
		title_label.text = ""
		text_label.text = ""
		_full_title = "Ace of Diamonds"
		_full_text = "Why would a skeleton keep hold of an envelope with a playing card? Could there be something written on the back? Better hang onto it… just in case."
		_start_typewriter_sequence()

func close_letter_view():
	if letter_container:
		letter_container.visible = false
	if subview:
		subview.visible = false
	_dragging = false
	get_tree().call_group("ui", "hide_for_letter", false)
	get_tree().paused = false

func _start_typewriter_sequence() -> void:
	_typing = true
	await _type_text(title_label, _full_title)
	await get_tree().create_timer(pause_between_title_text).timeout
	await _type_text(text_label, _full_text)
	_typing = false

func _type_text(target_label: Label, full_text: String) -> void:
	target_label.text = ""
	for i in range(full_text.length()):
		target_label.text = full_text.substr(0, i + 1)
		await get_tree().create_timer(type_speed).timeout

func _on_exit_btn_pressed() -> void:
	if letter_container and letter_container.has_node("ExitBTN"):
		var exit_btn = letter_container.get_node("ExitBTN") as Button
		if not exit_btn.is_connected("pressed", Callable(self, "close_letter_view")):
			exit_btn.pressed.connect(close_letter_view)

func collect() -> void:
	Global.has_key = true

	if label:
		label.visible = false

	queue_free()
