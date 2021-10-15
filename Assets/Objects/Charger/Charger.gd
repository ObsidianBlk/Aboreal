tool
extends Node2D

enum ORIENTATION {LEFT, RIGHT}

# ---------------------------------------------------------------------------
# Export Variables
# ---------------------------------------------------------------------------
export (ORIENTATION) var orientation = ORIENTATION.LEFT
export var powered : bool = false
export (float, -1.0, 100.0) var battery_amount : float = -1.0		setget set_battery_amount
export (float, 0.1, 100.0) var charge_per_second : float = 10.0

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
var _player : Player = null
var _last_charge_state = ""

# ---------------------------------------------------------------------------
# Onready Variables
# ---------------------------------------------------------------------------
onready var anim_node = get_node("Anim")

onready var blight_node = get_node("Body/BLight")
onready var clight_node = get_node("Body/CLight")

# ---------------------------------------------------------------------------
# Setters / Getters
# ---------------------------------------------------------------------------
func set_orientation(o : int) -> void:
	if o == ORIENTATION.LEFT or o == ORIENTATION.RIGHT:
		orientation = o
		var body_node = get_node_or_null("Body")
		if body_node:
			body_node.scale.x = 1 if orientation == ORIENTATION.LEFT else -1

func set_battery_amount(amount : float) -> void:
	if amount < 0.0:
		amount = -1.0
	else:
		amount = min(100.0, amount)
	
	battery_amount = amount
	_UpdateChargerAnim()


# ---------------------------------------------------------------------------
# Override Methods
# ---------------------------------------------------------------------------
func _ready() -> void:
	set_orientation(orientation)
	if Engine.editor_hint:
		set_process(false)
	else:
		set_process(true)
		_UpdateChargerAnim()


func _process(delta : float) -> void:
	if not powered:
		return
	
	if battery_amount >= 0.0 and battery_amount < 100.0:
		battery_amount = min(battery_amount + (charge_per_second * delta), 100.0)
		_UpdateChargerAnim()

# ---------------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------------
func _PlayIfNotPlaying(anim : String) -> void:
	if anim_node and _last_charge_state != anim:
		anim_node.play(anim)


func _UpdateChargerAnim() -> void:
	if powered and not Engine.editor_hint:
		if battery_amount < 0.0:
			_PlayIfNotPlaying("powered")
		elif battery_amount < 100.0:
			_PlayIfNotPlaying("powered_charging")
		else:
			_PlayIfNotPlaying("powered_charged")
	else:
		if battery_amount < 0.0:
			_PlayIfNotPlaying("unpowered")
		elif battery_amount < 100.0:
			_PlayIfNotPlaying("unpowered_uncharged")
		else:
			_PlayIfNotPlaying("unpowered_charged")

# ---------------------------------------------------------------------------
# Handler Methods
# ---------------------------------------------------------------------------

func _on_body_entered(body) -> void:
	if Engine.editor_hint:
		return
	
	if body is Player and _player == null:
		_player = body
		_player.connect("activate", self, "_on_player_activate")


func _on_body_exited(body) -> void:
	if body == _player:
		_player.disconnect("activate", self, "_on_player_activate")
		_player = null

func _on_player_activate() -> void:
	if _player:
		if battery_amount >= 0.0:
			if _player.give_battery(battery_amount):
				set_battery_amount(-1.0)
		else:
			set_battery_amount(_player.take_battery())

