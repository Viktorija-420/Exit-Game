extends Area2D

@export var heal_amount: int = 1
@onready var local_label: Label = $Label 
@onready var anim: Sprite2D = $Sprite2D
@onready var light: PointLight2D = get_node_or_null("PointLight2D")
@onready var drink: AudioStreamPlayer2D = $Drink
var ui_label_container: CanvasItem # Norāde uz ekrāna (UI) paziņojumu elementu
var player_near: bool = false # Norāda, vai spēlētājs atrodas eliksīra tuvumā
@export var glow_speed: float = 5.0
@export var glow_min_energy: float = 0.6
@export var glow_max_energy: float = 2.0
var _glow_time: float = 0.0
func _ready() -> void: # Sākotnējā sagatavošanās funkcija potion objektam
	var root = get_tree().current_scene
	if root:
		ui_label_container = root.get_node_or_null("UI/Collect") as CanvasItem
	if local_label: local_label.visible = false	# Sākumā paslēpj abus paziņojumu tekstus
	if ui_label_container: ui_label_container.visible = false
	body_entered.connect(_on_body_entered)	# Savieno signālus, lai fiksētu, kad spēlētājs ieiet un iziet no potion zonas
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void: # pārbauda spēlētāja tuvumu, ievadi un gaismas efektu
	if player_near: # Ja spēlētājs ir pietuvoties eliksīram
		update_labels_visibility()
		
		if Global.lives < Global.max_lives_cap:
			if Input.is_action_just_pressed("Collect"): # Ja spēlētājs nospiež savākšanas pogu
				collect() # savākšanas funkciju
	if light:# Apstrādā spīdēšanas (glow) animāciju
		_glow_time += delta * glow_speed
		var t = (sin(_glow_time) + 1.0) / 2.0
		light.energy = lerp(glow_min_energy, glow_max_energy, t)

func update_labels_visibility() -> void: # Kontrolē UI tekstu redzamību
	if Global.lives >= Global.max_lives_cap:
		if local_label: # parāda tekstu virs eliksīra, ja spēlētājam ir pilnas dzīvības, un paslēpj UI
			local_label.text = "Already at full health"
			local_label.visible = true
		if ui_label_container:
			ui_label_container.visible = false
	else:
		if local_label:# parāda ekrāna UI tekstu, ja nav pilnas dzīvības un paslēpj tekstu virs eliksīra
			local_label.visible = false
		if ui_label_container:
			ui_label_container.visible = true

func _on_body_entered(body: Node2D) -> void: # Fiksē spēlētāja ieiešanu eliksīra zonā
	if body.is_in_group("player"):
		player_near = true # Spēlētājs ir pietiekami tuvu, lai mijiedarbotos

func _on_body_exited(body: Node2D) -> void: #Fiksē spēlētāja iziešanu no eliksīra zonas
	if body.is_in_group("player"):
		player_near = false
		if local_label: local_label.visible = false # Aizejot prom, paslēpj abus paziņojumu tekstus
		if ui_label_container: ui_label_container.visible = false

func collect() -> void: # Potion/eliksīra savākšana
	if Global.lives >= Global.max_lives_cap:
		return
	drink.play() # Atskaano dzeršanas skaņas efektu
	
	player_near = false # Nekavējoties atslēdz vizuālos elementus un interakciju, lai nevarētu izdzert vēlreiz
	if anim: anim.visible = false
	if light: light.enabled = false
	if local_label: local_label.visible = false
	if ui_label_container: ui_label_container.visible = false
	
	Global.gain_life(heal_amount) # Izsauc globālo funkciju, lai atjaunotu/palielinātu spēlētāja dzīvības

	await drink.finished # Pagaida, kamēr skaņas efekts beidz skanēt
	queue_free() # Pilnībā izdzēš eliksīra objektu no spēles pasaules
