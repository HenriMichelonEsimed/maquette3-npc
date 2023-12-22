class_name EnemyCharacter extends CharacterBody3D

const ANIM_IDLE = "idle"
const ANIM_WALK = "walk"
const ANIM_RUN = "run"
const ANIM_ATTACK = "attack"
const ANIM_DIE = "die"
const ANIM_HIT = "hit"

enum States {
	STARTING,
	DEAD,
	PLAYER_DEAD,
	IDLE,
	MOVE_TO_POSITION,
	MOVE_TO_PLAYER,
	ATTACK,
}
static var STATES_NAMES = [
	"STARTING",
	"DEAD",
	"PLAYER_DEAD",
	"IDLE",
	"MOVE_TO_POSITION",
	"MOVE_TO_PLAYER",
	"ATTACK"
]

enum StatesResult {
	STOP,
	CONTINUE,
}


@export var label:String = "Enemy"
@export var hear_distance:float = 5
@export var attack_distance:float = 0.9
@export var height:float = 0.0

@onready var weapon:ItemWeapon = $RootNode/Skeleton3D/WeaponAttachement/Weapon
@onready var hit_points_roll:DicesRoll = $HitPoints
@onready var walking_speed_roll:DicesRoll = $WalkingSpeed
@onready var running_speed_roll:DicesRoll = $RunningSpeed
@onready var detection_distance_roll:DicesRoll = $DetectionDistance
@onready var help_distance_roll:DicesRoll = $HelpDistance

@onready var collision_shape:CollisionShape3D = $CollisionShape3D
@onready var anim:AnimationPlayer = $AnimationPlayer

var label_info:Label
var progress_hp:ProgressBar
var raycast_detection:RayCast3D

var in_info_area:bool = false
var timer_attack:Timer
var timer_start_animation:Timer
# action animation playing
var attack_cooldown:bool = false
# one hit only allowed during attack cooldown
var hit_allowed:bool = false

var xp:int
var hit_points:int = 100
var walking_speed:float = 0.5
var running_speed:float = 1.0
var detection_distance:float = 10
var info_distance:float = 25
var help_distance:float = 15
var help_called:bool = false

var attack_animation_scale:float

var state:States = States.STARTING
var idle_rotation_tween:Tween
var player_distance:float = 0.0
var detected_position:Vector3 = Vector3.ZERO
var player_detected:bool = false
# last position when moving to position
var previous_position:Vector3 = Vector3.ZERO
# we heard a fight
var heard_hit:bool = false
# we heard a call for help
var heard_help_call:bool = false
var idle_detection_angle:float = 60
var current_detection_angle:float = idle_detection_angle

func _ready():
	weapon.disable()
	weapon.use_area.set_collision_mask_value(Consts.LAYER_PLAYER, true)
	weapon.use_area.set_collision_mask_value(Consts.LAYER_ENEMY_CHARACTER, false)
	connect("input_event", _on_input_event)
	hit_points = hit_points_roll.roll()
	walking_speed = walking_speed_roll.roll()
	running_speed = running_speed_roll.roll()
	detection_distance = detection_distance_roll.roll()
	help_distance = help_distance_roll.roll()
	xp = hit_points
	set_collision_mask_value(Consts.LAYER_ROOFS, true)
	set_collision_layer_value(Consts.LAYER_ENEMY_CHARACTER, true)
	attack_animation_scale = GameMechanics.anim_scale(weapon.speed)
	if (height == 0) and (collision_shape.shape is CylinderShape3D):
		height = collision_shape.shape.height
	raycast_detection = RayCast3D.new()
	raycast_detection.position.y += height
	raycast_detection.target_position = Vector3(0.0, 0.0, -detection_distance)
	raycast_detection.set_collision_mask_value(Consts.LAYER_ROOFS, true)
	raycast_detection.set_collision_mask_value(Consts.LAYER_ENEMY_CHARACTER, true)
	add_child(raycast_detection)
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
	NotificationManager.connect("new_hit", _on_new_hit)
	NotificationManager.connect("node_call_for_help", _on_call_for_help)

