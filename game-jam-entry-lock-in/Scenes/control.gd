extends Control

func _ready() -> void:
	var caught_label = $caughtLabel
	var status_label = $statusLabel
	
	# Assign to each NPC's VisionPivot
	get_tree().root.get_node("main/policeNpc/VisionPivot").caught_label = caught_label
	get_tree().root.get_node("main/policeNpc/VisionPivot").status_label = status_label
	
	get_tree().root.get_node("main/dogNpc/VisionPivot").caught_label = caught_label
	get_tree().root.get_node("main/dogNpc/VisionPivot").status_label = status_label
	
