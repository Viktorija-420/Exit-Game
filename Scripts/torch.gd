extends Area2D

@onready var light = $PointLight2D

var noise = FastNoiseLite.new()
var time_passed := 0.0

func _ready():
	noise.frequency = 2.0

func _process(delta):
	time_passed += delta
	var flicker = noise.get_noise_1d(time_passed) * 0.2
	light.energy = 1.3 + flicker
