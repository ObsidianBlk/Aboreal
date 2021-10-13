extends KinematicBody2D
class_name Boid

signal release
const IDEAL_DISTANCE = 2.0
const TARGET_DISTANCE = 8.0

# ----------------------------------------------------------------------------
# Export Variables
# ----------------------------------------------------------------------------
export var home_position : Vector2 = Vector2.ZERO
export (float, 0.1) var despawn_delay = 1.0
export var verbose : bool = false

# ----------------------------------------------------------------------------
# Variables
# ----------------------------------------------------------------------------
var _speed = 1
var _acceleration = 2.0
var _velocity : Vector2 = Vector2.ZERO
var _direction : Vector2 = Vector2.ZERO

var _weight_com : float = 0.0
var _center_of_mass : Vector2 = Vector2.ZERO
var _weight_closest : float = 0.0
var _closest_neighbor : Vector2 = Vector2.ZERO
var _weight_impulse : float = 0.0
var _impulse : Vector2 = Vector2.ZERO
var _return_home : bool = false

var _enemy : Node2D = null
var _enemy_lock : bool = false

var timer : Timer= null

# ----------------------------------------------------------------------------
# Setters / Getters
# ----------------------------------------------------------------------------


# ----------------------------------------------------------------------------
# Override Methods
# ----------------------------------------------------------------------------
func _ready() -> void:
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.connect("timeout", self, "_on_timeout")


func _physics_process(delta : float) -> void:
	_direction = Vector2.ZERO
	if _enemy != null:
		_ApplyEnemyImpulse()
		_ApplyCNImpulse()
	elif _return_home:
		_ApplyHomeImpulse()
		#_ApplyCNImpulse()
	elif _weight_impulse == 1.0:
		_ApplyGroupImpulse()
	else:
		_ApplyCOMImpulse()
		_ApplyCNImpulse()
		_ApplyGroupImpulse()
	
	_velocity += _direction * _acceleration * delta
	_direction = _velocity.normalized()
	if _return_home or _enemy != null:
		var dist = 0.0
		if _enemy:
			dist = global_position.distance_to(_enemy.global_position)
		else:
			dist = global_position.distance_to(home_position)
		var speed = min(_speed, _speed * (dist / TARGET_DISTANCE))
		if _velocity.length() > speed:
			_velocity = _direction * speed
	else:
		if _velocity.length() > _speed:
			_velocity = _direction * _speed
	move_and_collide(_velocity)
	if _enemy and global_position.distance_to(_enemy.global_position) < 8.0:
		if _enemy.has_method("hurt"):
			_enemy.hurt(0.5)
		set_enemy(null)
	if _return_home and global_position.distance_to(home_position) < TARGET_DISTANCE * 0.5:
		_velocity = Vector2.ZERO
		timer.start(despawn_delay)
		set_physics_process(false)
	if verbose:
		print(_velocity)


# ----------------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------------
func _ApplyCOMImpulse() -> void:
	var dist = _center_of_mass.distance_to(global_position)
	var imp_direction = global_position.direction_to(_center_of_mass)
	var weight = 0.0 if dist == 0.0 else min(1.0, IDEAL_DISTANCE / dist)
	_direction = (_direction + (imp_direction * weight)).normalized()

func _ApplyCNImpulse() -> void:
	var cn_distance = _closest_neighbor.distance_to(global_position)
	var cn_direction = null
	var cn_weight = 0.0
	if cn_distance <= IDEAL_DISTANCE:
		cn_weight = 1.0 if cn_distance <= 1.0 else 1.0 - (cn_distance / IDEAL_DISTANCE) 
		cn_direction = _closest_neighbor.direction_to(global_position)
	else:
		cn_weight = min(1.0, (IDEAL_DISTANCE / cn_distance) - 1.0)
		cn_direction = global_position.direction_to(_closest_neighbor)
	_direction = (_direction + (cn_direction * cn_weight)).normalized()


func _ApplyGroupImpulse() -> void:
	_direction = (_direction + (_impulse * _weight_impulse)).normalized()

func _ApplyHomeImpulse() -> void:
	_direction = global_position.direction_to(home_position).normalized()

func _ApplyEnemyImpulse() -> void:
	_direction = global_position.direction_to(_enemy.global_position).normalized()

# ----------------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------------
func set_impulse_weight(w : float) -> void:
	_weight_impulse = max(0.0, min(1.0, w))
	if _weight_impulse == 1.0 and _enemy != null:
		if timer.is_stopped():
			timer.start(rand_range(0.4, 1.2))

func set_impulse_direction(id : Vector2) -> void:
	_impulse = id.normalized()

func set_center_of_mass(com : Vector2) -> void:
	_center_of_mass = com

func set_closest_neighbor(cn : Vector2) -> void:
	_closest_neighbor = cn

func set_enemy(e : Node2D) -> void:
	if e == null:
		_enemy = null
		_enemy_lock = true
		timer.start(4.0)
	elif not _return_home and not _enemy_lock and _enemy == null:
		_enemy = e

func knows_of_enemy() -> bool:
	return _enemy != null

func return_home() -> void:
	_return_home = true




# ----------------------------------------------------------------------------
# Handler Methods
# ----------------------------------------------------------------------------
func _on_timeout() -> void:
	if _enemy_lock:
		_enemy_lock = false
	elif _weight_impulse == 1.0 and _enemy != null:
		set_enemy(null)
	elif _return_home:
		emit_signal("release")
		queue_free()