func _physics_process(delta):
	match (state):
		States.STARTING:
			action_start()
		States.PLAYER_DEAD:
			action_idle()
		States.IDLE:
			if (condition_preconditions() == StatesResult.STOP): return
			setvar_player_detected()
			if (condition_player_detected_and_not_hidden() == StatesResult.STOP): return
			if (condition_heard_hit() == StatesResult.STOP): return
			if (condition_heard_help_call() == StatesResult.STOP): return
			action_idle()
		States.MOVE_TO_PLAYER:
			if (condition_preconditions() == StatesResult.STOP): return
			setvar_player_detected()
			if (condition_player_still_detected() == StatesResult.STOP): return
			if (condition_player_hidden() == StatesResult.STOP): return
			if (condition_attack_player() == StatesResult.STOP): return
			action_move_to_player()
		States.MOVE_TO_POSITION:
			if (condition_preconditions() == StatesResult.STOP): return
			setvar_player_detected()
			if (condition_attack_player() == StatesResult.STOP): return
			if (condition_heard_hit() == StatesResult.STOP): return
			if (condition_heard_help_call() == StatesResult.STOP): return
			if (condition_have_detected_position() == StatesResult.STOP): return
			if (condition_continue_to_position() == StatesResult.STOP): return
			if (condition_blocked() == StatesResult.STOP): return
			action_move_to_detected_position()
		States.ATTACK:
			if (condition_preconditions() == StatesResult.STOP): return
			setvar_player_detected()
			if (condition_player_still_detected() == StatesResult.STOP): return
			if (condition_player_hidden() == StatesResult.STOP): return
			if (condition_player_in_attack_range() == StatesResult.STOP): return
			if (condition_can_attack() == StatesResult.STOP): return
			action_attack_player()
		_:
			pass

func change_state(new_state:States, from:String) -> StatesResult:
	print("%s %s (%s) from %s " % [name, STATES_NAMES[new_state], from, STATES_NAMES[state]])
	state = new_state
	return StatesResult.STOP

func condition_preconditions() -> StatesResult:
	if (condition_death() == StatesResult.STOP): return StatesResult.STOP
	if (condition_player_dead() == StatesResult.STOP): return StatesResult.STOP
	setvar_player_distance()
	action_update_label()
	return StatesResult.CONTINUE

func setvar_player_distance():
	player_distance = position.distance_to(GameState.player.position)

func condition_death() -> StatesResult:
	if (hit_points <= 0):
		NotificationManager.xp(xp)
		label_info.queue_free()
		progress_hp.queue_free()
		raycast_detection.queue_free()
		weapon.queue_free()
		$CollisionShape3D.queue_free()
		NotificationManager.disconnect("new_hit", _on_new_hit)
		label_info = null
		in_info_area = false
		return change_state(States.DEAD, "death")
	return StatesResult.CONTINUE

func condition_player_dead() -> StatesResult:
	if (GameState.player_state.hp <= 0):
		return change_state(States.PLAYER_DEAD, "player_dead")
	return StatesResult.CONTINUE

func action_start():
	anim.play(ANIM_IDLE)
	anim.seek(randf()*10.0)
	change_state(States.IDLE, "start")

func condition_attack_player() -> StatesResult:
	if (player_distance <= attack_distance):
		if (not attack_cooldown):
			_stop_idle_rotation()
			return change_state(States.ATTACK, "attack_player")
	return StatesResult.CONTINUE

func condition_player_in_attack_range() -> StatesResult:
	if (player_distance <= attack_distance):
		return StatesResult.CONTINUE
	return change_state(States.MOVE_TO_PLAYER, "player_in_attack_range")

func condition_can_attack() -> StatesResult:
	if (attack_cooldown):
		return StatesResult.STOP
	return StatesResult.CONTINUE

func action_attack_player() -> StatesResult:
	print("%s attack player" % name)
	anim.play(ANIM_ATTACK, 0.2, attack_animation_scale)
	timer_attack.start()
	attack_cooldown = true
	hit_allowed = true
	return StatesResult.CONTINUE

func action_move_to_player() -> StatesResult:
	if (anim.current_animation != ANIM_RUN):
		_stop_idle_rotation()
		print("%s move to player from %s" % [name, anim.current_animation])
		anim.play(ANIM_RUN, 0.2)
	detected_position = GameState.player.position
	look_at(detected_position)
	velocity = -transform.basis.z * running_speed
	previous_position = position
	move_and_slide()
	return StatesResult.CONTINUE

func setvar_player_detected():
	player_detected = (player_distance < hear_distance)
	if (not player_detected) and (player_distance < detection_distance):
		var forward_vector = -transform.basis.z
		var vector_to_player = (GameState.player.position - position).normalized()
		player_detected = acos(forward_vector.dot(vector_to_player)) <= deg_to_rad(current_detection_angle)

func condition_player_hidden():
	raycast_detection.target_position = Vector3(0.0, 0.0, -detection_distance)
	if (raycast_detection.is_colliding() and not(raycast_detection.get_collider() is Player)):
		current_detection_angle = 90
		previous_position = Vector3.ZERO
		return change_state(States.MOVE_TO_POSITION, "player_hidden")
	return StatesResult.CONTINUE

