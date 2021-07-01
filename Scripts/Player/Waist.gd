extends Area

onready var _player = get_node("..")

var entered = 0

func _on_area_entered(area):
	if area is Water:
		entered += 1
		if entered > 0:
			_player.water_is_at_waist = true

func _on_area_exited(area):
	if area is Water:
		entered -= 1
		if entered == 0:
			_player.water_is_at_waist = false
