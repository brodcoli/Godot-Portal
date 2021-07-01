extends KinematicBody

#A lot of the code in this script comes from here: https://github.com/turtlewit/VineCrawler/blob/master/PlayerNew.gd

var noclip = false

var cmd = {
	forward_move 	= 0.0,
	right_move 		= 0.0,
	up_move 		= 0.0
}

const walk_speed = 6 #4
const sprint_speed = 10 #7
const crouch_speed = 2
const noclip_speed = 40
const jump_speed = 5.3 #4 #8
const water_vertical_swim_speed = 0.7
const water_h_vel_mult = 0.5
const water_v_vel_mult = 0.7
const noclip_hyper_speed = 200
const gravity_strength = 15
var water_vel = Vector3.ZERO

var water_was_at_waist = false
var water_was_at_head = false

var x_mouse_sensitivity = .1

var gravity = gravity_strength #7

var friction = 6.0 #7

var move_speed = 15.0
var run_acceleration = 20.0 #14
var run_deacceleration = 12.0 #10
var air_acceleration = 0.7
var air_deacceleration = 2.0
var air_control = 0.3
var side_strafe_acceleration = 50.0 #0
var side_strafe_speed = 1.0 #0
var move_scale = 1.0

var ground_snap_tolerance = 1

var move_direction_norm = Vector3()

var up = Vector3(0,1,0)

var wish_jump = false
var ground_wish_dir = Vector3.ZERO
var air_wish_dir = Vector3.ZERO

var touching_ground = false

var _player: Spatial
var _head: Spatial
var _collision_shape: CollisionShape
var _crouch_animator
var step_rays: Spatial
var feet_ray: RayCast
var test_ray: RayCast

var _last_bubble = 0

func init(player: Spatial, head: Spatial, collision_shape: CollisionShape):
	_player = player
	_head = head
	_collision_shape = collision_shape
	_crouch_animator = _player.get_node("CrouchAnimator")
	step_rays = _player.get_node("StepRays")
	feet_ray = _player.get_node("StepRays/Feet")
	test_ray = _player.get_node("StepRays/Test")
	set_physics_process(true)

func process_movement(delta):
	var is_sprinting = Input.is_action_pressed("sprint")
	var is_jumping = Input.is_action_pressed("jump")
	var is_crouching = Input.is_action_pressed("crouch")
	var just_jumped = Input.is_action_just_pressed("jump")
	var just_crouched = Input.is_action_just_pressed("crouch")
	var just_uncrouched = Input.is_action_just_released("crouch")
	
	if just_crouched:
		crouch()
	elif just_uncrouched:
		uncrouch()
		
	if noclip:
		var forward = int(Input.is_action_pressed("move_forward")) - int(Input.is_action_pressed("move_backward"))
		var right = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
		var up = int(Input.is_action_pressed("noclip_up")) - int(Input.is_action_pressed("noclip_down"))
		
		var speed = noclip_speed
		if is_crouching:
			speed = noclip_hyper_speed
		touching_ground = false
		_player.velocity = Vector3.ZERO
		var h = Vector3.ZERO
		var v = Vector3.ZERO
		h += _head.global_transform.basis.x * right
		h += _head.global_transform.basis.z * -forward
		v += Vector3.UP * up
		_player.translation += (h + v) * speed * delta
	else:
		_queue_jump()
		if touching_ground and not _player.water_is_at_waist:
			_ground_move(delta)
			if _player.is_on_wall():
				_try_step()
		else:
			_air_move(delta)
		
		var vel_h = Vector3(_player.velocity.x, 0, _player.velocity.z)
		var vel_v = Vector3(0, _player.velocity.y, 0)
		
		var speed = walk_speed
		if touching_ground:
			if is_sprinting:
				speed = sprint_speed
			elif is_crouching:
				speed = crouch_speed
			
		if vel_h.length() > speed:
			vel_h = vel_h.normalized() * speed
				
		vel_v.y -= gravity * delta #GRAVITY
		_player.velocity = vel_h + vel_v
		
		if _player.water_is_at_feet:
			air_acceleration = 3
		else:
			air_acceleration = 0.7
			
		if _player.water_is_at_head:
			if not water_was_at_head:
				_player.get_node("Underwater").play()
			var delta_vel = _player.delta_velocity.abs()
			var dramatic_acc = delta_vel.x > 0.2 or delta_vel.y > 0.2 or delta_vel.z > 0.2
			if dramatic_acc and OS.get_ticks_msec() - _last_bubble > 300:
				Audio.play_rand_player("Water/Bubble", "bubble")
				_last_bubble = OS.get_ticks_msec()
			if _player.get_node("Head/CameraOffset/Camera").angular_velocity.length() > 0.1 and OS.get_ticks_msec() - _last_bubble > 200:
				Audio.play_rand_player("Water/Bubble", "bubble")
				_last_bubble = OS.get_ticks_msec()
			water_was_at_head = true
		elif water_was_at_head:
			Audio.play_player("Water/Splash/SmallAlt")
			_player.get_node("Underwater").stop()
			water_was_at_head = false
		if _player.water_is_at_waist:
			if not water_was_at_waist:
				water_vel = _player.velocity
				if water_vel.length() > 30:
					Audio.play_player("Water/Splash/Big")
				elif water_vel.length() > 15:
					Audio.play_player("Water/Splash/Medium")
				elif water_vel.length() > 10:
					Audio.play_player("Water/Splash/Small")
				elif water_vel.length() > 2:
					Audio.play_player("Water/Splash/Soft")
				else:
					Audio.play_rand_player("Water/Bubble", "bubble")
			water_was_at_waist = true
			water_vel += air_wish_dir * 0.5
			if air_wish_dir.length() == 0:
				water_vel.y -= 0.05
			if water_vel.length() > 15:
				water_vel = water_vel.normalized() * 15
			elif water_vel.length() > 0.1:
				water_vel *= 0.94
			else:
				water_vel = Vector3.ZERO
			
			_player.velocity = water_vel
		elif water_was_at_waist:
			water_was_at_waist = false
			if _player.is_on_wall():
				_player.velocity.y = 6
				crouch()
				yield(_player.get_tree().create_timer(0.2), "timeout")
				uncrouch(0.5)
				
		_player.velocity += _player.added_velocity
		_player.added_velocity = Vector3.ZERO
		
		#_player.velocity = _player.velocity.rotated(Vector3(1, 0, 0), _player.rotation.x).rotated(Vector3(0, 1, 0), _player.rotation.y).rotated(Vector3(0, 0, 1), _player.rotation.z)
		
		if just_jumped or _player.water_is_at_waist:
			_player.velocity = _player.move_and_slide(_player.velocity, up, false, 4, 0.785398, false)
		else:
			_player.velocity = _player.move_and_slide_with_snap(_player.velocity, Vector3.DOWN * 0.1, up, true, 4, 0.785398, false)
		
		touching_ground = _player.is_on_floor()
		
		return _player.velocity

