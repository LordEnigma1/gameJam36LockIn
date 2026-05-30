extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")


#dash mechanic
const DASH_SPEED: float = 450.0
const DASH_DURATION: float = 0.2
var is_dashing: bool = false
var dash_direction: float = 1.0
@onready var dash_timer: Timer = $dashTimer




func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_dashing:
		velocity.x
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var direction := Input.get_axis("left", "right")
	
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
