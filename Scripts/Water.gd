extends Area

class_name Water

export var visual = true

const _player_dist_buffer = 1
const _particles_per_unit = 0.005
var _player: Player
var _volume = 1

func _ready():
	_player = get_tree().get_nodes_in_group("player")[0]
	_volume = scale.x * scale.y * scale.z
	$WaterParticles.amount = _volume * _particles_per_unit
	
	for mesh in $Meshes/EditorOnly.get_children():
		mesh.queue_free()
	
	if not visual:
		for mesh in $Meshes.get_children():
			mesh.queue_free()


func _on_body_entered_particle_area(body):
	if body is Player:
		$WaterParticles.emitting = true

func _on_body_exited_particle_area(body):
	if body is Player:
		$WaterParticles.emitting = false