func _try_step():
	var rot = Vector2(-ground_wish_dir.x, ground_wish_dir.z).rotated(PI / 2).angle()#Vector2(_player.velocity.x, _player.velocity.z).angle()
	for ray in step_rays.get_children():
		ray.rotation.y = rot
		ray.enabled = true
		ray.force_raycast_update()
	if feet_ray.is_colliding():
		test_ray.translation.y = feet_ray.translation.y
		var height = 0
		for i in range(10):
			test_ray.translation.y += 0.1
			test_ray.force_raycast_update()
			if not test_ray.is_colliding():
				height = test_ray.translation.y
				break
		if height < 0.8:
			var col = _player.move_and_collide(Vector3(0, height + 0.2, 0) + test_ray.cast_to.normalized().rotated(Vector3.UP, rot)*0.1, true, true, true)
			if not col or not col.collider:
				_player.move_and_collide(Vector3(0, height, 0))
	for ray in step_rays.get_children():
		ray.enabled = false

func crouch(speed = 1.0):
	_crouch_animator.playback_speed = speed
	_crouch_animator.play("Crouch")
	yield(_crouch_animator, "animation_finished")
	_crouch_animator.playback_speed = 1.0
	
func uncrouch(speed = 1.0):
	_crouch_animator.playback_speed = speed
	_crouch_animator.play("Stand")
	yield(_crouch_animator, "animation_finished")
	_crouch_animator.playback_speed = 1.0

func _snap_to_ground(from):
	#var from = global_transform.origin
	var to = from + -_head.global_transform.basis.y * ground_snap_tolerance
	var space_state = get_world().get_direct_space_state()

	var result = space_state.intersect_ray(from, to)
	if !result.empty():
		_head.global_transform.origin.y = result.position.y

func _set_movement_dir():
	cmd.forward_move = 0.0
	cmd.right_move = 0.0
	cmd.forward_move += int(Input.is_action_pressed("move_forward"))
	cmd.forward_move -= int(Input.is_action_pressed("move_backward"))
	cmd.right_move += int(Input.is_action_pressed("move_right"))
	cmd.right_move -= int(Input.is_action_pressed("move_left"))

func _queue_jump():
	if Input.is_action_just_pressed("jump") and !wish_jump:
		wish_jump = true
	if Input.is_action_just_released("jump"):
		wish_jump = false

