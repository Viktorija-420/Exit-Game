extends Area2D
@onready var close_door: AudioStreamPlayer2D = $DoorClose
@onready var locked_door: AudioStreamPlayer2D = $LockedDoor

# The list of possible messages
var messages = [
	"Can't go through this door...",
	"Can't go back",
	"I will NOT go to the previous level"
]

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var is_typing: bool = false
var door_locked: bool = false # Prevents messages until the door is finished closing

func _ready():
	
	await get_tree().create_timer(0.1).timeout
	# 1. When the level starts, play the closing animation
	if anim and anim.sprite_frames.has_animation("StartDoorClose"):
		close_door.play()
		anim.play("StartDoorClose")
		# Optional: Wait for animation to finish before allowing text triggers
		anim.animation_finished.connect(_on_close_animation_finished)
	else:
		door_locked = true # Fallback if no animation exists

	body_entered.connect(_on_body_entered)

func _on_close_animation_finished():
	# Once the door is visually closed, we allow the "I can't go back" logic
	door_locked = true
	# Disconnect so it only runs once at the start of the level
	if anim.animation_finished.is_connected(_on_close_animation_finished):
		anim.animation_finished.disconnect(_on_close_animation_finished)

func _on_body_entered(body):
# Only show messages if the player entered and the door is locked/closed
	if body.is_in_group("player") and not is_typing and door_locked:
		# --- PLAY LOCKED SOUND HERE ---
		if locked_door and not locked_door.playing:
			locked_door.play()
			
		show_message_on_player(body)

func show_message_on_player(player):
	# Using get_node_or_null to prevent crashes if the label is missing
	var label = player.get_node_or_null("DoorLabel")
	
	if label:
		is_typing = true
		
		# Pick a random message
		label.text = messages[randi() % messages.size()]
		label.visible_ratio = 0.0 
		label.visible = true
		
		# Create the typewriter animation
		var duration = label.text.length() * 0.05 
		var tween = create_tween()
		
		# Animate the text appearing
		tween.tween_property(label, "visible_ratio", 1.0, duration)
		
		# Wait for typing to finish, then wait 1.5s, then hide
		await tween.finished
		await get_tree().create_timer(1.5).timeout
		
		label.visible = false
		# Adding a small cooldown before they can trigger the message/sound again
		await get_tree().create_timer(0.5).timeout 
		is_typing = false
