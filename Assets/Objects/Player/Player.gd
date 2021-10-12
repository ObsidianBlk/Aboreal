extends KinematicBody2D
class_name Player



# ----------------------------------------------------------------
# ENUMs and Constants
# ----------------------------------------------------------------
enum STATE {IDLE, MOVE, AIR, HURT}
enum MOVEMENT {WALKING, RUNNING, CRAWLING}

const IDLE_THRESHOLD = 1.0
const FLOAT_THRESHOLD = 10.0


# ----------------------------------------------------------------
# Export Variables
# ----------------------------------------------------------------
export (float, 0.0) var gravity = 150
export (float, 0.0) var max_walk_speed =  20
export (float, 0.0) var max_run_speed = 80
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
var _move_state = MOVEMENT.WALKING


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
	
	if _move_state == MOVEMENT.CRAWLING:
		_PlayIfNotCurrent("crouch")
	else:
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
		if _move_state == MOVEMENT.WALKING:
			_PlayIfNotCurrent("walk")
		elif _move_state == MOVEMENT.CRAWLING:
			_PlayIfNotCurrent("crawl")
	elif _move_state == MOVEMENT.RUNNING and vlen > max_walk_speed:
		_PlayIfNotCurrent("run")

	_ProcessUserJump(delta)
	_ProcessUserMovement(delta)


func _ProcessAirState(delta : float) -> void:
	if is_on_floor():
		_velocity.y = 0.0
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
	if Input.is_action_just_pressed("jump") and _move_state != MOVEMENT.CRAWLING:
		if abs(_velocity.x) > max_walk_speed:
			_velocity.y -= jump_force * 1.5
		else:
			_velocity.y -= jump_force

func _ProcessUserMovement(delta : float) -> void:
	var direction = _GetDirection()
	_UpdateMovementState()
	
	var running = abs(_velocity.x) > max_walk_speed
	if direction != 0 and not (_move_state == MOVEMENT.WALKING and running):
		if sign(direction) != sign(_velocity.x):
			_velocity.x = 0.0
		var acceleration = run_accel if _move_state == MOVEMENT.RUNNING else walk_accel
		var speed = max_run_speed if _move_state == MOVEMENT.RUNNING else max_walk_speed
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


func _UpdateMovementState() -> void:
	match _move_state:
		MOVEMENT.WALKING:
			if Input.is_action_pressed("down") and abs(_velocity.x) <= max_walk_speed:
				_move_state = MOVEMENT.CRAWLING
			if Input.is_action_pressed("mod_shift"):
				_move_state = MOVEMENT.RUNNING
		MOVEMENT.RUNNING:
			if not Input.is_action_pressed("mod_shift"):
				_move_state = MOVEMENT.WALKING
		MOVEMENT.CRAWLING:
			if not Input.is_action_pressed("down"):
				_move_state = MOVEMENT.WALKING

func _GetDirection() -> float:
	var direction = 0.0
	if Input.is_action_pressed("left"):
		direction -= 1
	if Input.is_action_pressed("right"):
		direction += 1
	return direction

func _Bound(v : float, minv : float, maxv : float) -> float:
	return max(minv, min(maxv, v))


func _PlayIfNotCurrent(anim_name : String) -> void:
	if anim_node.current_animation != anim_name:
		#print("Playing Current: ", anim_node.current_animation, " | Playing Now: ", anim_name)
		anim_node.play(anim_name)

# ----------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------



# ----------------------------------------------------------------
# Handler Methods
# ----------------------------------------------------------------


