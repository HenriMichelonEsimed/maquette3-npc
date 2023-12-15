extends Node

var notifications:Array[String] = []

signal new_notification(message:String)

func notif(message:String):
	new_notification.emit(message)
	notifications.push_back(message)
