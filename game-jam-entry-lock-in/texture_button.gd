extends TextureButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.






func _on_texture_button_pressed():
	# Reemplaza "main.tscn" por la ruta exacta de tu nivel si se llama diferente
	get_tree().change_scene_to_file("res://Scenes/main.tscn".tscn") 
