extends Node2D
class_name Doorway

# ---------------------------------------------------------------------------
# Export Variables
# ---------------------------------------------------------------------------
export var target_door_path : NodePath = ""
export var target_zone_path : String = ""
export var target_zone_door : String = ""
export var take_battery : bool = false

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
var _player : Player = null
var _state = 0 # 0 = closed | 1 = open | 2 = Changing state

# ---------------------------------------------------------------------------
# Onready Variables
# ---------------------------------------------------------------------------
onready var anim_node = get_node("AnimationPlayer")

func _ready() -> void:
	var light2d = get_node("Light2D")
	var occluder = get_node("LO_Left")
	
	print("Light2D Shadow Mask: ", light2d.shadow_item_cull_mask, " | Occluder Mask: ", occluder.light_mask)


# ---------------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------------
func open(animated : bool = false) -> void:
	if _state == 0:
		if animated:
			print("Opening Animated")
			anim_node.play("open")
			_state = 2
		else:
			print("Opening Instant")
			anim_node.play("idle_open")
			_state = 1

func close(animated : bool = false) -> void:
	if _state == 1:
		if animated:
			anim_node.play("close")
			_state = 2
		else:
			anim_node.play("idle")
			_state = 0

func is_open() -> bool:
	return _state == 1

func is_closed() -> bool:
	return _state == 0

func opening() -> bool:
	return transitioning("open")

func closing() -> bool:
	return transitioning("close")

func transitioning(dir : String = "") -> bool:
	if _state == 2:
		return dir == "" or anim_node.current_animation == dir
	return false

# ---------------------------------------------------------------------------
# Handler Methods
# ---------------------------------------------------------------------------
func _on_body_entered(body) -> void:
	if body is Player and _player == null:
		_player = body
		_player.connect("activate", self, "_on_player_activate")
		_player.connect("enter", self, "_on_player_enter")


func _on_body_exited(body) -> void:
	if body == _player:
		_player.disconnect("activate", self, "_on_player_activate")
		_player.disconnect("enter", self, "_on_player_enter")
		_player = null

func _on_animation_finished(anim_name : String) -> void:
	if _state == 2:
		if anim_name == "open":
			_state = 1
		else:
			_state = 0
			anim_node.play("idle")


func _on_player_activate() -> void:
	if _state != 2:
		if _state == 0:
			anim_node.play("open")
		else:
			anim_node.play("close")
		_state = 2

func _on_player_enter() -> void:
	if _player == null or _state != 1:
		return
	if target_zone_path != "" and target_zone_door != "":
		if take_battery:
			_player.take_battery(false)
		_player.transition_zone(target_zone_path, target_zone_door)
	else:
		var target_door = get_node_or_null(target_door_path)
		if target_door != null:
			if target_door.is_closed():
				target_door.open()
			_player.transition(target_door.global_position + Vector2(0.0, 4.0), true)

