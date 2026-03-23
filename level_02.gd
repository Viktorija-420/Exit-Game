extends Node2D

# -------------------- NODES --------------------
@onready var pop_level: Label = $CanvasLayer/popLevel
@onready var fade_rect: ColorRect = $CanvasLayer/Fade  # Full-screen fade

# -------------------- EXPORTS --------------------
@export var fade_in_time: float = 0.6
@export var visible_time: float = 1.5
@export var fade_out_time: float = 0.6
@export var level_fade_time: float = 0.8  # Fade-in for the whole level

# -------------------- READY --------------------
func _ready() -> void:
	Global.has_key = false
	_fade_in_level()
	show_popup()

# -------------------- LEVEL FADE --------------------
func _fade_in_level() -> void:
	if not fade_rect:
		return
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0  # start fully black

	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, level_fade_time)
	tween.tween_callback(func():
		fade_rect.visible = false
	)

# -------------------- SHOW POPUP --------------------
func show_popup() -> void:
	if not pop_level:
		return

	pop_level.visible = true
	pop_level.modulate.a = 0.0  # start fully transparent

	var tween = create_tween()
	# Fade in
	tween.tween_property(pop_level, "modulate:a", 1.0, fade_in_time)
	tween.tween_interval(visible_time)
	# Fade out
	tween.tween_property(pop_level, "modulate:a", 0.0, fade_out_time)
	tween.tween_callback(func():
		pop_level.visible = false
)
