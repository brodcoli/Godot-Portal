extends ClippedCamera

onready var water = get_node("../../../CanvasLayer/Water")

const third_person_distance = 20
onready var _player = $"../../.."
var water_entered = 0
var third_person = false
var angular_velocity = Vector3.ZERO

func _process(delta):
	var toggled_view = Input.is_action_just_pressed("toggle_view")
	
	angular_velocity = $"motion_blur".ang_vel
	
	if toggled_view:
		third_person = not third_person
		if third_person:
			$"..".translation.z = third_person_distance
		else:
			$"..".translation.z = 0

func _on_area_entered(area):
	if area is Water:
		water_entered += 1
		if water_entered > 0:
			_player.water_is_at_head = true
			water.visible = true
			AudioServer.set_bus_effect_enabled(0, 1, true)


func _on_area_exited(area):
	if area is Water:
		water_entered -= 1
		if water_entered == 0:
			_player.water_is_at_head = false
			water.visible = false
			AudioServer.set_bus_effect_enabled(0, 1, false)
