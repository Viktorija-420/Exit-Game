extends Area2D

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
@export var type_speed: float = 0.04
@export var pause_between_title_text: float = 0.3
@onready var title_label: Label = null
@onready var text_label: Label = null

var _typing: bool = false
var _full_title: String = ""
var _full_text: String = ""


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	if has_node("CanvasLayer/LetterContainer"):
		letter_container = $CanvasLayer/LetterContainer
		letter_container.visible = false
		letter_container.process_mode = Node.PROCESS_MODE_ALWAYS

		# Assign typewriter labels
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

				# --- Add a subtle glow ---
				var mat := StandardMaterial3D.new()
				mat.emission_enabled = true
				mat.emission = Color(1, 0.3, 0.3)  # soft red glow
				mat.emission_energy = 1.0           # adjust brightness
				letter_node.material_override = mat

	else:
		push_warning("LetterContainer not found! Check hierarchy!")
		
		
func _process(_delta):
	if not letter_container or not letter_container.visible:
		return

	if Input.is_action_just_pressed("ui_cancel"):
		close_letter_view()
		return

	var letter_node = _get_letter_node()
	if not letter_node:
		return

	# Handle rotation
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

	letter_node.scale = Vector3.ONE * _current_zoom

	# Bop animation
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
		body.current_letter = self

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_near = false
		player_ref = null
		if body.current_letter == self:
			body.current_letter = null

func pickup():
	if not player_ref:
		return

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

	# Hide UI
	get_tree().call_group("ui", "hide_for_letter", true)

	get_tree().paused = true

	# Start typewriter for Title first, then Text
	if title_label and text_label:
		title_label.text = ""
		text_label.text = ""
		_full_title = "Ace of Diamonds"  # Example, can be dynamic
		_full_text = "Why would a skeleton keep hold of an envelope with a playing card? Could there be something written on the back? Better hang onto it… just in case."
		_start_typewriter_sequence()

func close_letter_view():
	if letter_container:
		letter_container.visible = false
	if subview:
		subview.visible = false

	_dragging = false

	# Show UI again
	get_tree().call_group("ui", "hide_for_letter", false)

	get_tree().paused = false

# --- Typewriter Functions ---
func _start_typewriter_sequence() -> void:
	_typing = true
	await _type_text(title_label, _full_title)
	await get_tree().create_timer(pause_between_title_text).timeout
	await _type_text(text_label, _full_text)
	_typing = false

func _type_text(label: Label, full_text: String) -> void:
	label.text = ""
	for i in range(full_text.length()):
		label.text = full_text.substr(0, i + 1)
		await get_tree().create_timer(type_speed).timeout


func _on_exit_btn_pressed() -> void:
	if letter_container and letter_container.has_node("ExitBTN"):
		var exit_btn = letter_container.get_node("ExitBTN") as Button
		if not exit_btn.is_connected("pressed", Callable(self, "close_letter_view")):
			exit_btn.pressed.connect(close_letter_view)
