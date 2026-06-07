extends Area2D

const COLOR_NORMAL := Color(1.0, 1.0, 1.0, 1.0)       # Default white/unmodulated
const COLOR_HOVER  := Color(0.75, 0.75, 0.75, 1.0)    # Greyish
const COLOR_PRESSED := Color(0.85, 0.65, 0.75, 1.0)    # Pinkish-Grey

@onready var player_near: bool = false
var player_ref: Node = null
var letter_container: Control = null
var subview: SubViewportContainer = null

var _dragging: bool = false # Rotācijas mainīgie kārtij
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _rotate_speed: float = 0.5

var _zoom_speed: float = 0.2 # Zoom iestatījumi kārtij
var _min_zoom: float = 0.5
var _max_zoom: float = 3.0
var _current_zoom: float = 1.0

var _bop_amplitude: float = 0.04 # animācija
var _bop_speed: float = 1.0
var _bop_time: float = 0.0
var _original_position: Vector3 = Vector3.ZERO

@export var type_speed: float = 0.03 # Teksta rakstīšanas animācija
@export var pause_between_title_text: float = 0.3
@onready var title_label: Label = null
@onready var text_label: Label = null

var _typing: bool = false
var _full_title: String = ""
var _full_text: String = ""

@onready var glow_light: PointLight2D = $PointLight2D
@export var blink_speed: float = 2.0      # Cik ātri vēstule mirgo
@export var light_on_energy: float = 2.0  # spīdums
@export var light_off_energy: float = 0.0
var blink_time: float = 0.0
@onready var sprite: Sprite2D = $Letter2

@export var collect_label_path: NodePath
@onready var label: CanvasItem = get_node_or_null(collect_label_path) as CanvasItem

@onready var letter_collect_sound: AudioStreamPlayer2D = $CollectLetter
@onready var type_sound: AudioStreamPlayer2D = $Type

func _ready(): # Atrod UI elementus un sagatavo 3D modeli apskatei
	if label:
		label.visible = false
		
	process_mode = Node.PROCESS_MODE_ALWAYS # Nodrošina, ka skripts strādā arī tad, kad spēle ir nopauzēta
	
	if not body_entered.is_connected(_on_body_entered): # Savieno signālus, ja tie nav pievienoti editorā
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	if has_node("CanvasLayer/LetterContainer"): # Atrod un sagatavo CanvasLayer un tā apakšmezglus
		letter_container = $CanvasLayer/LetterContainer
		letter_container.visible = false
		letter_container.process_mode = Node.PROCESS_MODE_ALWAYS

		if letter_container.has_node("Title"):
			title_label = letter_container.get_node("Title")
		if letter_container.has_node("Text"):
			text_label = letter_container.get_node("Text")

		if letter_container.has_node("SubViewportContainer"):
			subview = letter_container.get_node("SubViewportContainer")
			subview.process_mode = Node.PROCESS_MODE_ALWAYS

			var letter_node = _get_letter_node() # Atrod 3D modeli un piešķir tam sākuma mirdzumu
			if letter_node and letter_node is MeshInstance3D:
				_original_position = letter_node.position
				var mat := StandardMaterial3D.new()
				mat.emission_enabled = true
				mat.emission = Color(1, 0.3, 0.3)
				mat.emission_energy = 1.0
				letter_node.material_override = mat
				
		# -------------------- ExitBTN Setup --------------------
		if letter_container.has_node("ExitBTN"):
			var exit_btn = letter_container.get_node("ExitBTN") as Button
			if exit_btn:
				_setup_button_visuals(exit_btn) # Applies the hover effects!
				if not exit_btn.pressed.is_connected(close_letter_view):
					exit_btn.pressed.connect(close_letter_view)
	else:
		push_warning("LetterContainer not found! Check hierarchy!")
		
func _process(_delta: float) -> void: # Apstrādā mirgošanu, 3D rotāciju un animāciju
	blink_time += _delta
	if glow_light:
		var raw_sine = sin(blink_time * blink_speed)
		var breathing_value = (raw_sine + 1.0) / 2.0
		
		glow_light.energy = lerp(light_off_energy, light_on_energy, breathing_value)
		
		if sprite:
			var pulse_color = lerp(1.0, 1.5, breathing_value)
			sprite.modulate = Color(pulse_color, pulse_color, pulse_color)

	var ui_open = letter_container and letter_container.visible # Pārbauda, vai ir atvērts apskates režīms
	if player_near and not ui_open:
		if Input.is_action_just_pressed("Collect"):
			letter_collect_sound.play()
			pickup() # Izsauc vēstules pacelšanu un apskates režīmu
		return

	if not ui_open: # Pārtrauc funkciju, ja UI logs nav atvērts
		return

	if Input.is_action_just_pressed("ui_cancel"): # Aizver apskates logu, ja nospiež ESC / Atpakaļ pogu
		close_letter_view()
		return

	var letter_node = _get_letter_node()
	if not letter_node:
		return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): #3D modeļa rotēšana ar peles kreiso klikšķi
		var mouse_pos = get_viewport().get_mouse_position()
		if _dragging:
			var delta_mouse = mouse_pos - _last_mouse_pos
			letter_node.rotation_degrees.y += delta_mouse.x * _rotate_speed
			letter_node.rotation_degrees.x += delta_mouse.y * _rotate_speed
		else:
			_dragging = true
		_last_mouse_pos = mouse_pos
	else:
		_dragging = false

	letter_node.scale = Vector3.ONE * _current_zoom # Peldoša, lēkājoša animācija modelim UI režīmā
	_bop_time += _delta
	var bop_offset = sin(_bop_time * _bop_speed) * _bop_amplitude
	letter_node.position = _original_position + Vector3(0, bop_offset, 0)
	
