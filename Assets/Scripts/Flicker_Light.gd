extends Light2D
tool

const MIN_DURATION = 0.1
const MAX_DURATION = 0.4

export (float, 0.1, 10.0) var min_energy = 0.5
export (float, 0.1, 10.0) var max_energy = 1.0
export var enable_flicker : bool = true

var _tween : Tween = null
var _rand : RandomNumberGenerator = null

func set_enable_flicker(f : bool) -> void:
	enable_flicker = f
	if enable_flicker:
		_flick()

func set_visible(vis : bool) -> void:
	.set_visible(vis)
	if vis:
		_flick()

func _ready() -> void:
	_rand = RandomNumberGenerator.new()
	_rand.randomize()
	
	_tween = Tween.new()
	add_child(_tween)
	_tween.connect("tween_all_completed", self, "_on_flick_complete")
	_flick()

func _flick() -> void:
	if enable_flicker:
		if _tween.is_active():
			return
		
		var nenergy = _rand.randf_range(min_energy, max_energy)
		var duration = _rand.randf_range(MIN_DURATION, MAX_DURATION)
		_tween.interpolate_property(
			self, "energy",
			energy, nenergy,
			duration,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
		)
		_tween.start()
	else:
		energy = max_energy


func _on_flick_complete() -> void:
	if visible:
		_flick()
