extends Node2D
class_name Zone


signal prepared

# ---------------------------------------------------------------------------
# Export Variables
# ---------------------------------------------------------------------------


# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
var _player : Player = null
var _camera : Camera2D = null

var _doorway_entrance : bool = false


# ---------------------------------------------------------------------------
# Onready Variables
# ---------------------------------------------------------------------------
onready var _player_container : Node2D = get_node_or_null("Player_Container")
onready var _zone_doorway_container : Node2D = get_node_or_null("Zone_Doorways")


# ---------------------------------------------------------------------------
# Override Methods
# ---------------------------------------------------------------------------
func _ready() -> void:
	emit_signal("prepared")


# ---------------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------------
func _DefaultPlayerStartPosition() -> Vector2:
	_doorway_entrance = false
	var start = get_node_or_null("Player_Start")
	if not start:
		print("ERROR: Failed to find Player_Start node.")
		return Vector2.ZERO
	return start.position


func _StartingDoorwayPosition(target_doorway : String) -> Vector2:
	if target_doorway != "":
		if _zone_doorway_container == null:
			print("ERROR: Failed to find Zone_Doorways node.")
			return _DefaultPlayerStartPosition()
		
		for door in _zone_doorway_container.get_children():
			if door is Doorway and door.name == target_doorway:
				var pos = door.position + Vector2(0, 4)
				door.open()
				_doorway_entrance = true
				return pos
		
		print("ERROR: Failed to find doorway '", target_doorway, "'.")
	return _DefaultPlayerStartPosition()

# ---------------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------------
func zone_ready() -> void:
	if _player != null and _camera != null:
		_player.transition_end(not _doorway_entrance)


func attach_player(player : Player, target_doorway : String = "") -> void:
	if not _player_container:
		print("ERROR: Failed to find Player_Container node.")
		return
	
	player.get_parent().remove_child(player)
	_player_container.add_child(player)
	player.position = _StartingDoorwayPosition(target_doorway)
	_player = player
	
	if _camera is Tracker_Camera:
		_camera.target_node_path = _camera.get_path_to(_player)
		_player.transition_end(not _doorway_entrance)

func detach_player_to(container : Node2D) -> void:
	if _player == null:
		return
	
	_player.get_parent().remove_child(_player)
	container.add_child(_player)
	_player = null


func attach_camera(camera : Camera2D) -> void:
	if not _player_container:
		print("ERROR: Failed to find Player_Container node.")
		return
	
	camera.get_parent().remove_child(camera)
	_player_container.add_child(camera)
	_camera = camera
	
	if _camera is Tracker_Camera and _player != null:
		_camera.target_node_path = _camera.get_path_to(_player)
		_player.transition_end(not _doorway_entrance)


func detach_camera_to(container : Node2D) -> void:
	if _camera == null:
		return
	
	_camera.get_parent().remove_child(_camera)
	container.add_child(_camera)
	_camera = null

# ---------------------------------------------------------------------------
# Handler Methods
# ---------------------------------------------------------------------------


