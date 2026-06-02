extends AudioStreamPlayer

func play_music(path: String):
	# Only load/play if it's a new song
	if stream != null and stream.resource_path == path:
		return
		
	stream = load(path)
	play()
