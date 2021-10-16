extends KinematicBody2D
class_name Player

signal activate
signal enter
signal zone(src)
signal dead

# ----------------------------------------------------------------
# ENUMs and Constants
# ----------------------------------------------------------------
enum STATE {IDLE, MOVE, AIR, USE, PICKUP, TRANSITION, HURT, DEAD}
enum MOVEMENT {WALKING, RUNNING, CRAWLING}

const IDLE_THRESHOLD = 8.0
const FLOAT_THRESHOLD = 10.0

var SPRITE_UNEQUIPPED = preload("res://Assets/Graphics/Player/Player.png")
var SPRITE_EQUIPPED = preload("res://Assets/Graphics/Player/Player_charger.png")

var VOICE_HURT_SMALL = [
	preload("res://Assets/Audio/SFX/Voice/small hurt1.wav"),
	preload("res://Assets/Audio/SFX/Voice/small hurt2.wav"),
	preload("res://Assets/Audio/SFX/Voice/small hurt3.wav"),
	preload("res://Assets/Audio/SFX/Voice/small hurt4.wav"),
	preload("res://Assets/Audio/SFX/Voice/small hurt 5.wav")
]

var VOICE_HURT_BIG = [
	preload("res://Assets/Audio/SFX/Voice/big hurt1.wav"),
	preload("res://Assets/Audio/SFX/Voice/big hurt2.wav"),
	preload("res://Assets/Audio/SFX/Voice/big hurt3.wav"),
	preload("res://Assets/Audio/SFX/Voice/big hurt4.wav")
]

var VOICE_JUMP = [
	preload("res://Assets/Audio/SFX/Voice/jump1-01.wav"),
	preload("res://Assets/Audio/SFX/Voice/jump2.wav"),
	preload("res://Assets/Audio/SFX/Voice/jump3.wav"),
	preload("res://Assets/Audio/SFX/Voice/jump4.wav"),
	preload("res://Assets/Audio/SFX/Voice/jump5.wav"),
]

var VOICE_LAND = [
	preload("res://Assets/Audio/SFX/Voice/landing1.wav"),
	preload("res://Assets/Audio/SFX/Voice/landing2.wav"),
	preload("res://Assets/Audio/SFX/Voice/landing3.wav"),
	preload("res://Assets/Audio/SFX/Voice/landing4.wav")
]

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
var _rng : RandomNumberGenerator = null
var _velocity = Vector2.ZERO
var _state = STATE.IDLE
var _move_state = MOVEMENT.WALKING

var _battery_charge = -1.0
var _always_run = false
var _flashlight_enabled = false

var _transition_target : Vector2 = Vector2.ZERO
var _transition_zone : String = ""


# ----------------------------------------------------------------
# Onready Variables
# ----------------------------------------------------------------
onready var anim_node = get_node("Anim")
onready var sprite_node = get_node("Viz/Sprite")
onready var bat_light_node = get_node("Viz/Battery_Light")
onready var flashlight_node = get_node("Viz/Flashlight")
onready var viz_node = get_node("Viz")

onready var acttimer_node = get_node("ActTimer")
onready var tween_node = get_node("Tween")

onready var sfx_node = get_node("audio_sfx")
onready var voice_node = get_node("audio_voice")

# ----------------------------------------------------------------
# Override Methods
# ----------------------------------------------------------------
func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

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
		if _velocity.y < 0.0:
			_PlayAudio(voice_node, VOICE_JUMP)
		_state = STATE.AIR
		return
		
	if abs(_velocity.x) > IDLE_THRESHOLD:
		_state = STATE.MOVE
		return
	
	if _move_state == MOVEMENT.CRAWLING:
		_PlayIfNotCurrent("crouch")
	else:
		_PlayIfNotCurrent("idle")

	_ProcessMiscInput()
	_ProcessUserInteractions()
	_ProcessUserJump(delta)
	_ProcessUserMovement(delta)


func _ProcessMoveState(delta : float) -> void:
	if not is_on_floor():
		if _velocity.y < 0.0:
			_PlayAudio(voice_node, VOICE_JUMP)
		_state = STATE.AIR
		return
	
	var vlen = abs(_velocity.x)
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

	_ProcessMiscInput()
	_ProcessUserInteractions()
	_ProcessUserJump(delta)
	_ProcessUserMovement(delta)


func _ProcessAirState(delta : float) -> void:
	if is_on_floor():
		_PlayAudio(voice_node, VOICE_LAND)
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
	_ProcessMiscInput()
	_ProcessUserMovement(delta)


func _ProcessHurtState(delta : float) -> void:
	pass


func _ProcessUserInteractions() -> void:
	if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("activate"):
		acttimer_node.start()
	elif Input.is_action_just_released("up") or Input.is_action_just_released("activate"):
		if acttimer_node.is_stopped():
			emit_signal("enter")
		else:
			emit_signal("activate")

func _ProcessUserJump(delta : float) -> void:
	if Input.is_action_just_pressed("jump"):
		if _move_state == MOVEMENT.CRAWLING:
			print("Crawling")
			position.y += 2
		else:
			print("Not Crawling")
			if abs(_velocity.x) > max_walk_speed:
				_velocity.y -= jump_force * 1.5
			else:
				_velocity.y -= jump_force

