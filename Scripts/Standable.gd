extends KinematicBody

class_name Standable

var move_with_platforms = true
var _ray: RayCast
var _last_platform_pos = null

func _ready():
	_ray = RayCast.new()
	_ray.translation.y = 1
	_ray.enabled = true
	_ray.cast_to = Vector3.DOWN * 2
	self.add_child(_ray)
	
func _get_platform_movement():
	var body = _ray.get_collider()
	if body is Platform:
		if _last_platform_pos == null:
			_last_platform_pos = body.global_transform.origin
		else:
			var moved = body.global_transform.origin - _last_platform_pos
			_last_platform_pos = body.global_transform.origin
			return moved
	return Vector3.ZERO
	
func move_along_platform(delta):
	if delta == 0:
		delta = 0.0001
	var move = _get_platform_movement() * (1 / delta)
	if not move == Vector3.ZERO:
		move_and_slide(move)
		
func _process(delta):
	if move_with_platforms:
		move_along_platform(delta)
	
