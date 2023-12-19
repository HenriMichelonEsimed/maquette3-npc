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

@onready var anim_tree:AnimationTree = $AnimationTree
@onready var collision_shape:CollisionShape3D = $CollisionShape3D

var anim_state:AnimationNodeStateMachinePlayback
var label_info:Label
var collision_height:float = 0.0
var hit_points:int
var anim_die_name:String

func _ready():
	hit_points = hit_points_start.roll()
	set_collision_layer_value(Consts.LAYER_ENEMY_CHARACTER, true)
	if (anim_tree != null):
		anim_state = anim_tree["parameters/playback"]
		var anim_die:AnimationNodeAnimation =  anim_tree.get_tree_root().get_node("die")
		anim_die_name = anim_die.animation
	if (collision_shape.shape is CylinderShape3D):
		collision_height = collision_shape.shape.height
	label_info = Label.new()
	label_info.add_theme_font_size_override("font_size", 14)
	label_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label_info)
	
func _to_string():
	return label

func _process(_delta):
	display_info()

func display_info():
	if (hit_points <=0) : return
	label_info.text = "%s\nHP:%d DMG:%s" % [ label, hit_points, damages ]
	var pos = position
	pos.y += collision_height
	label_info.position = get_viewport().get_camera_3d().unproject_position(pos)
	label_info.position.x -= label_info.size.x / 2
	label_info.position.y -= label_info.size.y

func hit(hit_by:ItemWeapon):
	var damage_points = min(hit_by.damage.roll(), hit_points)
	hit_points -= damage_points
	var pos = label_info.position
	pos.x += label_info.size.x / 2
	NotificationManager.hit(self, hit_by, damage_points, pos)
	if (anim_state != null):
		anim_state.travel(ANIM_HIT if hit_points > 0 else ANIM_DIE)
	if (hit_points <= 0):
		label_info.queue_free()
		set_collision_layer_value(Consts.LAYER_ENEMY_CHARACTER, false)

func _on_animation_tree_animation_finished(anim_name:String):
	if (anim_name == anim_die_name):
		process_mode = Node.PROCESS_MODE_DISABLED
