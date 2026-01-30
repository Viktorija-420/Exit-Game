extends CanvasLayer

@export var fade_in_on_start: bool = true
@export var fade_in_time: float = 0.6

@onready var game_over_label: Label = $GameOverLabel
@onready var fade: ColorRect = $Fade

var hearts: Array[TextureRect] = []
var full_textures: Array[Texture2D] = []
var empty_textures: Array[Texture2D] = []

var _tween: Tween

func _ready() -> void:
	# We will DISPLAY only these hearts (they are placed correctly)
	hearts = [
		_must_get_heart("HeartsHolder/Hearts/heart1"),
		_must_get_heart("HeartsHolder/Hearts/heart2"),
		_must_get_heart("HeartsHolder/Hearts/heart3")
	]

	# We only use these to COPY their textures
	var empty_hearts: Array[TextureRect] = [
		_must_get_heart("HeartsHolder/HeartsEmpty/heart1"),
		_must_get_heart("HeartsHolder/HeartsEmpty/heart2"),
		_must_get_heart("HeartsHolder/HeartsEmpty/heart3")
	]

	# Cache textures
	full_textures.clear()
	empty_textures.clear()

	for i in range(hearts.size()):
		full_textures.append(hearts[i].texture)
		empty_textures.append(empty_hearts[i].texture)

	# Hide the empty row completely (to avoid visual stacking issues)
	var empty_holder: Node = get_node_or_null("HeartsHolder/HeartsEmpty")
	if empty_holder:
		(empty_holder as CanvasItem).visible = false

	game_over_label.visible = false

	# Fade setup
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.z_index = 999
	fade.visible = true
	fade.modulate.a = 1.0

	Global.lives_changed.connect(_on_lives_changed)
	_on_lives_changed(Global.lives)

	if fade_in_on_start:
		fade_in(fade_in_time)
	else:
		fade.visible = false

func _on_lives_changed(lives_value: int) -> void:
	var maxl: int = int(min(Global.max_lives, hearts.size()))
	var lives: int = int(clamp(lives_value, 0, maxl))

	# Swap textures instead of toggling separate nodes
	for i in range(maxl):
		hearts[i].texture = full_textures[i] if i < lives else empty_textures[i]
		hearts[i].visible = true

	game_over_label.visible = (lives <= 0)

func _must_get_heart(path: String) -> TextureRect:
	var node: Node = get_node_or_null(path)
	var heart: TextureRect = node as TextureRect
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
