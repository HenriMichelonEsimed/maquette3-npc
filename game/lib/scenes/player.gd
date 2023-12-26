class_name Player extends CharacterBody3D

signal start_moving()
signal moving()
signal stop_moving()
signal endurance_change()

const ANIM_STANDING = "idle"
const ANIM_WALKING = "walk"
const ANIM_RUNNING = "run"
const ANIM_DIEING = "die"
const ANIM_ATTACKING= "attack_sword_1"
const ANIM_USING= "use"

@export var camera_pivot:Node3D

@onready var interactions = $Interactions
@onready var anim:AnimationPlayer = $AnimationPlayer 
@onready var timer_use:Timer = $TimerUse
@onready var raycast_to_floor:RayCast3D = $RayCastToFloor
@onready var audio:AudioStreamPlayer3D = $AudioStreamPlayer

const walking_speed:float = 7.0
const running_speed:float = 14.0
const walking_jump_impulse:float = 20.0

var camera:IsometricCamera
var character:Node3D
var attach_item:Node3D

# for move_and_slide()
var speed:float = 0.0
var fall_acceleration:float = 200.0
var target_velocity:Vector3 = Vector3.ZERO
# for mouse clic-to-move
var move_to_target = null
var move_to_previous_position = null

# isometric current view rotation
var current_view:int = 0
# player movement signaled
var signaled:bool = false

# action animation playing
var attack_cooldown:bool = false
# one hit only allowed during attack cooldown
var hit_allowed:bool = false
# running animation playing
var running:bool = false
# approx height
var height:float = 1.7
# weapon speed animation scale
var attack_speed_scale:float = 1.0

# movement sounds
var sound_walking:AudioStream
var sound_walking_name:String
#@onready var sound_swimming:AudioStream = load("res://assets/audio/water/swimming.mp3")

const directions = {
	"forward" : 	[  { 'x':  1, 'z': -1 },  { 'x':  1, 'z':  1 },  { 'x': -1, 'z':  1 },  { 'x': -1, 'z': -1 } ],
	"left" : 		[  { 'x': -1, 'z': -1 },  { 'x':  1, 'z': -1 },  { 'x':  1, 'z':  1 },  { 'x': -1, 'z':  1 } ],
	"backward" : 	[  { 'x': -1, 'z':  1 },  { 'x': -1, 'z': -1 },  { 'x':  1, 'z': -1 },  { 'x':  1, 'z':  1 } ],
	"right" : 		[  { 'x':  1, 'z':  1 },  { 'x': -1, 'z':  1 },  { 'x': -1, 'z': -1 },  { 'x':  1, 'z': -1 } ]
}

func _ready():
	character = get_node("Character")
	camera = camera_pivot.get_node("Camera")
	camera.connect("view_rotate", _on_view_rotate)
	attach_item = character.get_node("RootNode/Skeleton3D/HandAttachment/AttachmentPoint")
	update_floor()

func _unhandled_input(_event):
	if (attack_cooldown) or (GameState.player_state.hp <= 0): return
	if Input.is_action_pressed("player_moveto"):
		move_to(get_viewport().get_mouse_position())
	elif Input.is_action_just_released("player_moveto"):
		stop_move_to()

func _physics_process(delta):
	if (GameState.player_state.hp <= 0): return
	if Input.is_action_pressed("use") and (not attack_cooldown) and (GameState.current_item != null) and (GameState.current_item is ItemWeapon) and (interactions.node_to_use == null):
		if (not GameState.use_joypad) : 
			look_to(get_viewport().get_mouse_position())
		anim.play(ANIM_ATTACKING, 0.2, attack_speed_scale)
		hit_allowed = true
		timer_use.wait_time =  GameMechanics.attack_cooldown(GameState.current_item.speed)
		move_to_target = null
		running = false
		attack_cooldown = true
		timer_use.start()
	if (attack_cooldown): 
		_regen_endurance()
		return
	var on_floor = is_on_floor_only() 
	if (move_to_target != null):
		if Input.is_action_pressed("player_right") or  Input.is_action_pressed("player_left") or  Input.is_action_pressed("player_backward") or  Input.is_action_pressed("player_forward"):
			stop_move_to()
		else:
			if (position.distance_to(move_to_target) < 0.1):
				stop_move_to()
				return
			var look_at_target = move_to_target
			look_at_target.y = position.y
			look_at(look_at_target)
			_run_or_walk()
			velocity = -transform.basis.z * speed
			if (move_to_target.y > position.y):
				for index in range(get_slide_collision_count()):
					var collision = get_slide_collision(index)
					if (collision == null): return
					var collider = collision.get_collider()
					if collider.is_in_group("stairs"):
						velocity.y = 5
			elif not on_floor:
				velocity.y = velocity.y - (fall_acceleration * 2 * delta)
			move_to_previous_position = position
			move_and_slide()
			SimpleGrass.set_player_position(global_position) 
			_update_camera()
			return
		
	var no_jump = false
	var direction = Vector3.ZERO
	if Input.is_action_pressed("player_right"):
		direction.x += directions["right"][current_view].x
		direction.z += directions["right"][current_view].z
	if Input.is_action_pressed("player_left"):
		direction.x += directions["left"][current_view].x
		direction.z += directions["left"][current_view].z
	if Input.is_action_pressed("player_backward"):
		direction.x += directions["backward"][current_view].x
		direction.z += directions["backward"][current_view].z
	if Input.is_action_pressed("player_forward"):
		direction.x += directions["forward"][current_view].x
		direction.z += directions["forward"][current_view].z
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		look_at(position + direction, Vector3.UP)
		_run_or_walk()
		for index in range(get_slide_collision_count()):
			var collision = get_slide_collision(index)
			if (collision == null): return
			var collider = collision.get_collider()
			if collider.is_in_group("stairs"):
				target_velocity.y = 5
	else:
		target_velocity.y = 0
		signaled = false
		running = false
		stop_moving.emit()
		anim.play(ANIM_STANDING, 0.2)
		_regen_endurance()
		audio.stop()
	
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	
	if not on_floor:
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	if on_floor and Input.is_action_just_pressed("player_jump") and !no_jump:
		target_velocity.y = walking_jump_impulse
		#anim.play(Consts.ANIM_JUMPING)
	velocity = target_velocity
	move_and_slide()
	SimpleGrass.set_player_position(global_position) 
	if direction != Vector3.ZERO:
		_update_camera()