func _ProcessMiscInput() -> void:
	if Input.is_action_just_pressed("flashlight"):
		_flashlight_enabled = not _flashlight_enabled
		flashlight_node.visible = _flashlight_enabled
		

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
		if _velocity.x > 0.0 and viz_node.scale.x < 0.0:
			#print("Changing Scale - RIGHT")
			viz_node.scale.x = 1.0
		elif _velocity.x < 0.0 and viz_node.scale.x > 0.0:
			#print("Changing Scale - LEFT - ", scale)
			viz_node.scale.x = -1.0
			#print(self.scale)
	else:
		var friction = run_friction if running else walk_friction
		_velocity.x = lerp(_velocity.x, 0.0, friction)
	_velocity = move_and_slide_with_snap(_velocity, Vector2.DOWN, Vector2.UP)


func _UpdateMovementState() -> void:
	match _move_state:
		MOVEMENT.WALKING:
			if Input.is_action_pressed("down") and abs(_velocity.x) <= max_walk_speed:
				_move_state = MOVEMENT.CRAWLING
			if _always_run or Input.is_action_pressed("mod_shift"):
				_move_state = MOVEMENT.RUNNING
			if Input.is_action_just_pressed("toggle_mod"):
				_always_run = !_always_run
		MOVEMENT.RUNNING:
			if not _always_run and not Input.is_action_pressed("mod_shift"):
				_move_state = MOVEMENT.WALKING
			if _always_run and Input.is_action_pressed("down"):
				_move_state = MOVEMENT.CRAWLING
			if Input.is_action_just_pressed("toggle_mod"):
				_always_run = !_always_run
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

func _HideFlashlight() -> void:
	flashlight_node.visible = false

func _ShowFlashlight() -> void:
	if _flashlight_enabled:
		flashlight_node.visible = true

func _PlayIfNotCurrent(anim_name : String) -> void:
	if anim_node.current_animation != anim_name:
		#print("Playing Current: ", anim_node.current_animation, " | Playing Now: ", anim_name)
		anim_node.play(anim_name)


func _PickedUp() -> void:
	if _state == STATE.PICKUP:
		if _battery_charge >= 0.0:
			sprite_node.texture = SPRITE_EQUIPPED
			bat_light_node.visible = true
		else:
			sprite_node.texture = SPRITE_UNEQUIPPED
			bat_light_node.visible = false


func _Die() -> void:
	print("I have technically died!")
	emit_signal("dead")

func _PlayAudio(audio_node : AudioStreamPlayer, audio_set : Array, force : bool = false) -> void:
	if not audio_node.playing or force:
		var idx = _rng.randi_range(0, audio_set.size() - 1)
		if audio_set[idx] is AudioStream:
			audio_node.stream = audio_set[idx]
			audio_node.play()
		else:
			print("Item in list isn't an AudioStream?!")
	else:
		print("Still playing audio.")

# ----------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------
func reset(full : bool = false) -> void:
	_state = STATE.IDLE
	if full:
		_battery_charge = -1.0
		sprite_node.texture = SPRITE_UNEQUIPPED
		bat_light_node.visible = false
		flashlight_node.visible = false
		_flashlight_enabled = false
		# Also... reset health

func transition(target_position : Vector2, doorway_anim : bool = false) -> void:
	if _state == STATE.TRANSITION:
		return
	
	_transition_target = target_position
	_state = STATE.TRANSITION
	if doorway_anim:
		anim_node.play("enter_doorway")
	else:
		tween_node.interpolate_property(sprite_node, "self_modulate", sprite_node.self_modulate, Color(1,1,1,0), 0.4, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween_node.start()

func transition_zone(target_zone : String) -> void:
	if _state == STATE.TRANSITION:
		return
	_transition_zone = target_zone
	_state = STATE.TRANSITION
	anim_node.play("enter_doorway")

func transition_end(no_doorway : bool = false) -> void:
	if _state != STATE.TRANSITION or _transition_zone == "":
		return
	_transition_zone = ""
	if no_doorway:
		reset()
	else:
		anim_node.play("exit_doorway")

func using(u : bool = true) -> void:
	_state = STATE.USE if u else STATE.IDLE
	if u:
		anim_node.play("use")

func is_using() -> bool:
	return _state == STATE.USE

func give_battery(amount : float) -> bool:
	if _battery_charge < 0.0 and amount >= 0.0:
		_battery_charge = amount
		_state = STATE.PICKUP
		anim_node.play("pickup")
		return true
	return false

func take_battery() -> float:
	var v = _battery_charge
	if _battery_charge >= 0.0:
		_battery_charge = -1.0
		_state = STATE.PICKUP
		anim_node.play("pickup")
	return v

func hurt(amount : float) -> void:
	_PlayAudio(voice_node, VOICE_HURT_SMALL)
	pass

# ----------------------------------------------------------------
# Handler Methods
# ----------------------------------------------------------------

func _on_animation_finished(anim_name):
	if _state == STATE.TRANSITION:
		if anim_name == "enter_doorway":
			if _transition_zone != "":
				emit_signal("zone", _transition_zone)
			else:
				self.global_position = _transition_target
				anim_node.play("exit_doorway")
		if anim_name == "exit_doorway":
			anim_node.play("idle") # Forcing this which should also garentee all attributes are reset.
			_state = STATE.IDLE
	if _state == STATE.PICKUP:
		_state = STATE.IDLE


func _on_tween_completed(object, key):
	if _state == STATE.TRANSITION:
		if object == sprite_node and key == "self_modulate":
			if sprite_node.self_modulate == Color(1,1,1,0):
				self.global_position = _transition_target
				tween_node.interpolate_property(
					sprite_node, "self_modulate",
					sprite_node.self_modulate, Color(1,1,1,1),
					0.4,
					Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
				)
				tween_node.start()
			else:
				anim_node.play("idle")
				_state = STATE.IDLE


