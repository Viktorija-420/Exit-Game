extends Area2D

@onready var light = $PointLight2D

func _process(delta):
	light.energy = 0.8 + randf() * 0.2  # flicker effect
