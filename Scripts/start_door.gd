extends Area2D
@onready var close_door: AudioStreamPlayer2D = $DoorClose
@onready var locked_door: AudioStreamPlayer2D = $LockedDoor

# Iespējamo paziņojumu saraksts
var messages = [
	"Can't go through this door...",
	"Can't go back",
	"I will NOT go to the previous level"
]

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var is_typing: bool = false
var door_locked: bool = false # Novērš ziņojumus, kamēr durvis nav beigušas aizvērties

func _ready():
	
	await get_tree().create_timer(0.1).timeout
	# 1. Kad līmenis sākas, atskaņo aizvēršanās animāciju
	if anim and anim.sprite_frames.has_animation("StartDoorClose"):
		close_door.play()
		anim.play("StartDoorClose")
		# Pēc izvēles: Pagaida, kamēr animācija beidzas, pirms atļauj teksta aktivizēšanu
		anim.animation_finished.connect(_on_close_animation_finished)
	else:
		door_locked = true # Rezerves variants, ja animācija neeksistē

	body_entered.connect(_on_body_entered)

func _on_close_animation_finished():
	# Kad durvis vizuāli ir aizvērtas, mēs atļaujam "es nevaru atgriezties" loģiku
	door_locked = true
	# Atvieno, lai tas izpildītos tikai vienu reizi līmeņa sākumā
	if anim.animation_finished.is_connected(_on_close_animation_finished):
		anim.animation_finished.disconnect(_on_close_animation_finished)

func _on_body_entered(body):
# Rāda paziņojumus tikai tad, ja spēlētājs ir ienācis un durvis ir aizslēgtas/aizvērtas
	if body.is_in_group("player") and not is_typing and door_locked:
		# --- ŠEIT ATSKAŅO AIZSLĒGTU DURVJU SKAŅU ---
		if locked_door and not locked_door.playing:
			locked_door.play()
			
		show_message_on_player(body)

func show_message_on_player(player):
	# Izmanto get_node_or_null, lai novērstu avārijas, ja label mezgla trūkst
	var label = player.get_node_or_null("DoorLabel")
	
	if label:
		is_typing = true
		
		# Izvēlas nejaušu paziņojumu
		label.text = messages[randi() % messages.size()]
		label.visible_ratio = 0.0 
		label.visible = true
		
		# Izveido rakstāmmašīnas tipa animāciju
		var duration = label.text.length() * 0.05 
		var tween = create_tween()
		
		# Animē teksta parādīšanos
		tween.tween_property(label, "visible_ratio", 1.0, duration)
		
		# Pagaida, kamēr rakstīšana beidzas, tad pagaida 1.5s, tad paslēpj
		await tween.finished
		await get_tree().create_timer(1.5).timeout
		
		label.visible = false
		# Pievieno nelielu atdzišanas laiku, pirms var atkal aktivizēt paziņojumu/skaņu
		await get_tree().create_timer(0.5).timeout 
		is_typing = false
