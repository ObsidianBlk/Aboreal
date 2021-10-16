extends Node


export (AudioCtrl.BUS) var audio_bus = AudioCtrl.BUS.MASTER
export var value_node_path : NodePath = ""


func _ready() -> void:
	if value_node_path != "":
		var vnode = get_node_or_null(value_node_path)
		vnode.connect("value_change", self, "set_value")
		vnode.set_value(AudioCtrl.get_bus_volume(audio_bus))
	else:
		print("WARNING: Audio Monitor failed to find a ValueNode")

func set_value(value : float) -> void:
	AudioCtrl.set_bus_volume(audio_bus, max(0.0, min(1.0, value)))
