extends Node

var notifications:Array[String] = []

signal new_notification(message:String)
signal new_hit(target:Node3D, weapon:ItemWeapon, damage_points:int, positive:bool)
signal xp_gain(xp:int)
signal use_item(item:Item)
signal unuse_item()

func notif(message:String):
	new_notification.emit(message)
	notifications.push_back(message)

func hit(target:Node3D, weapon:ItemWeapon, damage_points:int, positive:bool=true):
	new_hit.emit(target, weapon, damage_points, positive)

func xp(xp:int):
	xp_gain.emit(xp)

func use(item:Item):
	use_item.emit(item)

func unuse_current_item():
	unuse_item.emit()
