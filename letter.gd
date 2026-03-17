extends Area2D

@onready var player_near: bool = false
var player_ref: Node = null

var letter_container: Control = null
var subview: SubViewportContainer = null

func _ready():
	# Get CanvasLayer > LetterContainer > SubViewportContainer
	if has_node("CanvasLayer/LetterContainer"):
		letter_container = $CanvasLayer/LetterContainer
		letter_container.visible = false  # hide initially
		
		if letter_container.has_node("SubViewportContainer"):
			subview = letter_container.get_node("SubViewportContainer")
			if subview.has_node("SubViewport"):
				var viewport = subview.get_node("SubViewport")
				viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	else:
		push_warning("LetterContainer not found! Check hierarchy!")

	# Connect signals
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	if not is_connected("body_exited", Callable(self, "_on_body_exited")):
		connect("body_exited", Callable(self, "_on_body_exited"))

func _process(delta):
	if letter_container and letter_container.visible:
		if Input.is_action_just_pressed("ui_cancel"):
			close_letter_view()

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

	# Hide 2D letter
	visible = false
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = true

	# Show letter UI
	if letter_container:
		letter_container.visible = true
	if subview:
		subview.visible = true

		# Reset 3D letter Node3D
		var model_path = "SubViewport/Letter3D"
		if subview.has_node(model_path):
			var letter_node = subview.get_node(model_path)
			letter_node.rotation_degrees = Vector3.ZERO
			letter_node.scale = Vector3.ONE

	# Pause everything else
	get_tree().paused = true

func close_letter_view():
	if letter_container:
		letter_container.visible = false
	if subview:
		subview.visible = false

	# Resume game
	get_tree().paused = false
