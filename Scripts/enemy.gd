extends CharacterBody2D

@export var small_enemy_scene: PackedScene # Aina mazajiem pretiniekiem
var _is_attacking = false

@export var speed = 50
@export var gravity = 900
@export var lunge_speed = 300.0 # Ātrums straujajam uzbrukuma lēcienam
@export var retreat_speed = 150.0 # Ātrums, ar kādu pretinieks atkāpjas pēc uzbrukuma
var lives = 3

var player_chase = false # Norāda, vai pretinieks seko spēlētājam
var player = null
var can_take_damage = true
var _is_jolting = false # Norāda, vai pretinieks atrodas atsitiena stāvoklī pēc traumas
var _is_retreating = false # vai pretinieks pašlaik atkāpjas
var _retreat_dir = 0 # Atkāpšanās virziens

@onready var hearts_container = $Hearts # Mezgls, kurā tiek glabātas pretinieka dzīvību sirsniņas
@onready var anim = $Anim
@onready var hurtbox: Area2D = $Hurtbox   # Zona, kurā pretinieks saņem triecienus
@onready var enemy_hit_sound: AudioStreamPlayer2D = $EnemyAttack

var is_harmful: bool = false # Aktīvs tikai tad, kad pretinieka uzbrukuma kustība var nodarīt pāri spēlētājam

func _ready(): # Sagatavo sirsniņas, savieno signālus un ignorē sadursmes
	update_hearts()
	if not anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.connect(_on_anim_finished)
	
	if hurtbox: # Savieno hurtbox zonu, lai fiksētu spēlētāja sitienus
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	await get_tree().process_frame # Izmanto collision exception, lai pretinieks fiziski nestumtu spēlētāju vai bossu
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		add_collision_exception_with(players[0])
	var skeletons = get_tree().get_nodes_in_group("skeleton_boss")
	if skeletons.size() > 0:
		add_collision_exception_with(skeletons[0])

func _on_hurtbox_area_entered(area: Area2D): # Fiksē, kad spēlētāja zobens trāpa pretiniekam
	if area.name == "Player_hitbox" and Global.player_current_attack and can_take_damage:
		var player_node = area.get_parent()
		take_damage(1, player_node.global_position.x)

func _physics_process(delta: float) -> void: # Atbild par pretinieka kustības stāvokļiem
	if not is_on_floor():
		velocity.y += gravity * delta # Gravitācijas ietekme, ja pretinieks nav uz zemes

	if _is_jolting: # Atsitiens no traumas
		velocity.x = move_toward(velocity.x, 0, 500 * delta)
	elif _is_attacking: # Uzbrukuma lēciens
		velocity.x = move_toward(velocity.x, 0, 200 * delta)
	elif _is_retreating: # Atkāpšanās prom no spēlētāja
		velocity.x = _retreat_dir * retreat_speed
		anim.play("Walk")
		anim.flip_h = velocity.x < 0
	elif player_chase and player: # Spēlētāja sekošana / distances pārbaude
		var dist = global_position.distance_to(player.global_position)
		if dist < 120: # Ja spēlētājs ir pietiekami tuvu, lec virsū
			_lunge_at_player()
		else: # Ja ir redzeslokā, bet par tālu, stāv uz vietas
			velocity.x = move_toward(velocity.x, 0, speed)
			anim.play("Idle")
			anim.flip_h = (player.global_position.x < global_position.x)
	else: # Miera stāvoklis, kad spēlētājs nav tuvumā
		_play_standard_idle()

	move_and_slide() # Izpilda reālo kustību pasaulē

func _play_standard_idle():
	if not _is_retreating:
		velocity.x = move_toward(velocity.x, 0, speed)
		if anim.animation != "Hurt":
			anim.play("Idle")

func _lunge_at_player(): # Straujš uzbrukuma lēciens uz spēlētāja pusi
	if _is_attacking or _is_retreating or _is_jolting:
		return

	_is_attacking = true
	is_harmful = true # Tagad pretinieks var ievainot spēlētāju
	anim.play("Attack")
	enemy_hit_sound.play()
	var dir = sign(player.global_position.x - global_position.x) 	# Nosaka virzienu uz spēlētāju un piešķir strauju grūdienu
	anim.flip_h = dir < 0
	velocity.x = dir * lunge_speed
	velocity.y = -150 # Neliels palēciens uz augšu uzbrukuma laikā

