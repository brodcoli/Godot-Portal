extends Node

var _rng = RandomNumberGenerator.new()
var last_steps_tracker = {}

func play(path: String, pos: Vector3):
	var s = get_node(path)
	s.translation = pos
	s.play()
	
func play_rand(path: String, pos: Vector3, id: String = ""):
	var sfx = get_node(path).get_children()
	var tracker_count = max(sfx.size() - 2, 1)
	
	var last_steps = []
	if last_steps_tracker.has(id):
		last_steps = last_steps_tracker[id]
	else:
		last_steps_tracker[id] = []
		for i in range(tracker_count):
			last_steps_tracker[id].append("")
		
	
	while true:
		var s = sfx[floor(_rng.randf() * sfx.size())] as AudioStreamPlayer3D
		if not last_steps.has(s.name):
			last_steps.pop_front()
			last_steps.append(s.name)
			s.translation = pos
			s.play()
			return s.name
			
func play_rand_player(path: String, id: String = ""):
	play_rand(path, get_tree().get_nodes_in_group("player")[0].translation, id)
	
func play_rand_player_feet(path: String, id: String = ""):
	play_rand(path, get_tree().get_nodes_in_group("player")[0].get_node("Feet").global_transform.origin, id)
	
func play_player(path: String):
	play(path, get_tree().get_nodes_in_group("player")[0].translation)
