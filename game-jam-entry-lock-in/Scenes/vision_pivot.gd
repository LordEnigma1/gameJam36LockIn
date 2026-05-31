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
var caught_label: Label
var status_label: Label
var labels_initialized: bool = false
@onready var caught_timer: Timer = $caughtTime
@onready var slowmo_timer: Timer = $slowmoTime
var main_scene = preload("res://Scenes/main.tscn")
var pulse_tween: Tween
var parent_npc: PossessableCharacter
var is_detecting: bool = false



func _ready() -> void:
	start_rotation = rotation
	var parent = get_parent()
	if parent is PossessableCharacter:
		parent_npc = parent
		line_of_sight.add_exception(parent)
	slowmo_timer.process_mode = Node.PROCESS_MODE_ALWAYS

func _get_labels() -> void:
	if caught_label == null:
		caught_label = get_tree().current_scene.get_node("CanvasLayer/Control/caughtLabel")
		print(name, " found caught_label: ", caught_label)
	if status_label == null:
		status_label = get_tree().current_scene.get_node("CanvasLayer/Control/statusLabel")
		print(name, " found status_label: ", status_label)
		
func _physics_process(delta: float) -> void:
	_get_labels()
	
	if parent_npc and parent_npc.is_possessed:
		vision_polygon.visible = false
		return

	vision_polygon.visible = true
	if has_spotted_player:
		return

	scan_time += delta
	rotation = start_rotation + deg_to_rad(sin(scan_time * scan_speed) * scan_angle)

	check_vision()

	if not caught_timer.is_stopped():
		caught_label.text = "%.1f" % caught_timer.time_left

func check_vision() -> void:
	if has_spotted_player:
		return
	var bodies = vision_area.get_overlapping_bodies()

	for body in bodies:
		if body is TileMap or body is StaticBody2D or "TileMap" in body.name:
			continue

		var is_correct_class = body is PossessableCharacter
		var is_possessed_by_player = false
		if is_correct_class:
			is_possessed_by_player = body.is_possessed

		if is_correct_class and is_possessed_by_player:
			line_of_sight.target_position = line_of_sight.to_local(body.global_position)
			line_of_sight.force_raycast_update()

			if line_of_sight.is_colliding():
				var thing_we_hit = line_of_sight.get_collider()
				if thing_we_hit == body:
					is_detecting = true
					caught_label.visible = true
					status_label.visible = true
					status_label.text = "DETECTED"
					status_label.modulate = Color(1.0, 1.0, 1.0)
					if caught_timer.is_stopped():
						caught_timer.start()
						_start_pulse()
					return

			if is_detecting:
				is_detecting = false
				_reset_caught()
			return
			
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
	status_label.position = Vector2(432.5, 0)
	caught_label.position = Vector2(520.0, 66.0)
	has_spotted_player = false


func _start_pulse() -> void:
	if pulse_tween:
		pulse_tween.kill()
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(status_label, "modulate:a", 0.2, 0.2)
	pulse_tween.tween_property(status_label, "modulate:a", 1.0, 0.2)

# Caught functions
func _on_caught_time_timeout():
	has_spotted_player = true
	if pulse_tween:
		pulse_tween.kill()
		pulse_tween = null
	
	caught_label.visible = false
	status_label.position = Vector2(430.0,66.0)
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
	get_tree().reload_current_scene()
