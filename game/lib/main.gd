extends Node3D

@onready var player:Player = $Player
@onready var ui:MainUI = $MainUI
@onready var audio:AudioStreamPlayer3D = $AudioStreamPlayer

#@onready var sound_drowning_man:AudioStream = load("res://assets/audio/water/drowning_man.mp3")
#@onready var sound_drowning_female:AudioStream = load("res://assets/audio/water/drowning_female.mp3")

var _previous_zone:Zone
var _last_spawnpoint:String
var _previous_item:Item

func _ready():
	GameState.player = player
	GameState.ui = ui
	#player.connect("update_oxygen", update_oxygen)
	TranslationServer.set_locale(GameState.settings.lang)
	NotificationManager.connect("xp_gain", xp_gain)
	if (GameState.current_item != null):
		var item = GameState.current_item
		GameState.current_item = null
		item_use(item)
	else:
		item_use(Tools.load_item(Item.ItemType.ITEM_WEAPONS, "long_blade_1"))
	GameState.quests.start("main")
	_change_zone(GameState.player_state.zone_name)
	if (GameState.player_state.position != Vector3.ZERO):
		player.move(GameState.player_state.position, GameState.player_state.rotation)
	GameState.game_started = true

func _unhandled_input(event):
	if (Input.is_action_just_pressed("use_previous")):
		item_use(_previous_item)
	elif  Input.is_action_just_released("unuse"):
		item_unuse()

func _change_zone(zone_name:String, spawnpoint_key:String="default"):
	if (GameState.current_zone != null) and (zone_name == GameState.current_zone.zone_name): 
		return
	var new_zone:Zone
	if (_previous_zone != null) and (_previous_zone.zone_name == zone_name):
		new_zone = _previous_zone
	else:
		if (_previous_zone != null): 
			_previous_zone.queue_free()
		new_zone = Tools.load_zone(zone_name).instantiate()
	new_zone.zone_name = zone_name
	if (GameState.current_zone != null): 
		GameState.player.interactions.disconnect("item_collected", GameState.current_zone.on_item_collected)
		GameState.current_zone.disconnect("change_zone", _change_zone)
		for node in GameState.current_zone.find_children("*", "Storage", true, true):
			node.disconnect("open", _on_storage_open)
		for node in GameState.current_zone.find_children("*", "Usable", true, true):
			node.disconnect("unlock", _on_usable_unlock)
		for node in GameState.current_zone.find_children("*", "InteractiveCharacter", true, true):
			node.disconnect("trade", GameState.ui.npc_trade)
			node.disconnect("talk", GameState.ui.npc_talk)
			node.disconnect("end_talk", GameState.ui.npc_end_talk)
		remove_child(GameState.current_zone)
	_previous_zone = GameState.current_zone
	GameState.current_zone = new_zone
	GameState.player_state.zone_name = zone_name
	GameState.current_zone.connect("change_zone", _change_zone)
	GameState.player.interactions.connect("item_collected", GameState.current_zone.on_item_collected)
	add_child(GameState.current_zone)
	_spawn_player(spawnpoint_key)
	for node in GameState.current_zone.find_children("*", "Storage", true, true):
		node.connect("open", _on_storage_open)
	for node in GameState.current_zone.find_children("*", "Usable", true, true):
		node.connect("unlock", _on_usable_unlock)
	for node in GameState.current_zone.find_children("*", "InteractiveCharacter", true, true):
		node.connect("trade", GameState.ui.npc_trade)
		node.connect("talk", GameState.ui.npc_talk)
		node.connect("end_talk", GameState.ui.npc_end_talk)
	GameState.current_zone.visible = true
	GameState.current_zone.zone_post_start()

func _spawn_player(spawnpoint_key:String):
	for node in GameState.current_zone.find_children("*", "SpawnPoint", false, true):
		if (node.key == spawnpoint_key):
			player.move(node.global_position, node.global_rotation)
			node.spawn()
			break
	_last_spawnpoint = spawnpoint_key

func item_use(item:Item):
	item_unuse()
	GameState.current_item = item.dup()
	if (item is ItemMultiple):
		GameState.current_item.quantity = 1
	GameState.inventory.remove(GameState.current_item)
	ui.panel_item.use()
	player.handle_item()
	GameState.current_item.use()

func item_unuse():
	if (GameState.current_item == null): return
	player.unhandle_item()
	ui.panel_item.unuse()
	GameState.current_item.unuse()
	_previous_item = GameState.current_item.dup()
	GameState.inventory.add(_previous_item)
	GameState.current_item = null

func _on_storage_open(node:Storage):
	GameState.ui.storage_open(node, _on_storage_close)

func _on_storage_close(node:Storage):
	node.use()

func _on_usable_unlock(success:bool):
	if (success):
		GameState.item_unuse()
	elif (GameState.current_item != null):
		NotificationManager.notif(tr("Nothing happens with '%s'") % tr(str(GameState.current_item)))

func xp_gain(xp:int):
	GameState.player_state.xp += xp
	GameState.ui.display_xp()

#func update_oxygen():
#	if (GameState.oxygen <= 0):
#		audio.stream = sound_drowning_female if GameState.player_state.sex else sound_drowning_man
#		audio.play()
#		GameState.pause_game()
#		Tools.load_screen(self, Tools.SCREEN_GAMEOVER).open()

