extends Node2D

# --- Exported variables ---
@export var dialog_scene: PackedScene
@export var idle_time_before_comment: float = 5.0
@export var cloud_duration: float = 3.0  # How long the cloud shows

# --- Onready nodes ---
@onready var area: Area2D = $InteractionArea
@onready var prompt: Label = $PromptLabel
@onready var grumpy_cloud: AnimatedSprite2D = $GrumpyCloud

# --- Internal state ---
var player_in_range: bool = false
var dialog_open: bool = false
var idle_timer: float = 0.0
var idle_comment_triggered: bool = false
var cloud_timer: float = 0.0
var cloud_visible: bool = false
var has_talked: bool = false  # Track if player has already talked

# --- Idle comments ---
var idle_comments := [
	"Are you just gonna stand there or actually say something?",
	"Hello? I can see you, you know.",
	"What's taking you so long?",
	"You gonna talk or just stare?",
	"Don't make me wait all day..."
]

# --- Ready ---
func _ready() -> void:
	randomize()
	prompt.visible = false
	grumpy_cloud.visible = false
	
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

	_floating_cloud()

# --- Process ---
func _process(delta: float) -> void:
	if player_in_range and not dialog_open and not has_talked:
		idle_timer += delta
		if idle_timer >= idle_time_before_comment and not idle_comment_triggered:
			_show_idle_comment()

	if cloud_visible:
		cloud_timer += delta
		if cloud_timer >= cloud_duration:
			grumpy_cloud.visible = false
			cloud_visible = false

	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		if has_talked:
			_show_no_more_to_tell()
		else:
			_open_dialog()

# --- Area signals ---
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		dialog_open = false
		idle_timer = 0.0
		idle_comment_triggered = false
		if not has_talked:
			prompt.text = "Press Enter to talk"
			prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		idle_timer = 0.0
		idle_comment_triggered = false
		prompt.visible = false
		grumpy_cloud.visible = false
		cloud_visible = false

# --- Idle comment ---
func _show_idle_comment() -> void:
	idle_comment_triggered = true
	var comment = idle_comments[randi() % idle_comments.size()]
	prompt.text = comment
	grumpy_cloud.visible = true
	grumpy_cloud.play()
	cloud_visible = true
	cloud_timer = 0.0

# --- Dialog ---
func _open_dialog() -> void:
	if dialog_scene == null:
		return

	dialog_open = true
	prompt.visible = false

	var dialog = dialog_scene.instantiate()
	var root = get_tree().current_scene
	if root:
		root.add_child(dialog)
	else:
		get_tree().get_root().add_child(dialog)

	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and player.has_method("set_controls_enabled"):
		player.set_controls_enabled(false)

	if dialog.has_method("start_dialog"):
		dialog.start_dialog()

	# Mark that the player has talked
	has_talked = true
	# Hide prompt and cloud forever
	prompt.visible = false
	grumpy_cloud.visible = false
	cloud_visible = false

# --- Show "no more to tell" message temporarily ---
func _show_no_more_to_tell() -> void:
	prompt.text = "I don't have anything to tell you anymore."
	prompt.visible = true
	grumpy_cloud.visible = true
	grumpy_cloud.play()
	cloud_visible = true
	cloud_timer = 0.0

	# Temporary display
	await get_tree().create_timer(2.0).timeout
	
	if player_in_range:
		prompt.visible = false
		grumpy_cloud.visible = false
		cloud_visible = false

# --- Animations ---
func _floating_cloud() -> void:
	if grumpy_cloud:
		var tween = create_tween()
		tween.tween_property(grumpy_cloud, "position:y", grumpy_cloud.position.y - 5, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(grumpy_cloud, "position:y", grumpy_cloud.position.y + 5, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.set_loops()
