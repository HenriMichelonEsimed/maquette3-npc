class_name ItemWeapon extends ItemUnique

@onready var damages_roll:DicesRoll = $Damages
@onready var speed_roll:DicesRoll = $Speed

var speed:int = 1

func _init():
	type = ItemType.ITEM_WEAPONS

func _ready():
	super._ready()
	speed = speed_roll.roll()
