class_name ItemWeapon extends ItemUnique

@export var damage:DicesRoll
@export var speed:int = 1

func _init():
	type = ItemType.ITEM_WEAPONS
