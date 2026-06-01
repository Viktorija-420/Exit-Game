extends Area2D
@export_file("*.tscn") var next_level_scene: String = ""
@onready var anim: AnimatedSprite2D = $Sprite2D
@onready var trigger_shape: CollisionShape2D = $TriggerShape
@onready var open_door: AudioStreamPlayer2D = $DoorOpen
@onready var locked_door: AudioStreamPlayer2D = $DoorLocked
var _transitioning := false
var player_ref: CharacterBody2D = null # Saglabā atsauci uz spēlētāju, lai atjauninātu UI paziņojumus
var is_open := false

func _ready() -> void: # Sākotnējā sagatavošanās funkcija durvju objektam
	add_to_group("door")
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)	# Savieno signālus, lai fiksētu, kad spēlētājs pieiet pie durvīm vai aiziet prom
	body_exited.connect(_on_body_exited)
	Global.key_changed.connect(_on_key_changed)
	if anim: anim.play("Closed") 	# Sāk animāciju "Closed"

func _process(_delta: float) -> void: # nepārtraukti pārbauda spēlētāja ievadi
	if player_ref and Global.has_key and is_open and not _transitioning: 	# pāreja uz nākamo līmeni tad, ja spēlētājs ir blakus, ir atslēga, durvis ir vaļā un nenotiek cita pāreja
		if Input.is_action_just_pressed("interact"): # Ja spēlētājs nospiež interakcijas pogu piemēram, "E"
			_try_transition() # Izsauc pāreju uz nākamo līmeni

func _on_key_changed(_has_key: bool) -> void:
	_update_ui()
	
func play_open_animation() -> void: # Durvju atvēršanas animācija un stāvokļa maiņa
	if anim and anim.sprite_frames.has_animation("DoorAnim"):
		open_door.play()
		anim.play("DoorAnim")
		is_open = true # Tagad durvis ir atvērtas
		_update_ui()

func _update_ui() -> void: #UI paziņojumu teksta atjaunināšana spēlētājam
	if player_ref and player_ref.has_node("DoorLabel"):
		var label = player_ref.get_node("DoorLabel") as Label
		if not Global.has_key:
			locked_door.play()
			label.text = "I need a key first"
			label.visible = true
		elif is_open:
			label.text = " "
			label.visible = true
		else:
			label.visible = false

func _on_body_entered(body: Node2D) -> void: # Fiksē spēlētāja ieiešanu durvju zonā
	if body.is_in_group("player"):
		player_ref = body
		_update_ui()

func _on_body_exited(body: Node2D) -> void: #Fiksē spēlētāja iziešanu no durvju tuvuma zonas
	if body.is_in_group("player"):
		if player_ref and player_ref.has_node("DoorLabel"):
			player_ref.get_node("DoorLabel").visible = false
		player_ref = null # Notīra atsauci, kad spēlētājs aiziet prom

func _try_transition() -> void: # pāriet uz nākamo līmeni
	if _transitioning or next_level_scene == "":
		return
	_transitioning = true
	if player_ref and player_ref.has_node("DoorLabel"):# Paslēpj UI tekstu uzreiz pārejas sākumā
		player_ref.get_node("DoorLabel").visible = false
	call_deferred("_reset_key_and_change_scene") # izsauc ainas maiņu nākamajā kadrā

func _reset_key_and_change_scene() -> void: # Atiestata atslēgu un nomaina spēles ainu, līmeni
	Global.has_key = false 
	get_tree().change_scene_to_file(next_level_scene) # Ielādē nākamo līmeni no norādītā faila ceļa
