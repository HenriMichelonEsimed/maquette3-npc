class_name Player extends CharacterBody3D

signal start_moving()
signal stop_moving()

const ANIM_STANDING = "idle"
const ANIM_WALKING = "walk"
const ANIM_RUNNING = "run"
const ANIM_ATTACK= "attack"
const ANIM_SWORD_SLASH = "default/sword_slash_1_v%d"

@export var camera_pivot:Node3D

@onready var interactions = $Interactions
@onready var anim_player:AnimationPlayer = $AnimationPlayer 
@onready var anim_tree:AnimationTree = $AnimationTree

const walking_speed:float = 7.0
const running_speed:float = 14.0
const walking_jump_impulse:float = 20.0

var anim_state:AnimationNodeStateMachinePlayback
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
var action:bool = false
# hit during action
var action_hit:bool = false
# running animation playing
var running:bool = false
# attack animation state node
var anim_attack:AnimationNodeAnimation

const directions = {
	"forward" : 	[  { 'x':  1, 'z': -1 },  { 'x':  1, 'z':  1 },  { 'x': -1, 'z':  1 },  { 'x': -1, 'z': -1 } ],
	"left" : 		[  { 'x': -1, 'z': -1 },  { 'x':  1, 'z': -1 },  { 'x':  1, 'z':  1 },  { 'x': -1, 'z':  1 } ],
	"backward" : 	[  { 'x': -1, 'z':  1 },  { 'x': -1, 'z': -1 },  { 'x':  1, 'z': -1 },  { 'x':  1, 'z':  1 } ],
	"right" : 		[  { 'x':  1, 'z':  1 },  { 'x': -1, 'z':  1 },  { 'x': -1, 'z': -1 },  { 'x':  1, 'z': -1 } ]
}

func _ready():
	character = get_node("Character")
	anim_state = anim_tree["parameters/playback"]
	anim_tree.connect("animation_finished", _on_animation_finished)
	camera = camera_pivot.get_node("Camera")
	camera.connect("view_rotate", _on_view_rotate)
	attach_item = character.get_node("RootNode/Skeleton3D/HandAttachment/AttachmentPoint")
	anim_attack =  anim_tree.get_tree_root().get_node("attack")

func _process(_delta):
	if Input.is_action_just_pressed("use") and (not action):
		move_to_target = null
		running = false
		action = true
		action_hit = false
		anim_state.travel(ANIM_ATTACK)
	if (action):
		return
	if Input.is_action_pressed("player_moveto"):
		move_to(get_viewport().get_mouse_position())
	elif Input.is_action_just_released("player_moveto"):
		stop_move_to()
	
func _on_animation_finished(anim:String):
	action = false
	pass
	
func _physics_process(delta):
	var on_floor = is_on_floor_only() 
	if (move_to_target != null):
		if Input.is_action_pressed("player_right") or  Input.is_action_pressed("player_left") or  Input.is_action_pressed("player_backward") or  Input.is_action_pressed("player_forward"):
			stop_move_to()
		else:
			var look_at_target = move_to_target
			look_at_target.y = position.y
			look_at(look_at_target)
			if (transform.origin.distance_to(move_to_target)) < 0.1:
				stop_move_to()
				return
			if Input.is_action_pressed("modifier"):
				if (not running):
					speed = running_speed
					anim_state.travel(ANIM_RUNNING)
					running = true
			else:
				running = false
				speed = walking_speed
				anim_state.travel(ANIM_WALKING)
			velocity = -transform.basis.z * speed
			
			if (move_to_target.y > position.y):
				for index in range(get_slide_collision_count()):
					var collision = get_slide_collision(index)
					var collider = collision.get_collider()
					if collider.is_in_group("stairs"):
						velocity.y = 5
			elif not on_floor:
				velocity.y = velocity.y - (fall_acceleration * 2 * delta)
			move_to_previous_position = position
			move_and_slide()
			if (position.distance_to(move_to_previous_position) < 0.001):
				stop_move_to()
				return
			camera_pivot.position = position
			camera_pivot.position.y += 1.5
			return
		
	var no_jump = false
	var direction = Vector3.ZERO
	if (not action):
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
			if Input.is_action_pressed("modifier"):
				if (not running):
					speed = running_speed
					anim_state.travel(ANIM_RUNNING)
					running = true
			else:
				speed = walking_speed
			anim_state.travel(ANIM_WALKING)
			for index in range(get_slide_collision_count()):
				var collision = get_slide_collision(index)
				var collider = collision.get_collider()
				if collider == null:
					continue
				if collider.is_in_group("stairs"):
					target_velocity.y = 5
					no_jump = true
				elif collider.is_in_group("ladders") and Input.is_action_pressed("player_jump"):
					target_velocity.y = 12
					no_jump = true
		else:
			target_velocity.y = 0
			signaled = false
			stop_moving.emit()
			anim_state.travel("idle")
			#if (not action):
			#	anim.play(Consts.ANIM_STANDING)
	
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	
	if not on_floor:
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	if on_floor and Input.is_action_just_pressed("player_jump") and !no_jump:
		target_velocity.y = walking_jump_impulse
		#anim.play(Consts.ANIM_JUMPING)
	velocity = target_velocity
	move_and_slide()
	if direction != Vector3.ZERO:
		camera_pivot.position = position
		camera_pivot.position.y += 1.5
		if (!signaled) :
			start_moving.emit()
			signaled = true

func move(pos:Vector3, rot:Vector3):
	position = pos
	rotation = rot

func move_to(target:Vector2):
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.collision_mask = 0x1
	ray_query.from = camera.project_ray_origin(target)
	ray_query.to = ray_query.from + camera.project_ray_normal(target) * 1000
	var iray = get_world_3d().direct_space_state.intersect_ray(ray_query)
	if (iray.size() > 0):
		move_to_target = iray.position

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

func handle_item():
	attach_item.add_child(GameState.current_item)
	if (GameState.current_item is ItemWeapon):
		anim_attack.animation = ANIM_SWORD_SLASH % GameState.current_item.speed
	if (GameState.current_item.use_area != null):
		GameState.current_item.use_area.connect("body_entered", _on_item_hit)

func unhandle_item():
	if (GameState.current_item.use_area != null):
		GameState.current_item.use_area.disconnect("body_entered", _on_item_hit)
	attach_item.remove_child(GameState.current_item)

func _on_item_hit(node:Node3D):
	if (not action) or (action_hit): return
	action_hit = true
	if (node is EnemyCharacter):
		node.hit(GameState.current_item)
