extends Node2D


# ---------------------------------------------------------------------------
# ENUMs, Signals, and Constants
# ---------------------------------------------------------------------------

signal value_change(value)

enum MODE {PROGRESS, SLIDER}

const _FRAMES = {
	MODE.PROGRESS : [0,1,2,3,4,5,6,7,8,9,10],
	MODE.SLIDER : [1,11,12,13,14,15,16,17,18,19,20]
}

# ---------------------------------------------------------------------------
# Export Variables
# ---------------------------------------------------------------------------
export (MODE) var mode = MODE.PROGRESS
export (float, 0.0, 1.0) var value = 0.0

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------


# ---------------------------------------------------------------------------
# Onready Variables
# ---------------------------------------------------------------------------
onready var sprite_node = get_node("Sprite")


# ---------------------------------------------------------------------------
# Setters / Getters
# ---------------------------------------------------------------------------
func set_mode(m : int) -> void:
	if m == MODE.PROGRESS or m == MODE.SLIDER:
		mode = m
		_UpdateSprite()

func set_value(v : float) -> void:
	value = max(0.0, min(1.0, v))
	_UpdateSprite()

# ---------------------------------------------------------------------------
# Override Methods
# ---------------------------------------------------------------------------
func _ready() -> void:
	_UpdateSprite()

# ---------------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------------
func _UpdateSprite() -> void:
	if sprite_node:
		var idx = int(floor(value * 10))
		sprite_node.frame = _FRAMES[mode][idx]

# ---------------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------------
func slide_up(amount : float) -> void:
	var ov = value
	set_value(value + amount)
	if value != ov:
		emit_signal("value_change", value)

func slide_down(amount : float) -> void:
	var ov = value
	set_value(value - amount)
	if value != ov:
		emit_signal("value_change", value)


# ---------------------------------------------------------------------------
# Handler Methods
# ---------------------------------------------------------------------------


