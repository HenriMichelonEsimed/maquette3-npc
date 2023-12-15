class_name IsometricCamera extends Camera3D

signal view_rotate(view:int)

@export var camera_pivot_path: NodePath
@export var object_to_follow_path: NodePath

const positions = [ Vector3(-50, 70, 50), Vector3(-50,70,-50), Vector3(50,70,-50),  Vector3(50,70,50) ]
const rotations = [ Vector3(-45, -45, 0), Vector3(-45,-135,0), Vector3(-45,-225,0), Vector3(-45,45,0) ]

var camera_pivot:Node3D
var object_to_follow:Node3D
# isometric view rotation
var _view:int = 0
# camera field of view
var _size:int = 20

func _ready():
	camera_pivot = get_node(camera_pivot_path)
	object_to_follow = get_node(object_to_follow_path)
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

func _process(_delta):
	camera_pivot.position = object_to_follow.position

func zoom_view(delta:int=0):
	_size += delta
	if (_size < 8): 
		_size = 8
	elif (_size > 100):
		_size = 100
	size = _size

func rotate_view(delta:int=0):
	_view += delta
	if (_view > 3): 
		_view = 0
	elif (_view < 0):
		_view = 3
	position = positions[_view]
	rotation_degrees = rotations[_view]
	view_rotate.emit(_view)

func move(pos):
	camera_pivot.position = pos