func _air_move(delta):
	var wishdir = Vector3()
	var wishvel = air_acceleration
	var accel = 0.0

	var scale = _cmd_scale()

	_set_movement_dir()

	wishdir += _head.global_transform.basis.x * cmd.right_move
	wishdir -= _head.global_transform.basis.z * cmd.forward_move

	var wishspeed = wishdir.length()
	wishspeed *= move_speed

	wishdir = wishdir.normalized()
	move_direction_norm = wishdir

	var wishspeed2 = wishspeed
	if _player.velocity.dot(wishdir) < 0:
		accel = air_deacceleration
	else:
		accel = air_acceleration

	if(cmd.forward_move == 0) and (cmd.right_move != 0):
		if wishspeed > side_strafe_speed:
			wishspeed = side_strafe_speed
		accel = side_strafe_acceleration

	_accelerate(wishdir, wishspeed, accel, delta)
	if air_control > 0:
		_air_control(wishdir, wishspeed2, delta)

	air_wish_dir = wishdir
	#_player.velocity.y -= gravity * delta

func _air_control(wishdir, wishspeed, delta):
	var zspeed = 0.0
	var speed = 0.0
	var dot = 0.0
	var k = 0.0

	if (abs(cmd.forward_move) < 0.001) or (abs(wishspeed) < 0.001):
		return
	zspeed = _player.velocity.y
	_player.velocity.y = 0

	speed = _player.velocity.length()
	if not _player.water_is_at_waist:
		_player.velocity = _player.velocity.normalized()

	dot = _player.velocity.dot(wishdir)
	k = 32.0
	k *= air_control * dot * dot * delta

	if dot > 0:
		_player.velocity.x = _player.velocity.x * speed + wishdir.x * k
		_player.velocity.y = _player.velocity.y * speed + wishdir.y * k 
		_player.velocity.z = _player.velocity.z * speed + wishdir.z * k 

		if not _player.water_is_at_waist:
			_player.velocity = _player.velocity.normalized()
		move_direction_norm = _player.velocity

	_player.velocity.x *= speed 
	_player.velocity.y = zspeed 
	_player.velocity.z *= speed 

func _ground_move(delta):
	var wishdir = Vector3()

	if (!wish_jump):
		_apply_friction(1.0, delta)
	else:
		_apply_friction(0, delta)

	_set_movement_dir()

	var scale = _cmd_scale()

	wishdir += _head.global_transform.basis.x * cmd.right_move
	wishdir -= _head.global_transform.basis.z * cmd.forward_move

	wishdir = wishdir.normalized()
	move_direction_norm = wishdir

	var wishspeed = wishdir.length()
	wishspeed *= move_speed

	_accelerate(wishdir, wishspeed, run_acceleration, delta)

	_player.velocity.y = 0.0

	if wish_jump:
		_player.velocity.y = jump_speed
		wish_jump = false
		
	ground_wish_dir = wishdir

func _apply_friction(t, delta):
	var vec = _player.velocity
	var speed = 0.0
	var newspeed = 0.0
	var control = 0.0
	var drop = 0.0

	vec.y = 0.0
	speed = vec.length()
	drop = 0.0

	if touching_ground:
		if speed < run_deacceleration:
			control = run_deacceleration
		else:
			control = speed
		drop = control * friction * delta * t

	newspeed = speed - drop;
	if newspeed < 0:
		newspeed = 0
	if speed > 0:
		newspeed /= speed

	_player.velocity.x *= newspeed
	_player.velocity.z *= newspeed

func _accelerate(wishdir, wishspeed, accel, delta):
	var addspeed = 0.0
	var accelspeed = 0.0
	var currentspeed = 0.0

	currentspeed = _player.velocity.dot(wishdir)
	addspeed = wishspeed - currentspeed
	if addspeed <=0:
		return
	accelspeed = accel * delta * wishspeed
	if accelspeed > addspeed:
		accelspeed = addspeed

	_player.velocity.x += accelspeed * wishdir.x
	_player.velocity.z += accelspeed * wishdir.z

func _cmd_scale():
	var var_max = 0
	var total = 0.0
	var scale = 0.0

	var_max = int(abs(cmd.forward_move))
	if(abs(cmd.right_move) > var_max):
		var_max = int(abs(cmd.right_move))
	if var_max <= 0:
		return 0

	total = sqrt(cmd.forward_move * cmd.forward_move + cmd.right_move * cmd.right_move)
	scale = move_speed * var_max / (move_scale * total)

	return scale
			
func process(delta):
	var just_noclip = Input.is_action_just_pressed("noclip")
	
	if just_noclip:
		noclip = not noclip
		if noclip:
			gravity = 0
			_collision_shape.disabled = true
		else:
			gravity = gravity_strength
			_collision_shape.disabled = false

func input(event):
	if event is InputEventMouseMotion and _player.mouse_captured:
		_head.rotation_degrees.y -= event.relative.x * _player.mouse_sensitivity / 10
		_head.rotation_degrees.x = clamp(_head.rotation_degrees.x - event.relative.y * _player.mouse_sensitivity / 10, -90, 90)