func _run_or_walk():
	update_floor()
	if Input.is_action_pressed("modifier"):
		GameState.player_state.endurance -= 2
		endurance_change.emit()
		if (GameState.player_state.endurance > 0):
			if (not running):
				audio.pitch_scale = 1.5
				speed = running_speed
				anim.play(ANIM_RUNNING, 0.1)
				running = true
		else:
			audio.pitch_scale = 1.0
			_regen_endurance()
			speed = walking_speed
			anim.play(ANIM_WALKING, 0.1)
	else:
		audio.pitch_scale = 1.0
		_regen_endurance()
		running = false
		speed = walking_speed
		anim.play(ANIM_WALKING, 0.1)
	if (not audio.playing) :
		audio.play()
	moving.emit()

func move(pos:Vector3, rot:Vector3):
	position = pos
	rotation = rot
	_update_camera()

func _update_camera():
	camera_pivot.position = position
	camera_pivot.position.y += 1.5
	if (!signaled) :
		start_moving.emit()
		signaled = true

func _regen_endurance():
	if (GameState.player_state.endurance < GameState.player_state.endurance_max):
		GameState.player_state.endurance += 1
		endurance_change.emit()

func move_to(target:Vector2):
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.collision_mask = 0x1
	ray_query.from = camera.project_ray_origin(target)
	ray_query.to = ray_query.from + camera.project_ray_normal(target) * 1000
	var iray = get_world_3d().direct_space_state.intersect_ray(ray_query)
	if (iray.size() > 0):
		move_to_target = iray.position

func look_to(target:Vector2):
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.collision_mask = 0x1
	ray_query.from = camera.project_ray_origin(target)
	ray_query.to = ray_query.from + camera.project_ray_normal(target) * 1000
	var iray = get_world_3d().direct_space_state.intersect_ray(ray_query)
	if (iray.size() > 0):
		var pos = iray.position
		pos.y = position.y
		look_at(pos)

func stop_move_to():
	if (move_to_target != null):
		move_to_target = null
		velocity = Vector3.ZERO

func _look_at(node:Node3D):
	var pos = node.global_position
	pos.y = position.y
	look_at(pos)

func _on_view_rotate(view:int):
	current_view = view

#func print_property_list(parent):
#	print(parent.get_name())
#	var list = parent.get_property_list()
#	for prop in list:
#		print("	> " + prop["name"])
#	print("---")

func handle_item():
	attach_item.add_child(GameState.current_item)
	if (GameState.current_item is ItemWeapon):
		attack_speed_scale = GameMechanics.anim_scale(GameState.current_item.speed)
	if (GameState.current_item.use_area != null):
		GameState.current_item.use_area.connect("body_entered", _on_item_hit)

func unhandle_item():
	if (GameState.current_item.use_area != null):
		GameState.current_item.use_area.disconnect("body_entered", _on_item_hit)
	attach_item.remove_child(GameState.current_item)

func hit(hit_by:ItemWeapon):
	if (GameState.player_state.hp <= 0): return
	var damage_points = min(hit_by.damages_roll.roll(), GameState.player_state.hp)
	GameState.player_state.hp -= damage_points
	velocity = Vector3.ZERO
	NotificationManager.hit(self, hit_by, damage_points, false)
	if (GameState.player_state.hp  <= 0):
		anim.play(ANIM_DIEING, 0.2)

func _on_item_hit(node:Node3D):
	if (hit_allowed):
		hit_allowed = false
		if (node is EnemyCharacter):
			node.hit(GameState.current_item)

func _on_timer_attack_timeout():
	attack_cooldown = false

func _to_string():
	return GameState.player_state.nickname

func _on_animation_tree_animation_finished(anim_name):
	if (anim_name == ANIM_DIEING):
		Tools.load_dialog(self, Tools.DIALOG_GAMEOVER).open()

func update_floor():
	raycast_to_floor.force_raycast_update()
	if (raycast_to_floor.is_colliding()):
		var floor = raycast_to_floor.get_collider()
		if (floor != null):
			var play = audio.playing
			var audio_name = "default"
			if (floor is Terrain3D):
				var idx = floor.storage.get_texture_id(global_position).x
				var texture_name = floor.texture_list.get_texture(idx).name
				if (Sounds.TERRAIN.has(texture_name)):
					audio_name = Sounds.TERRAIN[texture_name]
			elif (floor is Floor) and (not floor.sound.is_empty()):
				audio_name = floor.sound
			if (sound_walking_name != audio_name):
				sound_walking = Tools.load_audio("terrain", audio_name)
				sound_walking_name = audio_name
				audio.stream = sound_walking
				audio.play()
