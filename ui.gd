extends CanvasLayer

@export var fade_in_on_start: bool = true
@export var fade_in_time: float = 0.6

@onready var game_over_label: Label = $GameOverLabel
@onready var fade: ColorRect = $Fade

var full_hearts: Array[TextureRect] = []
var empty_hearts: Array[TextureRect] = []

var _tween: Tween

func _ready() -> void:
# pilnās sirsniņas
	full_hearts = [
		_must_get_heart("HeartsHolder/Hearts/heart1"),
		_must_get_heart("HeartsHolder/Hearts/heart2"),
		_must_get_heart("HeartsHolder/Hearts/heart3")
	]

# tukšas sirsniņas
	empty_hearts = [
		_must_get_heart("HeartsHolder/HeartsEmpty/heart1"),
		_must_get_heart("HeartsHolder/HeartsEmpty/heart2"),
		_must_get_heart("HeartsHolder/HeartsEmpty/heart3")
	]

	game_over_label.visible = false

	# Fade setup
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.z_index = 999
	fade.visible = true
	fade.modulate.a = 1.0

	_update_hearts()

	if fade_in_on_start:
		fade_in(fade_in_time)
	else:
		fade.visible = false

func _process(_delta: float) -> void:
	_update_hearts()

func _update_hearts() -> void:
	var lives: int = clamp(Global.lives, 0, 3)

	for i: int in range(3):
		# If i < lives => that heart is still full
		full_hearts[i].visible = (i < lives)
		# If i >= lives => that heart is lost -> show emptyzy
		empty_hearts[i].visible = (i >= lives)

	game_over_label.visible = (lives <= 0)

func _must_get_heart(path: String) -> TextureRect:
	var node: Node = get_node(path)
	var heart := node as TextureRect
	if heart == null:
		push_error("UI: Node at '%s' is not a TextureRect (or path is wrong)." % path)
	return heart

func fade_in(time: float = 0.5) -> void:
	_kill_tween()
	fade.visible = true
	fade.modulate.a = 1.0

	_tween = create_tween()
	_tween.tween_property(fade, "modulate:a", 0.0, time)
	_tween.finished.connect(func() -> void:
		fade.visible = false
	)

func fade_out(time: float = 0.5) -> void:
	_kill_tween()
	fade.visible = true
	fade.modulate.a = 0.0

	_tween = create_tween()
	_tween.tween_property(fade, "modulate:a", 1.0, time)

func _kill_tween() -> void:
	if _tween:
		_tween.kill()
	_tween = null
