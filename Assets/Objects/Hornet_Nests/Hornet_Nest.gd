extends Node2D

const BOIDGROUP_INST = preload("res://Assets/Objects/Hornet_Nests/BoidGroup.tscn")
const BOID_INST = preload("res://Assets/Objects/Hornet_Nests/Boid.tscn")

# ---------------------------------------------------------------------------
# Export Variables
# ---------------------------------------------------------------------------
export (float, 0, 50) var small_bee_count = 15
export var small_spawn_container_path : NodePath = ""		setget set_small_spawn_container_path
export (Array, NodePath) var small_spawn_destinations = []

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
var _smalls_spawn_enabled = true
var _smalls_group = null
var _smalls_spawned = 0
var _smalls_timer : Timer = null
var _small_spawn_container_node : Node2D = null


# ---------------------------------------------------------------------------
# Onready Variables
# ---------------------------------------------------------------------------
onready var small_spawner_node = get_node_or_null("SSpawner")
onready var large_spawner_node = get_node_or_null("LSpawner")


# ---------------------------------------------------------------------------
# Setters / Getters
# ---------------------------------------------------------------------------
func set_small_spawn_container_path(cp : NodePath) -> void:
	small_spawn_container_path = cp
	if small_spawn_container_path != "":
		_small_spawn_container_node = get_node_or_null(small_spawn_container_path)
	else:
		# TODO: Remove any existing "small" spawns first.
		_small_spawn_container_node = null

# ---------------------------------------------------------------------------
# Override Methods
# ---------------------------------------------------------------------------
func _ready() -> void:
	set_small_spawn_container_path(small_spawn_container_path)
	if small_spawner_node != null:
		_smalls_timer = Timer.new()
		_smalls_timer.one_shot = true
		add_child(_smalls_timer)
		_smalls_timer.connect("timeout", self, "_on_smalls_enable")
		#_smalls_timer.start(rand_range(20.0, 50.0))
		for child in small_spawner_node.get_children():
			var timer = child.get_node_or_null("Timer")
			if timer != null:
				timer.connect("timeout", self, "_on_small_spawn_timeout", [child])

func _process(delta : float) -> void:
	if _smalls_spawn_enabled:
		_SpawnSmalls()


# ---------------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------------

func _GetRandSmallSpawnDestination() -> Vector2:
	if small_spawn_destinations.size() > 0:
		var idx = floor(rand_range(0.0, small_spawn_destinations.size()))
		var dpath = small_spawn_destinations[idx]
		var node = get_node_or_null(dpath)
		if node is Node2D:
			return node.global_position
	return global_position

func _GetRandSmallSpawnPosition() -> Node2D:
	if small_spawner_node != null:
		var idx = floor(rand_range(0.0, small_spawner_node.get_child_count()))
		var node = small_spawner_node.get_child(idx)
		if node is Node2D and node.visible:
			return node
	return null


func _SpawnSmalls() -> void:
	if not small_spawner_node or not _small_spawn_container_node:
		return
	
	if _smalls_group != null and not _smalls_group.locked() and _smalls_spawned < small_bee_count:
		var pos_node = _GetRandSmallSpawnPosition()
		if pos_node != null:
			var timer = pos_node.get_node_or_null("Timer")
			if timer:
				timer.start()
				pos_node.visible = false
				var boid = BOID_INST.instance()
				boid.position = pos_node.global_position
				boid.home_position = pos_node.global_position
				boid.despawn_delay = rand_range(1.0, 3.0)
				boid.connect("release", self, "_on_release_small_spawn", [boid])
				_small_spawn_container_node.add_child(boid)
				_smalls_group.add_boid(boid)
				_smalls_spawned += 1
				if _smalls_spawned == small_bee_count:
					_smalls_group.lock()
					_smalls_spawn_enabled = false
	elif _smalls_group == null:
		var dest = _GetRandSmallSpawnDestination()
		_smalls_group = BOIDGROUP_INST.instance()
		_smalls_group.position = self.global_position
		_smalls_group.target_position = dest
		_smalls_group.time_to_target = rand_range(20.0, 50.0)
		_small_spawn_container_node.add_child(_smalls_group)
		_SpawnSmalls()


# ---------------------------------------------------------------------------
# Handler Methods
# ---------------------------------------------------------------------------
func _on_small_spawn_timeout(spawner : Node2D) -> void:
	spawner.visible = true

func _on_release_small_spawn(boid : Boid) -> void:
	_smalls_spawned -= 1
	_smalls_group.remove_boid(boid)
	if _smalls_group.boid_count() <= 0:
		_smalls_group.get_parent().remove_child(_smalls_group)
		_smalls_group.queue_free()
		_smalls_group = null
		_smalls_timer.start(rand_range(20.0, 50.0))

func _on_smalls_enable() -> void:
	_smalls_spawn_enabled = true