func condition_player_still_detected() -> StatesResult:
	if (player_detected):
		return StatesResult.CONTINUE
	return change_state(States.IDLE, "player_detected")

func condition_player_detected_and_not_hidden() -> StatesResult:
	if (player_detected):
		var local = raycast_detection.to_local(GameState.player.position)
		raycast_detection.target_position = local
		if raycast_detection.is_colliding() and (raycast_detection.get_collider() is Player):
			current_detection_angle = idle_detection_angle
			return change_state(States.MOVE_TO_PLAYER, "player_detected_and_not_hidden")
	return StatesResult.CONTINUE
	
func condition_player_detected() -> StatesResult:
	if (player_detected):
		return change_state(States.MOVE_TO_PLAYER, "condition_player_detected")
	return StatesResult.CONTINUE

func action_update_label() -> StatesResult:
	in_info_area = player_distance < info_distance
	update_label_info_position()
	return StatesResult.CONTINUE
	
func action_idle():
	if (anim.current_animation != ANIM_IDLE):
		print("%s idle from %s" % [name, anim.current_animation])
		anim.play(ANIM_IDLE, 0.5)
	_idle_rotation()

func condition_heard_hit() -> StatesResult:
	if (heard_hit):
		heard_hit = false
		previous_position = Vector3.ZERO
		return change_state(States.MOVE_TO_POSITION, "heard_hit")
	return StatesResult.CONTINUE

func condition_heard_help_call() -> StatesResult:
	if (heard_help_call):
		heard_help_call = false
		previous_position = Vector3.ZERO
		return change_state(States.MOVE_TO_POSITION, "heard_help_call")
	return StatesResult.CONTINUE
	
func condition_have_detected_position() -> StatesResult:
	if (detected_position == Vector3.ZERO):
		return change_state(States.IDLE, "have_detected_position")
	return StatesResult.CONTINUE

func condition_continue_to_position() -> StatesResult:
	if (position.distance_to(detected_position) < 0.1):
		detected_position = Vector3.ZERO
		return change_state(States.IDLE, "continue_to_position")
	return StatesResult.CONTINUE

func condition_blocked() -> StatesResult:
	if (position.distance_to(previous_position) < 0.01):
		detected_position = Vector3.ZERO
		return change_state(States.IDLE, "blocked")
	return StatesResult.CONTINUE

func action_move_to_detected_position():
	if (anim.current_animation != ANIM_RUN):
		_stop_idle_rotation()
		print("%s move to position from %s" % [name, anim.current_animation])
		anim.play(ANIM_RUN, 0.2)
	look_at(detected_position)
	velocity = -transform.basis.z * running_speed
	previous_position = position
	move_and_slide()

func _to_string():
	return label

func _idle_rotation():
	if ((idle_rotation_tween == null) or (not idle_rotation_tween.is_valid())) and (randf() < 0.1):
		var angle = randf_range(-45, 45)
		idle_rotation_tween = get_tree().create_tween()
		idle_rotation_tween.tween_property(
			self, # target
			"rotation_degrees:y", # target property
			rotation_degrees.y+angle, # end value
			10 # animation time
		)

func _stop_idle_rotation():
	if (idle_rotation_tween != null) and (idle_rotation_tween.is_valid()):
		idle_rotation_tween.kill()

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
		pos.y += height
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
	NotificationManager.hit(self, hit_by, damage_points)
	if (hit_points < (progress_hp.max_value * 0.25)) and (not help_called) and (randf() < 0.25):
		help_called = true
		NotificationManager.call_for_help(self)
	anim.play(ANIM_HIT if hit_points > 0 else ANIM_DIE)

func _on_new_hit(target:Node3D, weapon:ItemWeapon, damage_points:int, positive:bool):
	if positive and (target != self) and (position.distance_to(target.position) < detection_distance):
		if (randf() < 0.2):
			detected_position = target.position
			heard_hit = true

func _on_call_for_help(sender:Node3D):
	if (sender is EnemyCharacter) and (sender != self) and (position.distance_to(sender.position) < (detection_distance * 2.0)):
		if (randf() < 0.2):
			detected_position = sender.position
			heard_help_call = true

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

func _on_animation_tree_animation_finished(anim_name):
	if (anim_name == "undead/react_death_backward_1"):
		$AnimationPlayer.queue_free()
		process_mode = Node.PROCESS_MODE_DISABLED
