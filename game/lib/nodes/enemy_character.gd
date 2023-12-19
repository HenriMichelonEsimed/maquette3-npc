class_name EnemyCharacter extends CharacterBody3D

const ANIM_IDLE = "idle"
const ANIM_WALK = "walk"
const ANIM_RUN = "run"
const ANIM_ATTACK = "attack"
const ANIM_DIE = "die"
const ANIM_HIT = "hit"

@export var label:String = "Enemy"
@export var damages:DicesRoll 
@export var speed:int = 1
@export var hit_points_start:DicesRoll
@export var walking_speed:float = 0.5
@export var running_speed:float = 1.0
@export var info_distance:float = 10
@export var detection_distance:float = 6
@export var hear_distance:float = 2
@export var min_distance:float = 0.5

@onready var anim_tree:AnimationTree = $AnimationTree
@onready var collision_shape:CollisionShape3D = $CollisionShape3D

var anim_state:AnimationNodeStateMachinePlayback
var label_info:Label
var collision_height:float = 0.0
var hit_points:int
var xp:int
var anim_die_name:String
var in_info_area:bool = false

var detection_mesh:CylinderShape3D
var detection_shape:CollisionShape3D
var detection_area:Area3D

func _ready():
	hit_points = hit_points_start.roll()
	xp = hit_points
	set_collision_layer_value(Consts.LAYER_ENEMY_CHARACTER, true)
	if (anim_tree != null):
		anim_state = anim_tree["parameters/playback"]
		var anim_die:AnimationNodeAnimation =  anim_tree.get_tree_root().get_node("die")
		anim_die_name = anim_die.animation
	if (collision_shape.shape is CylinderShape3D):
		collision_height = collision_shape.shape.height
	label_info = Label.new()
	label_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_info.visible = false
	add_child(label_info)
	detection_mesh = CylinderShape3D.new()
	detection_mesh.radius = detection_distance
	detection_mesh.height = 2
	detection_shape = CollisionShape3D.new()
	detection_shape.shape = detection_mesh
	detection_shape.position.y += detection_mesh.height / 2
	detection_area = Area3D.new()
	detection_area.add_child(detection_shape)
	detection_area.connect("body_entered", _on_detection_aera_body_entered)
	detection_area.connect("body_exited", _on_detection_aera_body_exited)
	detection_area.set_collision_mask_value(Consts.LAYER_PLAYER, true)
	detection_area.set_collision_mask_value(Consts.LAYER_WORLD, false)
	detection_area.set_collision_layer_value(Consts.LAYER_WORLD, false)
	add_child(detection_area)
	update_info()

func _process(delta):
	var dist = position.distance_to(GameState.player.position)
	in_info_area = dist < info_distance
	update_label_info_position()
	if (dist < detection_distance):
		pass
		
	#if (in_detection_area): 
	#	update_label_info_position()
		#if (dist < attack_distance) and (dist > min_distance):
		#	var vector_to_player = global_position.direction_to(GameState.player.global_position)
		#	print( vector_to_player.dot(position.normalized()))
			#var detected = (dist < hear_distance)
			#if (not detected):
			#	var vector_to_player = position.direction_to(GameState.player.position)
			#	detected = vector_to_player.dot(position.normalized()) > 0
			#if (detected):
			#	look_at(GameState.player.position)
			#	velocity = -transform.basis.z * running_speed
			#	anim_state.travel(ANIM_RUN)
			#	move_and_slide()
		#else:
		#	anim_state.travel(ANIM_IDLE)
		#	if (randf() < 0.1):
		#		rotate_y(deg_to_rad(randf_range(-10, 10)))

func _to_string():
	return label

func update_info():
	if (label_info == null): return
	label_info.text = "%s\nHP:%d DMG:%s" % [ label, hit_points, damages ]
	update_label_info_position()

func update_label_info_position():
	if (label_info == null): return
	label_info.visible = in_info_area and GameState.camera.size < 30
	if (label_info.visible):
		var pos = position
		pos.y += collision_height
		label_info.position = get_viewport().get_camera_3d().unproject_position(pos)
		label_info.position.x -= label_info.size.x / 2
		label_info.position.y -= label_info.size.y
		label_info.add_theme_font_size_override("font_size", 14 - GameState.camera.size / 10)

func hit(hit_by:ItemWeapon):
	var damage_points = min(hit_by.damage.roll(), hit_points)
	hit_points -= damage_points
	update_info()
	look_at(GameState.player.position)
	var pos = label_info.position
	pos.x += label_info.size.x / 2
	NotificationManager.hit(self, hit_by, damage_points, pos)
	if (anim_state != null):
		anim_state.travel(ANIM_HIT if hit_points > 0 else ANIM_DIE)
	if (hit_points <= 0):
		NotificationManager.xp(xp)
		set_collision_layer_value(Consts.LAYER_ENEMY_CHARACTER, false)
		set_collision_layer_value(Consts.LAYER_WORLD, true)
		detection_area.disconnect("body_entered", _on_detection_aera_body_entered)
		detection_area.disconnect("body_exited", _on_detection_aera_body_exited)
		detection_shape.queue_free()
		detection_area.queue_free()
		label_info.queue_free()
		label_info = null
		in_info_area = false

func _on_detection_aera_body_entered(node:Node):
	#in_detection_area = true
	#display_info()
	pass

func _on_detection_aera_body_exited(node:Node):
	#in_detection_area = false
	#update_label_info_position()
	pass
