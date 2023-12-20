class_name PlayerState extends State

#var zone_name:String = "exteriors/EXT1/level_1"
var zone_name:String = "start/level_0/level_0"
var position:Vector3 = Vector3.ZERO
var rotation:Vector3 = Vector3.ZERO
var current_item_type:Item.ItemType = Item.ItemType.ITEM_UNKNOWN
var current_item_key:String = ""
var nickname:String = "Player"
var sex:bool = true
var char:String = "player_1"
var xp:int = 0
var hp:int = 20
var hp_max:int = 20

func _init():
	super("player")
