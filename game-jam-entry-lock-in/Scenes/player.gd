extends Node2D

@onready var blob_body = $"." # Assuming this script is on your Blob's CharacterBody2D
@onready var possession_area = $PossessionArea
@onready var camera = $Camera2D # The camera currently following the blob

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("possess"): # Map this in Project Settings
		try_possess()

func try_possess() -> void:
	# Get all bodies currently inside our possession radius
	var overlapping_bodies = possession_area.get_overlapping_bodies()
	
	for body in overlapping_bodies:
		if body.is_in_group("possessable") and body != blob_body:
			execute_possession(body)
			return # Stop after possessing the first valid target
			
func execute_possession(target_npc) -> void:
	# 1. Turn off the blob
	blob_body.is_possessed = false
	blob_body.visible = false
	blob_body.set_collision_layer_value(1, false) # Disable blob collision
	blob_body.set_collision_mask_value(1, false)
	
	# 2. Move the camera to the NPC
	camera.reparent(target_npc)
	camera.position = Vector2.ZERO # Center camera on the NPC
	
	# 3. Give control to the NPC
	target_npc.is_possessed = true
