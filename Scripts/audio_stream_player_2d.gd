# MusicController.gd
extends AudioStreamPlayer2D

func play_music(path: String):
	var song = load(path)
	if stream == song:
		return # Don't restart if it's already playing
	stream = song
	play()
