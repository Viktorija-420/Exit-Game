extends Area2D

@export var blink_speed: float = 2.0 # atslēgas mirgošanas ātrums
@export var light_on_energy: float = 2.5
@export var light_off_energy: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow_light: PointLight2D = $PointLight2D
@onready var key_collect_sound: AudioStreamPlayer2D = $Collect
var _collected: bool = false

var player_near: bool = false # Norāda, vai spēlētājs atrodas atslēgas tuvumā
var blink_time: float = 0.0

func _ready() -> void: # Sagatavo atslēgu
	body_entered.connect(_on_body_entered) # Savieno signālus
	body_exited.connect(_on_body_exited)
	
	# Drošībai spēles sākumā paslēpjam UI caur galveno UI mezglu
	var ui = _get_ui_node()
	if ui: ui.show_collect_label(false)

func _process(delta: float) -> void: # pārbauda spēlētāja ievadi un mirgošanas loģiku
	blink_time += delta
	
	if player_near and not _collected and Input.is_action_just_pressed("Collect"): 
		key_collect_sound.play()
		collect() # Izsauc atslēgas paņemšanas funkciju

	if glow_light: # Atslēgas pulsēšanas loģika
		var is_on = int(blink_time * blink_speed) % 2 == 0
		if is_on: # Kad gaisma ir ieslēgta, palielina enerģiju un padara sprite spilgtāku
			glow_light.energy = light_on_energy
			if sprite:
				sprite.modulate = Color(1.2, 1.2, 1.2)
		else: # Kad gaisma ir izslēgta, samazina enerģiju un padara sprite tumšāku
			glow_light.energy = light_off_energy
			if sprite:
				sprite.modulate = Color(0.8, 0.8, 0.8)

func _on_body_entered(body: Node2D) -> void: # Fiksē spēlētāja ieiešanu atslēgas zonā
	if body.is_in_group("player"):
		player_near = true # Pietiekami tuvu, lai paņemtu atslēgu
		var ui = _get_ui_node()
		if ui:
			ui.show_collect_label(true) # Izmantojam tava CanvasLayer funkciju!

func _on_body_exited(body: Node2D) -> void: # Fiksē spēlētāja iziešanu no atslēgas zonas
	if body.is_in_group("player"):
		player_near = false
		var ui = _get_ui_node()
		if ui:
			ui.show_collect_label(false) # Paslēpjam caur CanvasLayer

func collect() -> void: # Atslēgas savākšana un durvju cutscene
	if _collected: # Drošības barjera atkārtotiem izsaukumiem
		return
	_collected = true
	
	Global.has_key = true # atslēga ir iegūta
	
	var ui = _get_ui_node()
	if ui: ui.show_collect_label(false) # Paslēpjam UI uzrakstu
	
	sprite.visible = false
	if glow_light: glow_light.enabled = false
	
	monitoring = false
	monitorable = false
	
	var player = get_tree().get_first_node_in_group("player") # Atrodam spēlētāju un durvis spēlē (scene tree)
	var door = get_tree().current_scene.find_child("Door", true, false) # Meklē mezglu ar nosaukumu "Door"

	if player and door:
		player.controls_enabled = false # Apturam spēlētāja kustību un vadību uz laiku
		await player.show_door_cutscene(door.global_position) # Izsauc kameras funkciju player skriptā un gaida, kamēr funkcija pabeigta
		player.controls_enabled = true # Atļaujam spēlētājam atkal kustēties

	queue_free() # izdzēš atslēgas objektu

# Palīgfunkcija, kas atrod tavu CanvasLayer scēnā (lai kur tas atrastos)
func _get_ui_node() -> Node:
	# Ja tavs CanvasLayer mezgls ir pievienots kāds specifisks skripts, 
	# mēs varam to atrast pēc metodes, kas tajā eksistē:
	var root = get_tree().current_scene
	if root:
		return _find_ui_by_method(root, "show_collect_label")
	return null

func _find_ui_by_method(node: Node, method_name: String) -> Node:
	if node.has_method(method_name):
		return node
	for child in node.get_children():
		var found = _find_ui_by_method(child, method_name)
		if found:
			return found
	return null
