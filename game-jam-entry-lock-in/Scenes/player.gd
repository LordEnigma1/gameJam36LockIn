extends CharacterBody2D

@export var speed: float = 300.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var gravity: float = 500.0

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

func _physics_process(delta: float) -> void:
	if not is_on_floor() or velocity.y < 0:
		var current_gravity = base_gravity
		
		if velocity.y > 0:
			current_gravity *= fall_gravity_multiplier
			
		velocity.y += current_gravity * delta
	else:
		is_jumping = false

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_speed
		is_jumping = true

	if Input.is_action_just_released("jump") and is_jumping and velocity.y < 0:
		velocity.y *= jump_cut_multiplier
		is_jumping = false

	# Dash
	if Input.is_action_just_pressed("dash") and can_dash:
		is_dashing = true
		can_dash = false
		dash_timer.start()
		dash_cooldown.start()

	# Movement
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * (DASH_SPEED if is_dashing else speed)
		animated_sprite_2d.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

# Dash functions
func _on_dash_timer_timeout() -> void:
	is_dashing = false

func _on_dash_cooldown_timeout() -> void:
	can_dash = true
