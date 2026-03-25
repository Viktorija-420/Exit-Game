extends Node

# Preload skaņu, lai tā vienmēr būtu atmiņā
var button_click_sound = preload("res://Assets/Sound/button_bGApOblm.mp3")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Pievienojam signālus
	get_tree().node_added.connect(_on_node_added)
	get_tree().tree_changed.connect(_on_tree_changed)
	
	# Sākotnējā pogu reģistrācija
	_register_all_buttons()

func _on_tree_changed() -> void:
	# FIX: Pārbaudām, vai šis nodes vēl ir kokā pirms prasām get_tree()
	if not is_inside_tree():
		return
		
	_register_all_buttons()

func _on_node_added(node: Node) -> void:
	if node is Button:
		_connect_button(node)

func _register_all_buttons() -> void:
	# Drošības pārbaude
	if not is_inside_tree():
		return
		
	# Efektīvāks veids kā atrast visas pogas visā projektā
	var buttons = get_tree().root.find_children("*", "Button", true, false)
	for btn in buttons:
		_connect_button(btn)

func _connect_button(btn: Button) -> void:
	if not btn.pressed.is_connected(_play_button_sound):
		btn.pressed.connect(_play_button_sound)

func _play_button_sound() -> void:
	var asp = AudioStreamPlayer.new()
	asp.stream = button_click_sound
	asp.bus = "SFX" 
	asp.process_mode = Node.PROCESS_MODE_ALWAYS
	
	add_child(asp)
	asp.play()
	
	asp.finished.connect(asp.queue_free)
