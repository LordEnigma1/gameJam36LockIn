extends Control


# Called when the node enters the scene tree for the first time.
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _on_texture_button_pressed() -> void:
	
	audio_stream_player_2d.play()
	#aaaaaaxdxdxdxdxdaaaaa
	
	await audio_stream_player_2d.finished



	get_tree().change_scene_to_file("res://Scenes/main.tscn")
