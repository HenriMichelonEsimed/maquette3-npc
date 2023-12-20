class_name IsometricCameraPivot extends Node3D

signal view_moving()

@onready var camera:IsometricCamera = $Camera

const player_maxdistance:Vector3 = Vector3(50.0, 0, 50.0)
const mouse_delta:float = 1.0

var current_view:int = 0
var signaled:bool = false
var player_moving:bool = false
var mouse_pressed_position:Vector2 = Vector2.ZERO
var mouse_vector:Vector2

func _ready():
	camera.connect("view_rotate", _on_camera_view_rotate)

func _process(_delta):
	if Input.is_action_pressed("modifier") or player_moving or get_tree().paused: return
	mouse_vector = Vector2.ZERO
	var mouse_pos =  get_viewport().get_mouse_position()
	if (mouse_pos.x >= (get_viewport().size.x - mouse_delta)):
		mouse_vector.x = -1
	elif (mouse_pos.x < mouse_delta):
		mouse_vector.x = 1
	if (mouse_pos.y >= (get_viewport().size.y - mouse_delta)):
		mouse_vector.y = -1
	elif (mouse_pos.y < mouse_delta):
		mouse_vector.y = 1
	
	var new_pos = position
	var modifier = ((100 - GameState.camera.size)+5)/10.0
	if Input.is_action_pressed("view_right") or mouse_vector.x < 0:
		new_pos.x += Player.directions["right"][current_view].x/modifier
		new_pos.z += Player.directions["right"][current_view].z/modifier
	if Input.is_action_pressed("view_left") or mouse_vector.x > 0:
		new_pos.x += Player.directions["left"][current_view].x/modifier
		new_pos.z += Player.directions["left"][current_view].z/modifier
	if Input.is_action_pressed("view_down") or mouse_vector.y < 0:
		new_pos.x += Player.directions["backward"][current_view].x/modifier
		new_pos.z += Player.directions["backward"][current_view].z/modifier
	if Input.is_action_pressed("view_up") or mouse_vector.y > 0:
		new_pos.x += Player.directions["forward"][current_view].x/modifier
		new_pos.z += Player.directions["forward"][current_view].z/modifier
	var player_pos = GameState.player.position
	if (new_pos.x < (player_pos.x - player_maxdistance.x)):
		new_pos.x = player_pos.x - player_maxdistance.x
	if (new_pos.x > (player_pos.x + player_maxdistance.x)):
		new_pos.x = player_pos.x + player_maxdistance.x
	if (new_pos.z < (player_pos.z - player_maxdistance.z)):
		new_pos.z = player_pos.z - player_maxdistance.z
	if (new_pos.z > (player_pos.z + player_maxdistance.z)):
		new_pos.z = player_pos.z + player_maxdistance.z
	if (position != new_pos):
		camera.move(new_pos)
		if (!signaled) :
			view_moving.emit()
			signaled = true

func _on_camera_view_rotate(view:int):
	current_view = view

func _on_player_player_moving():
	signaled = false
	player_moving = true
	
func _on_player_player_stopmoving():
	player_moving = false
