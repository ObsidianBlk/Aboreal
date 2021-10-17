extends Node2D

# ---------------------------------------------------------------------------
# Export Variables
# ---------------------------------------------------------------------------


# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
var _cur_zone : Zone = null

# ---------------------------------------------------------------------------
# Onready Variables
# ---------------------------------------------------------------------------
onready var _viewport : Viewport = get_node("Viewport")
onready var _pccontainer : Node2D = get_node("PCContainter")
onready var _player : Player = get_node("PCContainter/Player")
onready var _camera : Camera2D = get_node("PCContainter/Camera")


# ---------------------------------------------------------------------------
# Override Methods
# ---------------------------------------------------------------------------
func _ready() -> void:
	_player.connect("zone", self, "_on_zone_transition")
	_Zone("res://Assets/Levels/StartZone.tscn")

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


# ---------------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------------
func _Zone(target_zone : String, target_doorway : String = "") -> void:
	var ZONE = load(target_zone)
	if not ZONE:
		print("ERROR: Failed to load zone '", target_zone, "'!")
		return
	var nzone = ZONE.instance()
	if not nzone is Zone:
		print("ERROR: Loaded Scene, '", target_zone, "', is not a Zone!")
		nzone.queue_free()
		return
	
	if _cur_zone != null:
		_cur_zone.detach_camera_to(_pccontainer)
		_cur_zone.detach_player_to(_pccontainer)
		_viewport.remove_child(_cur_zone)
		_cur_zone.queue_free()
		_cur_zone = null
	
	nzone.connect("prepared", self, "_on_zone_prepared", [nzone, target_doorway])
	_viewport.add_child(nzone)


# ---------------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------------


# ---------------------------------------------------------------------------
# Handler Methods
# ---------------------------------------------------------------------------
func _on_zone_transition(target_zone : String, target_doorway : String) -> void:
	_Zone(target_zone, target_doorway)

func _on_zone_prepared(zone : Zone, target_doorway : String) -> void:
	zone.disconnect("prepared", self, "_on_zone_prepared")
	zone.attach_camera(_camera)
	zone.attach_player(_player, target_doorway)
	zone.zone_ready()
	_cur_zone = zone

