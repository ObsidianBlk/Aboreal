extends KinematicBody2D
class_name Player



# ----------------------------------------------------------------
# ENUMs and Constants
# ----------------------------------------------------------------
enum STATE {IDLE, MOVE, AIR, HURT}

const IDLE_THRESHOLD = 1.0
const FLOAT_THRESHOLD = 10.0


# ----------------------------------------------------------------
# Export Variables
# ----------------------------------------------------------------
export (float, 0.0) var gravity = 150
export (float, 0.0) var max_walk_speed =  20
export (float, 0.0) var max_run_speed = 200
export (float, 0.1) var walk_accel =  30
export (float, 0.1) var run_accel = 100
export (float, 0.0, 1.0) var walk_friction = 0.25
export (float, 0.0, 1.0) var run_friction = 0.15
export (float, 0.0) var jump_force = 60

# ----------------------------------------------------------------
# Variables
# ----------------------------------------------------------------
var _velocity = Vector2.ZERO
var _state = STATE.IDLE


# ----------------------------------------------------------------
# Onready Variables
# ----------------------------------------------------------------
onready var anim_node = get_node("Anim")
onready var sprite_node = get_node("Sprite")

# ----------------------------------------------------------------
# Override Methods
# ----------------------------------------------------------------
func _physics_process(delta : float) -> void:
	match(_state):
		STATE.IDLE:
			_ProcessIdleState(delta)
		STATE.MOVE:
			_ProcessMoveState(delta)
		STATE.AIR:
			_ProcessAirState(delta)
		STATE.HURT:
			_ProcessHurtState(delta)

# ----------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------
func _ProcessIdleState(delta : float) -> void:
	if not is_on_floor():
		_state = STATE.AIR
		return
		
	if _velocity.length() > IDLE_THRESHOLD:
		_state = STATE.MOVE
		return
	
	_PlayIfNotCurrent("idle")

	_ProcessUserJump(delta)
	_ProcessUserMovement(delta)


func _ProcessMoveState(delta : float) -> void:
	if not is_on_floor():
		_state = STATE.AIR
		return
	
	var vlen = _velocity.length()
	if vlen <= IDLE_THRESHOLD:
		_state = STATE.IDLE
		return
	
	if vlen <= max_walk_speed:
		_PlayIfNotCurrent("walk")
	elif vlen > max_walk_speed:
		_PlayIfNotCurrent("run")

	_ProcessUserJump(delta)
	_ProcessUserMovement(delta)


func _ProcessAirState(delta : float) -> void:
	if is_on_floor():
		if abs(_velocity.x) <= IDLE_THRESHOLD:
			_state = STATE.IDLE
		else:
			_state = STATE.MOVE
		return
	
	if abs(_velocity.y) <= FLOAT_THRESHOLD:
		_PlayIfNotCurrent("float")
	else:
		if _velocity.y < 0.0:
			_PlayIfNotCurrent("lifting")
		else:
			_PlayIfNotCurrent("falling")
	
	_velocity.y += gravity * delta
	_ProcessUserMovement(delta)

func _ProcessHurtState(delta : float) -> void:
	pass


func _ProcessUserJump(delta : float) -> void:
	if Input.is_action_just_pressed("jump"):
		_velocity.y -= jump_force

func _ProcessUserMovement(delta : float) -> void:
	var direction = 0
	var enable_run = false
	if Input.is_action_pressed("left"):
		direction -= 1
	if Input.is_action_pressed("right"):
		direction += 1
	if Input.is_action_pressed("mod_shift"):
		enable_run = true
	
	var running = abs(_velocity.x) > max_walk_speed
	if direction != 0:
		if sign(direction) != sign(_velocity.x):
			_velocity.x = 0.0
		var acceleration = run_accel if enable_run else walk_accel
		var speed = max_run_speed if enable_run else max_walk_speed
		_velocity.x = _Bound(
			_velocity.x + (direction * acceleration * delta),
			-speed, speed
		)
		if _velocity.x > 0.0 and sprite_node.scale.x < 0.0:
			sprite_node.scale.x = 1.0
		elif _velocity.x < 0.0 and sprite_node.scale.x > 0.0:
			sprite_node.scale.x = -1.0
	else:
		var friction = run_friction if running else walk_friction
		_velocity.x = lerp(_velocity.x, 0.0, friction)
	_velocity = move_and_slide_with_snap(_velocity, Vector2.DOWN, Vector2.UP)


func _Bound(v : float, minv : float, maxv : float) -> float:
	return max(minv, min(maxv, v))


func _PlayIfNotCurrent(anim_name : String) -> void:
	if anim_node.current_animation != anim_name:
		anim_node.play(anim_name)

# ----------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------



# ----------------------------------------------------------------
# Handler Methods
# ----------------------------------------------------------------


