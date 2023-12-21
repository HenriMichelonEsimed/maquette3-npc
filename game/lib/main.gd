extends Node3D

var current_item:CurrentItemManager = CurrentItemManager.new()
var zones:ZonesManager = ZonesManager.new()

func _ready():
	add_child(current_item)
	GameState.player = $Player
	GameState.ui = $MainUI
	TranslationServer.set_locale(GameState.settings.lang)
	NotificationManager.connect("xp_gain", xp_gain)
	if (GameState.current_item != null):
		var item = GameState.current_item
		GameState.current_item = null
		current_item.use(item)
	else:
		current_item.use(Tools.load_item(Item.ItemType.ITEM_WEAPONS, "long_blade_1"))
	GameState.quests.start("main")
	zones.change_zone(self, GameState.player_state.zone_name)
	if (GameState.player_state.position != Vector3.ZERO):
		GameState.player.move(GameState.player_state.position, GameState.player_state.rotation)
	GameState.player_state.hp_max = 20
	GameState.player_state.hp = 20
	GameState.game_started = true

func xp_gain(xp:int):
	GameState.player_state.xp += xp
	GameState.ui.display_xp()
