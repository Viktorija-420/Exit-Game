extends Node2D

@export var dialog_scene: PackedScene
@export var idle_time_before_comment: float = 5.0

@onready var area: Area2D = $InteractionArea
@onready var prompt: Label = $PromptLabel
@onready var grumpy_cloud: AnimatedSprite2D = $GrumpyCloud
@export var cloud_duration: float = 3.0  # how long the cloud shows

var player_in_range: bool = false
var dialog_open: bool = false

var idle_timer: float = 0.0
var idle_comment_triggered: bool = false
var cloud_timer: float = 0.0
var cloud_visible: bool = false

func _ready() -> void:
	prompt.visible = false
	prompt.text = "Press E to talk"
	grumpy_cloud.visible = false

	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

	_floating_cloud()  # cloud animation

func _process(delta: float) -> void:
	if player_in_range and not dialog_open:
		# idle timer
		idle_timer += delta
		if idle_timer >= idle_time_before_comment and not idle_comment_triggered:
			_show_idle_comment()

	# cloud timer
	if cloud_visible:
		cloud_timer += delta
		if cloud_timer >= cloud_duration:
			grumpy_cloud.visible = false
			cloud_visible = false

	# Press E to open dialog
	if player_in_range and not dialog_open and Input.is_action_just_pressed("ui_accept"):
		_open_dialog()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		dialog_open = false
		idle_timer = 0.0
		idle_comment_triggered = false
		prompt.text = "Press E to talk"
		prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		idle_timer = 0.0
		idle_comment_triggered = false
		prompt.visible = false
		grumpy_cloud.visible = false
		cloud_visible = false

func _show_idle_comment() -> void:
	idle_comment_triggered = true
	prompt.text = "Are you just gonna stand there or actually say something?"
	grumpy_cloud.visible = true
	grumpy_cloud.play()
	cloud_visible = true
	cloud_timer = 0.0

func _open_dialog() -> void:
	if dialog_scene == null:
		return

	dialog_open = true
	prompt.visible = false

	var dialog = dialog_scene.instantiate()
	# Add to scene root (CanvasLayer works)
	var root = get_tree().current_scene
	if root:
		root.add_child(dialog)
	else:
		get_tree().get_root().add_child(dialog)

	# Disable player control instead of pausing the game
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and player.has_method("set_controls_enabled"):
		player.set_controls_enabled(false)

	if dialog.has_method("start_dialog"):
		dialog.start_dialog()

func _floating_cloud() -> void:
	if grumpy_cloud:
		var tween = create_tween()
		tween.tween_property(grumpy_cloud, "position:y", grumpy_cloud.position.y - 5, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(grumpy_cloud, "position:y", grumpy_cloud.position.y + 5, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.set_loops()
