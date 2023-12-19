class_name DicesRoll extends Node

@export var dice_count:int = 1
@export var dice_faces:int = 3
@export var modifier:int = 0

func _to_string():
	var str = "%dd%d" % [ dice_count, dice_faces]
	if (modifier > 0):
		str += "+%d" % modifier
	elif (modifier < 0):
		str += "-%d" % modifier
	return str

func roll():
	var points = modifier
	for i in range(0, dice_count):
		points += (randi() % dice_faces)+1
	if (points < 0):
		points = 0
	return points
