extends Camera2D
class_name Tracker_Camera


# ----------------------------------------------------------------
# Export Variables
# ----------------------------------------------------------------
export var target_node_path : NodePath = ""		setget set_target_node_path

# ----------------------------------------------------------------
# Variables
# ----------------------------------------------------------------
var target = null
var tween_node : Tween = null
var transitioning : bool = false

# ----------------------------------------------------------------
# Setters / Getters
# ----------------------------------------------------------------

func set_target_node_path(tnp : NodePath) -> void:
	target_node_path = tnp
	if tnp == "":
		target = null
		set_process(false)
	else:
		target = get_node_or_null(target_node_path)
		if target != null and not transitioning:
			set_process(true)


func set_target_node(tn : Node2D) -> void:
	if target != tn:
		if tn != null:
			var tnp = get_path_to(tn)
			target_node_path = tnp
			target = tn
			if not transitioning:
				set_process(true)
		else:
			target_node_path = ""
			target = null
			set_process(false)


# ----------------------------------------------------------------
# Override Methods
# ----------------------------------------------------------------
func _ready() -> void:
	set_process(false)
	tween_node = Tween.new()
	add_child(tween_node)
	tween_node.connect("tween_all_completed", self, "_on_transition_complete")
	if target_node_path != "":
		set_target_node_path(target_node_path)


func _process(delta : float) -> void:
	if not target:
		return
	
	var pos = target.global_position
	global_position = pos


# ----------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------
func transition_to(target_node : Node2D, duration : float) -> void:
	if transitioning:
		print("WARNING: Transition already in progress. Cannot start a new transition.")
		return

	if duration <= 0.0:
		set_target_node(target_node)
		return
	
	if target != null:
		set_process(false)
	transitioning = true
	if target_node != target:
		set_target_node(target_node)
		
	tween_node.interpolate_property(
		self, "global_position",
		global_position, target_node.global_position,
		duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween_node.start()


# ----------------------------------------------------------------
# Handler Methods
# ----------------------------------------------------------------
func _on_transition_complete() -> void:
	transitioning = false
	if target != null:
		set_process(true)

