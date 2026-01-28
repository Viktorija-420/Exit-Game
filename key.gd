extends Area2D

@export var collect_label_path: NodePath

@onready var label: Area2D = get_node(collect_label_path) as Area2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var player_near := false

func _ready() -> void:
	if label:
		label.visible = false

	if anim:
		anim.play()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_near and Input.is_action_just_pressed("Collect"):
		collect()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_near = true
		if label:
			label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_near = false
		if label:
			label.visible = false

func collect() -> void:
	Global.has_key = true

	if label:
		label.visible = false

	call_deferred("queue_free")
