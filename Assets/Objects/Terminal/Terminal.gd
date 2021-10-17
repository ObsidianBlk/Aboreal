extends Node2D


signal shift_up(amount)
signal shift_down(amount)
signal switch(on)


# ---------------------------------------------------------------------------
# Export Variables
# ---------------------------------------------------------------------------
export var powered : bool = false
export var switch : bool = true
export var switch_state : bool = false
export (float, 0.01, 1.0, 0.001) var amount_per_second = 1.0

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
var _player : Player = null

# ---------------------------------------------------------------------------
# Onready Variables
# ---------------------------------------------------------------------------
onready var anim_node = get_node("Anim")
onready var light_node = get_node("Light2D")
onready var usetimer_node = get_node("UseTimer")

# ---------------------------------------------------------------------------
# Setters / Getters
# ---------------------------------------------------------------------------
func set_powered(p : bool) -> void:
	powered = p
	_UpdatePower()

# ---------------------------------------------------------------------------
# Override Methods
# ---------------------------------------------------------------------------
func _ready() -> void:
	set_powered(powered)
	set_process(false)


func _process(delta : float) -> void:
	if _player == null:
		return
	
	if Input.is_action_pressed("left"):
		emit_signal("shift_down", amount_per_second * delta)
	if Input.is_action_pressed("right"):
		emit_signal("shift_up", amount_per_second * delta)
	if Input.is_action_just_pressed("activate") or Input.is_action_just_pressed("up"):
		set_process(false)
		_player.using(false)


# ---------------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------------

func _UpdatePower() -> void:
	if anim_node:
		if powered:
			light_node.visible = true
			anim_node.play("active")
		else:
			light_node.visible = false
			anim_node.play("idle")

# ---------------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------------



# ---------------------------------------------------------------------------
# Handler Methods
# ---------------------------------------------------------------------------

func _on_body_entered(body) -> void:
	if body is Player and _player == null:
		_player = body
		_player.connect("activate", self, "_on_player_activate")


func _on_body_exited(body):
	if body == _player:
		_player.disconnect("activate", self, "_on_player_activate")
		_player = null

func _on_player_activate() -> void:
	if _player != null and powered:
		if switch:
			_player.using()
			usetimer_node.start()
		else:
			_player.using()
			set_process(true)

func _on_UseTimer_timeout():
	if _player != null and switch:
		_player.using(false)
		switch_state = not switch_state
		emit_signal("switch", switch_state)
