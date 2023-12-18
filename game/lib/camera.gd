class_name IsometricCamera extends Camera3D

signal view_rotate(view:int)

@export var object_to_follow_path: NodePath

const positions = [ Vector3(-50, 70, 50), Vector3(-50,70,-50), Vector3(50,70,-50),  Vector3(50,70,50) ]
const rotations = [ Vector3(-45, -45, 0), Vector3(-45,-135,0), Vector3(-45,-225,0), Vector3(-45,45,0) ]

@onready var raycast_to_roofs:RayCast3D = $RayCastToRoofs
@onready var camera_pivot:Node3D = $".."

var object_to_follow:Node3D
# isometric view rotation
var _view:int = 0
# camera field of view
var _size:int = 20
# hide roofs for interiors
var last_collider = null
var last_collider_mesh = []
# keyboard actions
var zoom_in = false
var zoom_out = false

func _ready():
	_size = GameState.camera.size
	if (_size == -1):
		_size = 10 #30 / get_viewport().content_scale_factor
	_view = GameState.camera.view
	object_to_follow = get_node(object_to_follow_path)
	camera_pivot.connect("view_moving", _on_camera_pivot_view_moving)
	zoom_view()
	rotate_view()

func _unhandled_input(event):
	if (event is InputEventMouseButton) and (not event.pressed):
		if (event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			if (Input.is_action_pressed("modifier")):
				rotate_view(1)
			else:
				zoom_view(2)
		elif (event.button_index == MOUSE_BUTTON_WHEEL_UP):
			if (Input.is_action_pressed("modifier")):
				rotate_view(-1)
			else:
				zoom_view(-2)

func _unhandled_key_input(event):
	if (event is InputEventKey) and Input.is_action_pressed("modifier"):
		if (event.physical_keycode == KEY_UP):
			if (event.pressed):
				zoom_in = true
			else:
				zoom_in = false
		elif (event.physical_keycode == KEY_DOWN):
			if (event.pressed):
				zoom_out = true
			else:
				zoom_out = false
		elif (event.physical_keycode == KEY_LEFT) and not event.pressed:
			rotate_view(-1)
		elif (event.physical_keycode == KEY_RIGHT) and not event.pressed:
			rotate_view(1)

func _process(_delta):
	camera_pivot.position = object_to_follow.position
	if (zoom_in): 
		zoom_view(-1)
	elif (zoom_out): 
		zoom_view(1)
	#raycast_to_roofs.force_raycast_update()
	if (raycast_to_roofs.is_colliding()):
		var collider:Node3D = raycast_to_roofs.get_collider().get_parent()
		if (collider != null) and (last_collider != collider):
			if (collider.get_groups().is_empty()):
				_set_camera_collider(collider, 0.1)
			else:
				for friend in get_tree().get_nodes_in_group(collider.get_groups()[0]):
					_set_camera_collider(friend, 0.1 if friend == collider else 0.6)
			last_collider = collider
	else:
		_reset_camera_collider()

func zoom_view(delta:int=0):
	_size += delta
	if (_size < 8): 
		_size = 8
	elif (_size > 100):
		_size = 100
	size = _size
	GameState.camera.size = _size

func rotate_view(delta:int=0):
	_view += delta
	if (_view > 3): 
		_view = 0
	elif (_view < 0):
		_view = 3
	position = positions[_view]
	rotation_degrees = rotations[_view]
	GameState.camera.view = _view
	view_rotate.emit(_view)

func move(pos):
	camera_pivot.position = pos

func _on_camera_pivot_view_moving():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass

func _on_player_moving():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass

func _set_camera_collider(collider:Node3D, alpha:float):
	var child_mesh = collider
	var mesh = child_mesh.mesh
	for i in range(0, mesh.get_surface_count()):
		var mat = mesh.surface_get_material(0).duplicate(0)
		if (mat is ShaderMaterial):
				mat.set_shader_parameter("alpha", alpha)
				child_mesh.set_surface_override_material(i, mat)
				last_collider_mesh.push_back(child_mesh)

func _reset_camera_collider():
	if (last_collider != null):
		for mesh in last_collider_mesh:
			for i in range(0, mesh.mesh.get_surface_count()):
				mesh.set_surface_override_material(i, null)
		last_collider = null
		last_collider_mesh.clear()
