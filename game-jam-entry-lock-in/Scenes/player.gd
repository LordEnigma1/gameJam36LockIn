extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

const DASH_SPEED: float = 600.0
const DASH_DURATION: float = 0.15
const DASH_COOLDOWN: float = 0.5

var is_dashing: bool = false
var last_direction: float = 1.0 

@onready var dash_timer: Timer = $dashTimer
@onready var dash_cooldown_timer: Timer = $dashCooldownTimer

func _ready() -> void:
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timeout)

func _physics_process(delta: float) -> void:
	if is_dashing:
		velocity.x = last_direction * DASH_SPEED
		velocity.y = clamp(velocity.y, -200.0, 200.0)
		move_and_slide()
		return


	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * speed
		last_direction = sign(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer.is_stopped():
		dash()

	move_and_slide()

func dash() -> void:
	is_dashing = true
	dash_timer.start(DASH_DURATION)

func _on_dash_timer_timeout() -> void:
	is_dashing = false
	dash_cooldown_timer.start(DASH_COOLDOWN)

func _on_dash_cooldown_timeout() -> void:
	pass 
