extends Node2D


signal power_state(powered)

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export var battery_level : float = -1.0
export (float, 0.05, 1.0, 0.001) var discharge_per_second = 0.25
export var infinite_battery : bool = false

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _player : Player = null
var _picking_up : bool = false

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var anim_node : AnimationPlayer = get_node("Anim")
onready var usetimer_node : Timer = get_node("UseTimer")

# -------------------------------------------------------------------------
# Setters / Getters
# -------------------------------------------------------------------------
func set_battery_level(bl : float) -> void:
	if bl < 0.0:
		battery_level = -1.0
	else:
		battery_level = max(0.0, min(1.0, bl))
	_UpdateAnimation()

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	_UpdateAnimation()

func _process(delta : float) -> void:
	if infinite_battery:
		return
	
	set_battery_level(battery_level - (discharge_per_second * delta))

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _UpdateAnimation() -> void:
	if battery_level > 0.0:
		anim_node.play("battery_active")
		emit_signal("power_state", true)
	elif battery_level == 0.0:
		anim_node.play("battery_inactive")
		emit_signal("power_state", false)
	else:
		anim_node.play("nobattery")
		emit_signal("power_state", false)


# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------

func _on_body_entered(body) -> void:
	if infinite_battery and battery_level >= 0:
		return
	
	if body is Player and _player == null:
		var dist = position.distance_to(body.position)
		if dist <= 17.8:
			print("I see the player")
			_player = body
			_player.connect("activate", self, "_on_player_activate")
		print("Distance: ", dist)


func _on_body_exited(body) -> void:
	if body == _player:
		_player.disconnect("activate", self, "_on_player_activate")
		_player = null


func _on_UseTimer_timeout() -> void:
	if _picking_up:
		_picking_up = false
		if _player.give_battery(battery_level, false):
			set_battery_level(-1)
	_player.using(false)


func _on_player_activate() -> void:
	if battery_level < 0.0:
		var bv = _player.take_battery(false)
		if bv >= 0.0:
			set_battery_level(bv)
			_player.using()
			usetimer_node.start()
	else:
		_player.using()
		_picking_up = true
		usetimer_node.start()

