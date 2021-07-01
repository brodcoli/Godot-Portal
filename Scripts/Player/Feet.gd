extends Area

onready var _player = get_node("..")
const _default_path = "Steps/Default"
var step_audio_path = _default_path
var last_color = Color(0, 0, 0)
var last_body

func _on_area_entered(area_id, area, area_shape, local_shape):
	if area is Water:
		_player.water_is_at_feet = true

func _on_area_exited(area_id, area, area_shape, local_shape):
#	if area is StepArea:
#		step_audio_path = _default_path
	if area is Water:
		_player.water_is_at_feet = false

func _on_body_entered(body):
	last_body = body
