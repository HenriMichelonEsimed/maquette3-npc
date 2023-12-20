class_name EnemyCharacter extends CharacterBody3D

const ANIM_IDLE = "idle"
const ANIM_WALK = "walk"
const ANIM_RUN = "run"
const ANIM_ATTACK = "attack"
const ANIM_DIE = "die"
const ANIM_HIT = "hit"

@export var label:String = "Enemy"
@export var info_distance:float = 10
@export var hear_distance:float = 2
@export var attack_distance:float = 0.9

@onready var weapon:ItemWeapon = $RootNode/Skeleton3D/WeaponAttachement/Weapon
@onready var hit_points_roll:DicesRoll = $HitPoints
@onready var walking_speed_roll:DicesRoll = $WalkingSpeed
@onready var running_speed_roll:DicesRoll = $RunningSpeed
@onready var detection_distance_roll:DicesRoll = $DetectionDistance

@onready var anim_tree:AnimationTree = $AnimationTree
@onready var collision_shape:CollisionShape3D = $CollisionShape3D

var anim_state:AnimationNodeStateMachinePlayback
var label_info:Label
var progress_hp:ProgressBar
var collision_height:float = 0.0
var xp:int
var anim_die_name:String
var in_info_area:bool = false
var timer_attack:Timer
# action animation playing
var attack_cooldown:bool = false
# one hit only allowed during attack cooldown
var hit_allowed:bool = false

var hit_points:int = 100
var walking_speed:float = 0.5
var running_speed:float = 1.0
var detection_distance:float = 6

func _ready():
	weapon.disable()
	hit_points = hit_points_roll.roll()
	walking_speed = walking_speed_roll.roll()
	running_speed = running_speed_roll.roll()
	detection_distance = detection_distance_roll.roll()
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
	GameState.ui.hud.add_child(label_info)
	progress_hp = ProgressBar.new()
	progress_hp.max_value = hit_points
	progress_hp.value = hit_points
	progress_hp.show_percentage = false
	progress_hp.size.x = 50
	progress_hp.modulate = Color.RED
	GameState.ui.hud.add_child(progress_hp)
	timer_attack = Timer.new()
	timer_attack.process_callback = Timer.TIMER_PROCESS_PHYSICS
	timer_attack.one_shot = true
	timer_attack.wait_time = GameMechanics.attack_cooldown(weapon.speed)
	add_child(timer_attack)
	timer_attack.connect("timeout", _on_timer_attack_timeout)
	update_info()
	label_info.text = "%s" % label
	if (weapon.use_area != null):
		weapon.use_area.connect("body_entered", _on_item_hit)

func _process(delta):
	if (hit_points <= 0): return
	var dist = position.distance_to(GameState.player.position)
	in_info_area = dist < info_distance
	update_label_info_position()
	if (dist < detection_distance):
		var detected = (dist < hear_distance)
		if (not detected):
			var forward_vector = -get_transform().basis.z
			var vector_to_player = (GameState.player.position - position).normalized()
			detected = acos(forward_vector.dot(vector_to_player)) <= deg_to_rad(60)
		if (detected):
			velocity = Vector3.ZERO
			# raycast
			look_at(GameState.player.position)
			if (dist > attack_distance):
				velocity = -transform.basis.z * running_speed
				anim_state.travel(ANIM_RUN)
				move_and_slide()
			elif not attack_cooldown:
				anim_state.travel(ANIM_ATTACK)
				timer_attack.start()
				attack_cooldown = true
				hit_allowed = true
			return
	anim_state.travel(ANIM_IDLE)
	if (randf() < 0.1):
		rotate_y(deg_to_rad(randf_range(-10, 10)))

func _to_string():
	return label

func update_info():
	if (label_info == null): return
	progress_hp.value = hit_points
	update_label_info_position()

func update_label_info_position():
	if (label_info == null): return
	label_info.visible = in_info_area and GameState.camera.size < 30
	progress_hp.visible = label_info.visible
	if (label_info.visible):
		var pos:Vector3 = position
		pos.y += collision_height
		var pos2d:Vector2 = get_viewport().get_camera_3d().unproject_position(pos)
		progress_hp.position = pos2d
		progress_hp.position.x -= progress_hp.size.x / 2
		progress_hp.position.y -= progress_hp.size.y/2
		label_info.position = pos2d
		label_info.position.x -= label_info.size.x / 2
		label_info.position.y -= label_info.size.y + progress_hp.size.y
		label_info.add_theme_font_size_override("font_size", 14 - GameState.camera.size / 10)

func hit(hit_by:ItemWeapon):
	var damage_points = min(hit_by.damages_roll.roll(), hit_points)
	hit_points -= damage_points
	update_info()
	look_at(GameState.player.position)
	var pos = label_info.position
	pos.x += label_info.size.x / 2
	velocity = Vector3.ZERO
	NotificationManager.hit(self, hit_by, damage_points, pos)
	if (anim_state != null):
		anim_state.travel(ANIM_HIT if hit_points > 0 else ANIM_DIE)
	if (hit_points <= 0):
		NotificationManager.xp(xp)
		set_collision_layer_value(Consts.LAYER_ENEMY_CHARACTER, false)
		set_collision_layer_value(Consts.LAYER_WORLD, true)
		label_info.queue_free()
		label_info = null
		progress_hp.queue_free()
		in_info_area = false

func _on_timer_attack_timeout():
	attack_cooldown = false

func _on_item_hit(node:Node3D):
	if (hit_allowed):
		hit_allowed = false
		if (node is Player):
			node.hit(weapon)

func _on_input_event(camera, event, position, normal, shape_idx):
	if (event is InputEventMouseButton) and (event.button_index == MOUSE_BUTTON_MIDDLE) and not(event.pressed):
		Tools.load_dialog(self, Tools.DIALOG_ENEMY_INFO, GameState.resume_game).open(self)