func _on_anim_finished(): # Fiksē animācijas beigas
	if anim.animation == "Attack":
		_is_attacking = false
		is_harmful = false # Uzbrukums beidzies
		_start_retreat()

func _start_retreat(): # Liek pretiniekam uz laiku pēc uzbrukuma atkāpties atpakaļ
	if _is_retreating:
		return
	if player: # Aprēķina pretējo virzienu no spēlētāja
		_retreat_dir = -sign(player.global_position.x - global_position.x)
	else:
		_retreat_dir = 1
	_is_retreating = true
	await get_tree().create_timer(0.8).timeout # Atkāpjas tieši 0.8 sekundes
	_is_retreating = false
	velocity.x = 0
	anim.play("Idle")

func take_damage(_amount: int, _from_x: float): # Dzīvību atņemšana pretiniekam
	if not can_take_damage:
		return
	lives -= 1
	update_hearts() # Atjaunina vizuālo dzīvību skaitu
	_start_damage_cooldown()

func update_hearts(): # Paslēpj vai parāda sirsniņu sprites virs pretinieka
	if not hearts_container:
		return
	var heart_sprites = hearts_container.get_children()
	for i in range(heart_sprites.size()):
		heart_sprites[i].visible = i < lives # Parāda tikai tik sirsniņas, cik atlicis dzīvību

func _start_damage_cooldown(): # Atsitiena un traumas efekts
	can_take_damage = false
	_is_jolting = true
	is_harmful = false
	modulate = Color(10, 1, 1) # Iekrāso pretinieku spilgti sarkanu

	var knockback_dir = 1 if player and global_position.x > player.global_position.x else -1 	# Aprēķina, uz kuru pusi pretiniekam jāatlec
	velocity.x = knockback_dir * 300
	velocity.y = -250 # Palēciens gaisā no sitiena

	if anim.sprite_frames.has_animation("Hurt"):
		anim.play("Hurt")

	await get_tree().create_timer(0.3).timeout # Traumas animācijas un kontroles zaudēšanas ilgums

	if lives <= 0: # Ja dzīvības ir 0, izsauc minionu parādīšanos un izdzēš pretinieku
		spawn_minions()
		queue_free()
	else: # Ja vēl dzīvs, atgriež parasto krāsu
		modulate = Color(1, 1, 1)
		_is_jolting = false
		can_take_damage = true

func spawn_minions(): # 4 mazāku pretinieku parādīšanās pēc nāves
	if small_enemy_scene == null:
		return

	var spawn_origin = global_position + Vector2(0, -25) # Parādīšanās sākumpunkts
	var num_bats = 4

	for i in range(num_bats):
		var bat = small_enemy_scene.instantiate()
		bat.global_position = spawn_origin

		var angle = i * (PI * 2 / num_bats) # Aprēķina leņķi, lai katrs sikspārnis izlidotu uz savu pusi
		var burst_velocity = Vector2(cos(angle), sin(angle)) * 350.0
		get_tree().root.add_child(bat) # Pievieno jauno objektu spēles pasaulei

		if bat.has_method("apply_burst"):
			bat.apply_burst(burst_velocity) # Iedod sikspārnim sākotnējo izsviešanas ātrumu

func enemy(): pass # Tukša funkcija, kalpo kā "ID/Tags", lai citas ainas atpazītu, ka šis objekts ir pretinieks

func _on_detection_area_body_entered(body): # Redzesloka zona – pamanīja spēlētāju
	if body.is_in_group("player"):
		player = body
		player_chase = true

func _on_detection_area_body_exited(body): # Redzesloka zona – spēlētājs aizbēga prom
	if body == player:
		player = null
		player_chase = false

func _on_enemy_hitbox_body_entered(body): # Pretinieka hitbox uzbrūk spēlētājam
	if body.is_in_group("player") and is_harmful: # Ievaino spēlētāju tikai tad, ja pašlaik izpilda uzbrukuma lēcienu
		body.take_damage(1, global_position.x)

func _on_enemy_hitbox_body_exited(_body):
	pass
