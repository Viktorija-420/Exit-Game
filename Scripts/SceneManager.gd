# SceneManager.gd
extends Node

func change_scene_safe(path: String) -> void:
	if path == "":
		push_error("Scene path is empty")
		return
	# Wait one idle frame so any physics callbacks finish
	await get_tree().process_frame
	get_tree().change_scene_to_file(path)
