extends Node

var notifications:Array[String] = []

signal new_notification(message:String)
signal new_hit(enemy:EnemyCharacter, weapon:ItemWeapon, damage_points:int, label_info_position:Vector2)
signal xp_gain(xp:int)

func notif(message:String):
	new_notification.emit(message)
	notifications.push_back(message)

func hit(enemy:EnemyCharacter, weapon:ItemWeapon, damage_points:int, label_info_position:Vector2):
	new_hit.emit(enemy, weapon, damage_points, label_info_position)

func xp(xp:int):
	xp_gain.emit(xp)
