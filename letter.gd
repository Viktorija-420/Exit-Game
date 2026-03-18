extends Area2D

@onready var player_near: bool = false
var player_ref: Node = null
var letter_container: Control = null
var subview: SubViewportContainer = null

# Rotation state
var _dragging: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _rotate_speed: float = 0.5  # degrees per pixel dragged

func _ready():
	# ✅ Make this node keep processing even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	if has_node("CanvasLayer/LetterContainer"):
		letter_container = $CanvasLayer/LetterContainer
		letter_container.visible = false

		# ✅ UI should also ignore pause
		letter_container.process_mode = Node.PROCESS_MODE_ALWAYS

		if letter_container.has_node("SubViewportContainer"):
			subview = letter_container.get_node("SubViewportContainer")

			# ✅ SubViewport container also keeps updating
			subview.process_mode = Node.PROCESS_MODE_ALWAYS

			if subview.has_node("SubViewport"):
				var viewport = subview.get_node("SubViewport")
				viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	else:
		push_warning("LetterContainer not found! Check hierarchy!")

	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	if not is_connected("body_exited", Callable(self, "_on_body_exited")):
		connect("body_exited", Callable(self, "_on_body_exited"))

func _process(_delta):
	if not letter_container or not letter_container.visible:
		return

	# Close on Escape
	if Input.is_action_just_pressed("ui_cancel"):
		close_letter_view()
		return

	# Rotation via mouse drag
	var letter_node = _get_letter_node()
	if not letter_node:
		return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_viewport().get_mouse_position()
		if _dragging:
			var delta_mouse = mouse_pos - _last_mouse_pos
			# Drag horizontally → rotate around Y axis
			# Drag vertically   → rotate around X axis
			letter_node.rotation_degrees.y += delta_mouse.x * _rotate_speed
			letter_node.rotation_degrees.x += delta_mouse.y * _rotate_speed
		else:
			_dragging = true
		_last_mouse_pos = mouse_pos
	else:
		_dragging = false

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

	_dragging = false
	
	# ✅ Pause the game (letter + UI will still work)
	get_tree().paused = true

func close_letter_view():
	if letter_container:
		letter_container.visible = false
	if subview:
		subview.visible = false

	_dragging = false
	
	# ✅ Resume game
	get_tree().paused = false
