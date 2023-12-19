class_name EnemyCharacter extends CharacterBody3D

const ANIM_IDLE = "idle"
const ANIM_WALK = "walk"
const ANIM_RUN = "run"
const ANIM_ATTACK = "attack"

@export var label:String = "Enemy"

@onready var anim_tree:AnimationTree = $AnimationTree

var anim_state:AnimationNodeStateMachinePlayback

func _ready():
	set_collision_layer_value(Consts.LAYER_ENEMY_CHARACTER, true)
	if (anim_tree != null):
		anim_state = anim_tree["parameters/playback"]

func hit(hit_by:Node3D):
	if (anim_state != null):
		anim_state.travel("hit")
	