func _input(event): # Zoom ar peles rullīti
	if not letter_container or not letter_container.visible:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_current_zoom += _zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_current_zoom -= _zoom_speed
		_current_zoom = clamp(_current_zoom, _min_zoom, _max_zoom)

func _get_letter_node() -> Node3D: # 3D modeļa atrašana un atgriešana no SubViewport
	if subview and subview.has_node("SubViewport/LetterModel"):
		return subview.get_node("SubViewport/LetterModel")
	return null

func _on_body_entered(body): # Fiksē spēlētāja pienākšanu pie vēstules
	if body.is_in_group("player"):
		player_near = true
		player_ref = body
		get_tree().call_group("ui", "show_collect_label", true)
		if body.has_method("set_current_letter"):
			body.current_letter = self
		if label:
				label.visible = true

func _on_body_exited(body): # Fiksē spēlētāja aiziešanu no vēstules zonas
	if body.is_in_group("player"):
		player_near = false
		player_ref = null
		get_tree().call_group("ui", "show_collect_label", false)
		if body.get("current_letter") == self:
			body.current_letter = null
		if label:
			label.visible = false

func pickup(): # Vēstules pacelšana un spēles pauzēšana apskates režīmam
	if not player_ref:
		return
	get_tree().call_group("ui", "show_collect_label", false)

	visible = false # Padara objektu neredzamu
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = true

	if letter_container: # Aktivizē un parāda UI elementus un 3D Viewportu
		letter_container.visible = true
	if subview:
		subview.visible = true
		var letter_node = _get_letter_node()
		if letter_node:
			letter_node.rotation_degrees = Vector3.ZERO
			letter_node.scale = Vector3.ONE
			_current_zoom = 1.0
			_original_position = letter_node.position

	_dragging = false
	get_tree().call_group("ui", "hide_for_letter", true) # Paslēpj standarta spēles UI
	get_tree().paused = true # Nopauzē pašu spēles gaitu un fiziku pasaulē
	if title_label and text_label: # Sagatavo un palaiž rakstāmmašīnas efekta tekstu
		title_label.text = ""
		text_label.text = ""
		_full_title = "Ace of Diamonds"
		_full_text = "Why would a skeleton keep hold of an envelope with a playing card? Could there be \nsomething written on the back? Better hang onto it… just in case."
		_start_typewriter_sequence()

func close_letter_view(): # Apskates loga aizvēršana un spēles atsākšana
	if letter_container:
		letter_container.visible = false
	if subview:
		subview.visible = false
	_dragging = false
	_typing = false 
	type_sound.stop() # Aptur drukāšanas skaņu
	get_tree().call_group("ui", "hide_for_letter", false) # Atgriež standarta spēles UI
	get_tree().paused = false # Atpauzē spēli

func _start_typewriter_sequence() -> void: # Rakstāmmašīnas teksta izvadīšana
	_typing = true
	await _type_text(title_label, _full_title) # Vispirms uzraksta virsrakstu
	
	if not _typing: return 
	await get_tree().create_timer(pause_between_title_text).timeout # Pagaida mazu brīdi pirms pamatteksta
	
	if not _typing: return
	await _type_text(text_label, _full_text) # Uzraksta pamattekstu
	_typing = false

func _type_text(target_label: Label, full_text: String) -> void: # Burtu pa burtam drukāšanas loģika
	target_label.text = ""
	
	for i in range(full_text.length()):
		if not _typing: # Ja spēlētājs aizver logu ātrāk, nekā teksts pabeidzas, uzreiz pārtrauc ciklu
			type_sound.stop()
			return 
		
		target_label.text = full_text.substr(0, i + 1)
		if full_text[i] != " ": # Ja burts nav tukšums, atskaņo klikšķa skaņu
			type_sound.pitch_scale = randf_range(0.9, 1.1)
			type_sound.play()
			
		await get_tree().create_timer(type_speed).timeout

	type_sound.stop()

# Deprecated explicit signal connector method since setup handled it dynamically above
func _on_exit_btn_pressed() -> void:
	close_letter_view()

func collect() -> void: # Izsauc, ja objekts tiek pilnībā izdzēsts
	Global.has_key = true
	if label:
		label.visible = false

	queue_free()

# Handles texture styling, eliminates theme border clips, and binds mouse interactions
func _setup_button_visuals(btn: Button) -> void:
	if btn == null: return

	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.clip_text = false
	
	# Block default structural shifting styling
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	# Find underlying graphics child safely
	var tex_rect: TextureRect = null
	if btn.get_child_count() > 0:
		tex_rect = btn.get_child(0) as TextureRect

	var is_hovered := false

	btn.mouse_entered.connect(func():
		is_hovered = true
		btn.self_modulate = COLOR_HOVER
		if tex_rect: tex_rect.modulate = COLOR_HOVER
	)
	btn.mouse_exited.connect(func():
		is_hovered = false
		btn.self_modulate = COLOR_NORMAL
		if tex_rect: tex_rect.modulate = COLOR_NORMAL
	)
	btn.button_down.connect(func():
		btn.self_modulate = COLOR_PRESSED
		if tex_rect: tex_rect.modulate = COLOR_PRESSED
	)
	btn.button_up.connect(func():
		var target_color := COLOR_HOVER if is_hovered else COLOR_NORMAL
		btn.self_modulate = target_color
		if tex_rect: tex_rect.modulate = target_color
	)
