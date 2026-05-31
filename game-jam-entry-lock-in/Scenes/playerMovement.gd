extends CharacterBody2D
class_name PossessableCharacter

var target_npc: Node2D = null
var is_incubating: bool = false

@export var is_possessed: bool = false:
	set(value):
		is_possessed = value
		_update_collision_layers()

@export var possessed_sprite_frames: SpriteFrames
@export var speed: float = 300.0
@onready var eject_marker: Marker2D = $ejectMarker
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var gravity: float = 500.0
var outline_shader: Shader = preload("res://Scenes/outline_shader.gdshader")

# Dash variables
const DASH_SPEED: float = 1000.0
var is_dashing: bool = false
var can_dash: bool = true
@onready var dash_timer: Timer = $dashTimer
@onready var dash_cooldown: Timer = $dashCooldown

# Jump variables
@export var jump_speed: float = -550.0
@export var base_gravity: float = 1400.0
@export var fall_gravity_multiplier: float = 1.7
@export var jump_cut_multiplier: float = 0.35
var is_jumping: bool = false

# Edge check variables
@onready var edge_check: RayCast2D = $edgeCheck
@onready var wall_check: RayCast2D = $wallCheck
@export var patrol_speed: float = 80.0
var patrol_direction: float = 1.0
var flip_cooldown: float = 0.0

# Incubation phase — player can move but is not yet detectable
var is_incubation_active: bool = false


func _ready() -> void:
	_update_collision_layers()
	if animated_sprite_2d:
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = outline_shader
		shader_mat.set_shader_parameter("line_thickness", 0.0)
		animated_sprite_2d.material = shader_mat


func _update_collision_layers() -> void:
	if is_possessed:
		set_collision_layer_value(3, true)
		set_collision_layer_value(2, false)
	else:
		set_collision_layer_value(3, false)
		set_collision_layer_value(2, true)


func _physics_process(delta: float) -> void:
	var input_dir: float = 0.0
	var want_jump: bool = false
	var want_jump_release: bool = false
	var want_dash: bool = false

	# Allow input during both incubation and full possession
	if is_possessed or is_incubation_active:
		input_dir = Input.get_axis("left", "right")
		want_jump = Input.is_action_just_pressed("jump")
		want_jump_release = Input.is_action_just_released("jump")
		want_dash = Input.is_action_just_pressed("dash")
	elif is_incubating:
		velocity.x = 0
	else:
		_patrol(delta)

	if not is_on_floor() or velocity.y < 0:
		var current_gravity = base_gravity
		if velocity.y > 0:
			current_gravity *= fall_gravity_multiplier
		velocity.y += current_gravity * delta
	else:
		is_jumping = false

	if want_jump and is_on_floor():
		velocity.y = jump_speed
		is_jumping = true

	if want_jump_release and is_jumping and velocity.y < 0:
		velocity.y *= jump_cut_multiplier
		is_jumping = false

	if want_dash and can_dash:
		is_dashing = true
		can_dash = false
		dash_timer.start()
		dash_cooldown.start()

	if is_possessed or is_incubation_active:
		if input_dir != 0:
			velocity.x = input_dir * (DASH_SPEED if is_dashing else speed)
			set_facing_direction(input_dir)
		else:
			velocity.x = move_toward(velocity.x, 0, speed)

	if not is_on_floor():
		animated_sprite_2d.play("jump")
	elif is_dashing:
		animated_sprite_2d.play("dash")
	elif velocity.x != 0:
		animated_sprite_2d.play("move")
	else:
		if animated_sprite_2d.sprite_frames.has_animation("idle"):
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("move")

	move_and_slide()


func _on_dash_timer_timeout() -> void:
	is_dashing = false

func _on_dash_cooldown_timeout() -> void:
	can_dash = true


func _patrol(delta: float) -> void:
	if flip_cooldown > 0:
		flip_cooldown -= delta
	if flip_cooldown <= 0:
		if not edge_check.is_colliding() or wall_check.is_colliding():
			set_facing_direction(patrol_direction * -1.0)
			flip_cooldown = 0.5
	velocity.x = patrol_speed * patrol_direction


func set_facing_direction(dir: float) -> void:
	if dir == 0:
		return
	var facing = 1.0 if dir > 0 else -1.0
	patrol_direction = facing
	animated_sprite_2d.flip_h = (facing < 0)
	if eject_marker:
		eject_marker.position.x = abs(eject_marker.position.x) * facing
	if edge_check:
		edge_check.position.x = abs(edge_check.position.x) * facing
		edge_check.target_position.x = abs(edge_check.target_position.x) * facing
	if wall_check:
		wall_check.position.x = abs(wall_check.position.x) * facing
		wall_check.target_position.x = abs(wall_check.target_position.x) * facing
	var vision_pivot = get_node_or_null("VisionPivot")
	if vision_pivot and vision_pivot.has_method("set_facing"):
		vision_pivot.set_facing(facing)


func show_possessable_outline() -> void:
	if is_possessed:
		hide_possessable_outline()
		return
	if animated_sprite_2d and animated_sprite_2d.material:
		animated_sprite_2d.material.set_shader_parameter("line_thickness", 1.5)


func hide_possessable_outline() -> void:
	if animated_sprite_2d and animated_sprite_2d.material:
		animated_sprite_2d.material.set_shader_parameter("line_thickness", 0.0)


func start_possession_sequence() -> void:
	if is_possessed or is_incubating or is_incubation_active:
		return
	is_incubation_active = true
	hide_possessable_outline()
	var vision_pivot = get_node_or_null("VisionPivot")
	if vision_pivot:
		var polygon = vision_pivot.get_node_or_null("Polygon2D")
		if polygon:
			polygon.visible = false
	
	var tween: Tween = null
	if animated_sprite_2d and animated_sprite_2d.material:
		animated_sprite_2d.material.set_shader_parameter("tint", Color(1.0, 1.0, 1.0, 1.0))
		tween = create_tween()
		tween.tween_method(
			func(c: Color):
				animated_sprite_2d.material.set_shader_parameter("tint", c),
			Color(1.0, 1.0, 1.0, 1.0),
			Color(0.2, 1.0, 0.2, 1.0),
			15.0
		)
	
	await get_tree().create_timer(15.0).timeout
	
	if tween:
		tween.kill()
	
	if possessed_sprite_frames and animated_sprite_2d:
		animated_sprite_2d.sprite_frames = possessed_sprite_frames
		animated_sprite_2d.play()
	if animated_sprite_2d and animated_sprite_2d.material:
		animated_sprite_2d.material.set_shader_parameter("tint", Color(1.0, 1.0, 1.0, 1.0))
	is_incubation_active = false
	is_possessed = true
	_update_collision_layers()
