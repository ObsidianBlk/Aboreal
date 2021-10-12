extends Area2D
class_name BoidGroup


# ----------------------------------------------------------------------------
# Export Variables
# ----------------------------------------------------------------------------
export (float, 0.1) var life_span = 60.0
export var target_position : Vector2 = Vector2.ZERO
export (float, 0.1) var time_to_target = 150.0

# ----------------------------------------------------------------------------
# Variables
# ----------------------------------------------------------------------------
var _boids = []
var _locked = false
var _center_of_mass = Vector2.ZERO
var _size = 1.0

var _player : Player = null

# ----------------------------------------------------------------------------
# Override Methods
# ----------------------------------------------------------------------------
func _ready() -> void:
	var col_node = get_node("CollisionShape2D")
	_size = col_node.shape.radius
	
	var timer : Timer = get_node("Timer")
	timer.connect("timeout", self, "_on_end_of_life")
	
	var tween : Tween = get_node("Tween")
	tween.connect("tween_all_completed", self, "_on_reached_target")
	tween.interpolate_property(
		self, "global_position",
		global_position, target_position, 
		time_to_target,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween.start()
#
func _physics_process(delta : float) -> void:
	_CalcCenterOfMass()
	for b in _boids:
		var boid : Boid = b[0]
		boid.set_center_of_mass(_center_of_mass)
		boid.set_closest_neighbor(get_closest_to(boid))
		var dist = global_position.distance_to(boid.global_position)
		var dir = boid.global_position.direction_to(global_position)
		boid.set_impulse_direction(dir)
		boid.set_impulse_weight(min(1.0, dist / _size))
		if _player and not boid.knows_of_enemy():
			if randf() < 0.05:
				boid.set_enemy(_player)

# ----------------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------------
func _CalcCenterOfMass() -> void:
	if _boids.size() > 0:
		var com = Vector2.ZERO
		for bo in _boids:
			com += bo[0].global_position
		_center_of_mass = com / _boids.size()
	else:
		_center_of_mass = Vector2.ZERO

# ----------------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------------
func has_boid(b : Boid) -> bool:
	for bo in _boids:
		if b == bo[0]:
			return true
	return false

func add_boid(b : Boid) -> void:
	if _locked:
		return
	
	if not has_boid(b):
		_boids.append([b, overlaps_body(b)])

func remove_boid(b : Boid) -> void:
	for i in range(_boids.size()):
		if _boids[i][0] == b:
			_boids.remove(i)
			break

func boid_count() -> int:
	return _boids.size()

func lock() -> void:
	_locked = true

func locked() -> bool:
	return _locked

func get_closest_to(b : Boid) -> Vector2:
	var tpos = null
	var tdist = 0
	for bo in _boids:
		if bo[0] != b:
			var _b = bo[0]
			var dist = _b.global_position.distance_to(b.global_position)
			if tpos == null or dist < tdist:
				tpos = _b.global_position
				tdist = dist
	if tpos == null:
		tpos = b.global_position
	return tpos


# ----------------------------------------------------------------------------
# Handler Methods
# ----------------------------------------------------------------------------

func _on_body_entered(body):
	if body is Boid:
		if not has_boid(body):
			_boids.append([body, true])
	elif body is Player and _player == null:
		_player = body


func _on_body_exited(body):
	if body is Boid:
		for bo in _boids:
			if bo[0] == body:
				bo[1] = false
				break
	elif body == _player:
		_player = null


func _on_reached_target() -> void:
	var timer : Timer = get_node("Timer")
	timer.start(life_span)

func _on_end_of_life() -> void:
	for b in _boids:
		b[0].return_home()


