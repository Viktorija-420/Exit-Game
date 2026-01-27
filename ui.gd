extends CanvasLayer

@onready var lives_label: Label = $Lives

func _process(delta: float) -> void:
	lives_label.text = "Lives: %d" % Global.lives
