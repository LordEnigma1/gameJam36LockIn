extends CharacterBody2D
class_name PossessableCharacter

@export var is_possessed: bool = false
@export var speed: float = 300.0
@onready var eject_marker: Marker2D = $ejectMarker


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
	var input_dir: float = 0.0
	var want_jump: bool = false
	var want_jump_release: bool = false
	var want_dash: bool = false

	if is_possessed:
		input_dir = Input.get_axis("left", "right")
		want_jump = Input.is_action_just_pressed("jump")
		want_jump_release = Input.is_action_just_released("jump")
		want_dash = Input.is_action_just_pressed("dash")
	else:
		pass # Future NPC AI goes here 

	
	if not is_on_floor() or velocity.y < 0:
		var current_gravity = base_gravity
		if velocity.y > 0:
			current_gravity *= fall_gravity_multiplier
		velocity.y += current_gravity * delta
	else:
		is_jumping = false

	# Jump
	if want_jump and is_on_floor():
		velocity.y = jump_speed
		is_jumping = true

	# Variable jump height
	if want_jump_release and is_jumping and velocity.y < 0:
		velocity.y *= jump_cut_multiplier
		is_jumping = false

	# Dash
	if want_dash and can_dash:
		is_dashing = true
		can_dash = false
		dash_timer.start()
		dash_cooldown.start()

	# Movement
	if input_dir != 0:
		velocity.x = input_dir * (DASH_SPEED if is_dashing else speed)
		animated_sprite_2d.flip_h = (input_dir < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

# Dash functions
func _on_dash_timer_timeout() -> void:
	is_dashing = false

func _on_dash_cooldown_timeout() -> void:
	can_dash = true
