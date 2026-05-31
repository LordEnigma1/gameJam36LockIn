extends Node2D

@onready var blob_body: PossessableCharacter = get_parent() 
@onready var possession_area: Area2D = $possessionArea
@onready var camera: Camera2D = $"../Camera2D" 

var currently_possessed_npc: PossessableCharacter = null


@export var eject_force_x: float = 800.0
@export var eject_force_y: float = 300.0 

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("possess"): 
		if currently_possessed_npc == null:
			try_possess()
		else:
			eject()

func try_possess() -> void:
	var overlapping_bodies = possession_area.get_overlapping_bodies()
	
	for body in overlapping_bodies:
		if body.is_in_group("possessable") and body is PossessableCharacter:
			var target_npc: PossessableCharacter = body as PossessableCharacter
			
			if target_npc != blob_body:
				execute_possession(target_npc)
				return 
			
func execute_possession(target_npc: PossessableCharacter) -> void:
	blob_body.is_possessed = false
	blob_body.visible = false
	
	blob_body.set_physics_process(false)
	blob_body.velocity = Vector2.ZERO 
	
	var col_shape = blob_body.get_node_or_null("CollisionShape2D")
	if col_shape:
		col_shape.set_deferred("disabled", true)
	
	camera.reparent(target_npc)
	camera.position = Vector2.ZERO 
	
	target_npc.is_possessed = true
	currently_possessed_npc = target_npc

func eject() -> void:
	if currently_possessed_npc.eject_marker:
		blob_body.global_position = currently_possessed_npc.eject_marker.global_position
	else:
		blob_body.global_position = currently_possessed_npc.global_position

	var facing_dir: float = 1.0
	if currently_possessed_npc.animated_sprite_2d and currently_possessed_npc.animated_sprite_2d.flip_h:
		facing_dir = -1.0
	
	camera.reparent(blob_body)
	camera.position = Vector2.ZERO
	
	blob_body.is_possessed = true
	blob_body.visible = true
	
	blob_body.set_physics_process(true)
	var col_shape = blob_body.get_node_or_null("CollisionShape2D")
	if col_shape:
		col_shape.set_deferred("disabled", false)
	
	blob_body.velocity = Vector2(facing_dir * eject_force_x, eject_force_y)
	
	currently_possessed_npc.queue_free()
	currently_possessed_npc = null
