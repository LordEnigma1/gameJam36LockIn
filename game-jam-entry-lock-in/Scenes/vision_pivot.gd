extends Node2D

@onready var vision_area: Area2D = $VisionArea
@onready var line_of_sight: RayCast2D = $LineOfSight
@onready var vision_polygon: Polygon2D = $Polygon2D
@export var scan_speed: float = 2.0
@export var scan_angle: float = 45.0

# Scan variables
var start_rotation: float
var scan_time: float = 0.0
var has_spotted_player: bool = false

# Caught variables
@export var caught_label: Label
@export var status_label: Label
var labels_initialized: bool = false
@onready var caught_timer: Timer = $caughtTime
@onready var slowmo_timer: Timer = $slowmoTime
var main_scene = preload("res://Scenes/main.tscn")
var pulse_tween: Tween
var parent_npc: PossessableCharacter
var is_detecting: bool = false
@export var vision_range: float = 200.0 
@export var ray_count: int = 20


func _ready() -> void:
	slowmo_timer.wait_time = 0.3
	start_rotation = rotation
	var parent = get_parent()
	if parent is PossessableCharacter:
		parent_npc = parent
		line_of_sight.add_exception(parent)
	slowmo_timer.process_mode = Node.PROCESS_MODE_ALWAYS


func _physics_process(delta: float) -> void:
	# FIX 1: The Ghost Timer. If we possess this guard, clean up their UI/Timers before shutting down!
	if parent_npc and parent_npc.is_possessed:
		if is_detecting or not caught_timer.is_stopped():
			_reset_caught() 
		vision_polygon.visible = false
		vision_polygon.polygon = PackedVector2Array() 
		return

	vision_polygon.visible = true
	if has_spotted_player:
		return

	scan_time += delta
	rotation = start_rotation + deg_to_rad(sin(scan_time * scan_speed) * scan_angle)

	_update_vision_polygon()
	check_vision()

	if not caught_timer.is_stopped():
		if caught_label:
			caught_label.text = "%.1f" % caught_timer.time_left

func _update_vision_polygon() -> void:
	var points: PackedVector2Array = [Vector2.ZERO]
	var angle_step = (scan_angle * 2.0) / float(ray_count)
	var space_state = get_world_2d().direct_space_state

	var ray_origin = global_position

	for i in range(ray_count + 1):
		var ray_angle = deg_to_rad(-scan_angle + angle_step * i)
		var local_dir = Vector2(cos(ray_angle), sin(ray_angle))
		var global_dir = global_transform.basis_xform(local_dir).normalized()
		var global_end = ray_origin + global_dir * vision_range

		var query = PhysicsRayQueryParameters2D.create(ray_origin, global_end)
		query.exclude = [get_parent()]
		query.collision_mask = 1

		var result = space_state.intersect_ray(query)
		if result:
			points.append(to_local(result.position))
		else:
			points.append(local_dir * vision_range)

	vision_polygon.polygon = points


func check_vision() -> void:
	if has_spotted_player:
		return
	
	var bodies = vision_area.get_overlapping_bodies()
	var player_found_this_frame = false

	for body in bodies:
		if body is TileMap or body is StaticBody2D or "TileMap" in body.name:
			continue

		if body is PossessableCharacter and body.is_possessed:
			# FIX: Offset the target position upward by 16-20 pixels 
			# to aim at the character's chest/torso instead of their feet!
			var chest_target = body.global_position + Vector2(0, -16)
			
			line_of_sight.target_position = line_of_sight.to_local(chest_target)
			line_of_sight.force_raycast_update()

			if line_of_sight.is_colliding():
				var thing_we_hit = line_of_sight.get_collider()
				if thing_we_hit == body:
					player_found_this_frame = true
					break 

	# Handle UI and Timers
	if player_found_this_frame:
		if not is_detecting:
			is_detecting = true
			if caught_label:
				caught_label.visible = true
			if status_label:
				status_label.visible = true
				status_label.text = "DETECTED"
				status_label.modulate = Color(1.0, 1.0, 1.0)
			if caught_timer.is_stopped():
				caught_timer.start()
				_start_pulse()
	else:
		if is_detecting:
			is_detecting = false
			_reset_caught()


func _reset_caught() -> void:
	if not caught_timer.is_stopped():
		caught_timer.stop()
	if pulse_tween:
		pulse_tween.kill()
		pulse_tween = null
	if caught_label:
		caught_label.visible = false
		caught_label.text = ""
	if status_label:
		status_label.visible = false
		status_label.text = ""
		status_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	has_spotted_player = false


func _start_pulse() -> void:
	if pulse_tween:
		pulse_tween.kill()
	if not status_label:
		return  
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(status_label, "modulate:a", 0.2, 0.2)
	pulse_tween.tween_property(status_label, "modulate:a", 1.0, 0.2)


# Caught functions
func _on_caught_time_timeout() -> void:
	has_spotted_player = true
	if pulse_tween:
		pulse_tween.kill()
		pulse_tween = null
	if caught_label:
		caught_label.visible = false
	if status_label:
		status_label.text = "CAUGHT"
		status_label.modulate = Color(1.0, 0.0, 0.0, 1.0)
		status_label.visible = true
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(status_label, "modulate:a", 0.2, 0.2)
	pulse_tween.tween_property(status_label, "modulate:a", 1.0, 0.2)
	Engine.time_scale = 0.15
	slowmo_timer.start()

func _on_slowmo_time_timeout() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://Scenes/gameover.tscn")

func set_facing(facing: float) -> void:
	if facing > 0:
		start_rotation = 0.0
	else:
		start_rotation = PI
