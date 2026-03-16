extends Control

# -------------------------
# NODES
# -------------------------
@onready var letter_sprite: Node2D = $LetterSprite
@onready var close_button: Button = $CloseButton

# -------------------------
# READY
# -------------------------
func _ready():
	close_button.pressed.connect(Callable(self, "_on_close_pressed"))

# -------------------------
# ROTATION INPUT
# -------------------------
func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		letter_sprite.rotation += deg_to_rad(event.relative.x)

# -------------------------
# CLOSE BUTTON
# -------------------------
func _on_close_pressed():
	queue_free()  # closes the letter UI
