extends Area2D
class_name BoidGroup


# ----------------------------------------------------------------------------
# Variables
# ----------------------------------------------------------------------------
var _boids = []
var _center_of_mass = Vector2.ZERO
var _size = 1.0

#onready var col_node = get_node("CollisionShape2D")

# ----------------------------------------------------------------------------
# Override Methods
# ----------------------------------------------------------------------------
func _ready() -> void:
	var col_node = get_node("CollisionShape2D")
	#print(col_node)
	_size = col_node.shape.radius
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
	if not has_boid(b):
		_boids.append([b, overlaps_body(b)])

func remove_boid(b : Boid) -> void:
	for i in range(_boids.size()):
		if _boids[i][0] == b:
			_boids.remove(i)
			break

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
		print ("I see a BODY!")
		if not has_boid(body):
			_boids.append([body, true])


func _on_body_exited(body):
	if body is Boid:
		for bo in _boids:
			if bo[0] == body:
				bo[1] = false
				break
