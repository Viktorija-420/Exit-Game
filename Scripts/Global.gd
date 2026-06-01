extends Node

var player_current_attack = false
signal lives_changed(lives: int) # Signāls, kas paziņo citām ainām, ka mainījies dzīvību skaits
signal key_changed(has_key: bool) # Signāls, kas paziņo, ka spēlētājs ir ieguvis atslēgu

@export var default_max_lives: int = 5
@export var max_lives_cap: int = 6

# Globālie spēles stāvokļa mainīgie, kas saglabājas, pārejot starp līmeņiem
var max_lives: int = 5 
var lives: int = 5
var _has_key: bool = false
var current_level: int = 1
var text_box: String = ""

# --- JAUNIE MAINĪGIE ATGRIEŠANĀS LOĢIKAI ---
var settings_return_path: String = "res://MainMenu.tscn"
var was_paused: bool = false # Atceras, vai mēs aizgājām no pauzes izvēlnes

# Mainīgais ar getter/setter loģiku – automātiski izsauc signālu, kad mainās atslēgas statuss
var has_key: bool:
	get: return _has_key
	set(value):
		_has_key = value
		key_changed.emit(_has_key)

func _ready() -> void: #Sākotnējā spēles stāvokļa inicializācija, kad spēle tiek ieslēgta
	process_mode = Node.PROCESS_MODE_ALWAYS # Nodrošina, ka šis skripts turpina strādāt, pat ja spēle ir nopauzēta
	max_lives = default_max_lives # Iestata sākuma dzīvības
	lives = max_lives

func lose_life(amount: int = 1) -> void: #Dzīvības atņemšana spēlētājam
	lives = max(lives - amount, 0) # Samazina dzīvības
	lives_changed.emit(lives) # Nosūta signālu UI, lai atjauninātu dzīvību indikatoru

func reset_run() -> void: # Pilnīga spēles stāvokļa atiestatīšana
	max_lives = default_max_lives
	lives = max_lives
	has_key = false
	lives_changed.emit(lives)

func restart_current_level() -> void: #Pašreizējā līmeņa pārstartēšana, kad spēlētājs nomirst
	lives = max_lives
	has_key = false # Zaudē atslēgu pēc nāves
	lives_changed.emit(lives)
	get_tree().call_deferred("reload_current_scene") # Pārlādē pašreizējo līmeņa scēnu nākamajā kadrā

func gain_life(amount: int = 1) -> void: # Dzīvību papildināšana
	max_lives = max_lives_cap
	lives = max_lives # Dziedē spēlētāju līdz pilnai dzīvībai
	lives_changed.emit(lives)

func set_music_paused(is_paused: bool): # Fona mūzikas nopauzēšana vai atsākšana
	if is_instance_valid(Music):
		Music.stream_paused = is_paused
	elif has_node("BGMusic"):
		$BGMusic.stream_paused = is_paused
