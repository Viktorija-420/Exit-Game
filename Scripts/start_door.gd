extends Area2D

# The list of possible messages
var messages = [
	"Can't go through this door...",
	"I went through this door already",
	"I will NOT go to the previous level"
]

# We use this to prevent the text from re-triggering while it's already typing
var is_typing: bool = false

func _ready():
	# Connect the signal that detects when something enters the door area
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Check if the body that entered is the player and we aren't already showing text
	if body.is_in_group("player") and not is_typing:
		show_message_on_player(body)

func show_message_on_player(player):
	var label = player.get_node_or_null("DoorLabel")
	
	if label:
		is_typing = true
		
		# 1. Setup the text
		label.text = messages[randi() % messages.size()]
		label.visible_ratio = 0.0 # Start with 0% of text visible
		label.visible = true
		
		# 2. Create the typewriter animation
		var duration = label.text.length() * 0.05 # Adjust 0.05 for speed (smaller is faster)
		var tween = create_tween()
		
		# Animate the visible_ratio from 0 to 1
		tween.tween_property(label, "visible_ratio", 1.0, duration)
		
		# 3. Wait for the typing to finish
		await tween.finished
		
		# 4. Wait a bit so the player can read the full message
		await get_tree().create_timer(1.5).timeout
		
		# 5. Hide and reset
		label.visible = false
		is_typing = false
