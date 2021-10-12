extends KinematicBody2D
class_name Boid


const IDEAL_DISTANCE = 2.0

# ----------------------------------------------------------------------------
# Export Variables
# ----------------------------------------------------------------------------
export var home_position : Vector2 = Vector2.ZERO
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

# ----------------------------------------------------------------------------
# Setters / Getters
# ----------------------------------------------------------------------------


# ----------------------------------------------------------------------------
# Override Methods
# ----------------------------------------------------------------------------
func _ready() -> void:
	pass


func _physics_process(delta : float) -> void:
	_direction = Vector2.ZERO
	if _weight_impulse == 1.0:
		_ApplyGroupImpulse()
	else:
		_ApplyCOMImpulse()
		_ApplyCNImpulse()
		_ApplyGroupImpulse()
	
	_velocity += _direction * _acceleration * delta
	_direction = _velocity.normalized()
	if _velocity.length() > _speed:
		_velocity = _direction * _speed
	move_and_collide(_velocity)
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

# ----------------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------------
func set_impulse_weight(w : float) -> void:
	_weight_impulse = max(0.0, min(1.0, w))

func set_impulse_direction(id : Vector2) -> void:
	_impulse = id.normalized()

func set_center_of_mass(com : Vector2) -> void:
	_center_of_mass = com

func set_closest_neighbor(cn : Vector2) -> void:
	_closest_neighbor = cn
