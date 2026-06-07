extends Area2D

@export var heal_amount: int = 1
@onready var local_label: Label = $Label 
@onready var anim: Sprite2D = $Sprite2D
@onready var light: PointLight2D = get_node_or_null("PointLight2D")
@onready var drink: AudioStreamPlayer2D = $Drink

var player_near: bool = false # Norāda, vai spēlētājs atrodas eliksīra tuvumā

@export var glow_speed: float = 5.0
@export var glow_min_energy: float = 0.6
@export var glow_max_energy: float = 2.0
var _glow_time: float = 0.0

func _ready() -> void: # Sākotnējā sagatavošanās funkcija potion objektam
	if local_label: 
		local_label.visible = true # Sākumā paslēpj vietējo tekstu virs pudeles
	
	body_entered.connect(_on_body_entered) # Savieno signālus
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void: # pārbauda spēlētāja tuvumu, ievadi un gaismas efektu
	if player_near: # Ja spēlētājs ir pietuvoties eliksīram
		update_labels_visibility()
		
		if Global.lives < Global.max_lives_cap:
			if Input.is_action_just_pressed("Collect"): # Ja spēlētājs nospiež savākšanas pogu
				collect() # savākšanas funkciju
				
	if light: # Apstrādā spīdēšanas (glow) animāciju
		_glow_time += delta * glow_speed
		var t = (sin(_glow_time) + 1.0) / 2.0
		light.energy = lerp(glow_min_energy, glow_max_energy, t)

func update_labels_visibility() -> void: # Kontrolē UI tekstu redzamību
	var ui = _get_ui_node()
	
	if Global.lives >= Global.max_lives_cap:
		# Parāda tekstu virs eliksīra, ja spēlētājam ir pilnas dzīvības, un paslēpj galveno UI
		if local_label: 
			local_label.text = "Already at full health"
			local_label.visible = true
		if ui:
			ui.show_collect_label(false)
	else:
		# Parāda ekrāna UI tekstu, ja nav pilnas dzīvības un paslēpj tekstu virs eliksīra
		if local_label:
			local_label.visible = false
		if ui:
			ui.show_collect_label(true)

func _on_body_entered(body: Node2D) -> void: # Fiksē spēlētāja ieiešanu eliksīra zonā
	if body.is_in_group("player"):
		player_near = true # Spēlētājs ir pietiekami tuvu, lai mijiedarbotos

func _on_body_exited(body: Node2D) -> void: # Fiksē spēlētāja iziešanu no eliksīra zonas
	if body.is_in_group("player"):
		player_near = false
		if local_label: 
			local_label.visible = false # Aizejot prom, paslēpj vietējo tekstu
		
		var ui = _get_ui_node()
		if ui:
			ui.show_collect_label(false) # Paslēpj ekrāna UI paziņojumu

func collect() -> void: # Potion/eliksīra savākšana
	if Global.lives >= Global.max_lives_cap:
		return
		
	drink.play() # Atskaņo dzeršanas skaņas efektu
	
	player_near = false # Nekavējoties atslēdz vizuālos elementus un interakciju
	if anim: anim.visible = false
	if light: light.enabled = false
	if local_label: local_label.visible = false
	
	var ui = _get_ui_node()
	if ui:
		ui.show_collect_label(false) # Paslēpjam ekrāna UI uzreiz pēc izdzeršanas
	
	Global.gain_life(heal_amount) # Atjauno dzīvības

	await drink.finished # Pagaida, kamēr skaņas efekts beidz skanēt
	queue_free() # Pilnībā izdzēš eliksīra objektu

# Automātiskā UI CanvasLayer atrašanas funkcija
func _get_ui_node() -> Node:
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
