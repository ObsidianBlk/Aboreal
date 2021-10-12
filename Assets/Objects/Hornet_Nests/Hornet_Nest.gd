extends Node2D

const BOIDGROUP_INST = preload("res://Assets/Objects/Hornet_Nests/BoidGroup.tscn")
const BOID_INST = preload("res://Assets/Objects/Hornet_Nests/Boid.tscn")

# ---------------------------------------------------------------------------
# Export Variables
# ---------------------------------------------------------------------------
export (float, 0, 50) var small_bee_count = 15
export var small_spawn_container_path : NodePath = ""		setget set_small_spawn_container_path


# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
var _smalls_group = null
var _smalls_spawned = 0
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

func _process(delta : float) -> void:
	# TODO: This is a sledge hammer. Make this look more natural!!
	_SpawnSmalls()


# ---------------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------------
func _GetRandSmallSpawnPosition() -> Node2D:
	if small_spawner_node != null:
		var idx = floor(rand_range(0.0, get_child_count()))
		var node = get_child(idx)
		if node is Node2D:
			return node
	return null


func _SpawnSmalls() -> void:
	if not small_spawner_node or not _small_spawn_container_node:
		return
	
	if _smalls_group != null and _smalls_spawned < small_bee_count:
		var pos_node = _GetRandSmallSpawnPosition()
		if pos_node != null:
			var boid = BOID_INST.instance()
			boid.position = pos_node.global_position
			_small_spawn_container_node.add_child(boid)
			_smalls_group.add_boid(boid)
			_smalls_spawned += 1			
	elif _smalls_spawned == 0:
		_smalls_group = BOIDGROUP_INST.instance()
		_smalls_group.position = self.global_position
		_small_spawn_container_node.add_child(_smalls_group)
		_SpawnSmalls()

