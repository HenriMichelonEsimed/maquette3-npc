extends Node3D

@onready var player:Player = $Player
@onready var ui:MainUI = $MainUI
@onready var audio:AudioStreamPlayer3D = $AudioStreamPlayer

#@onready var sound_drowning_man:AudioStream = load("res://assets/audio/water/drowning_man.mp3")
#@onready var sound_drowning_female:AudioStream = load("res://assets/audio/water/drowning_female.mp3")

var _previous_zone:Zone
var _last_spawnpoint:String

func _ready():
	GameState.prepare_game(true)
	GameState.load_game()
	GameState.player = player
	GameState.ui = ui
	NotificationManager.connect("new_notification", GameState.ui.display_notification)
	#player.connect("update_oxygen", update_oxygen)
	TranslationServer.set_locale(GameState.settings.lang)
	if (GameState.current_item != null):
		var item = GameState.current_item
		GameState.current_item = null
		GameState.item_use(item)
	GameState.quests.start("main")
	_change_zone(GameState.player_state.zone_name)
	if (GameState.player_state.position != Vector3.ZERO):
		player.move(GameState.player_state.position, GameState.player_state.rotation)
	GameState.game_started = true

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

func _on_new_message():
	ui.on_message()
	NotificationManager.notif("You have unread messages !")

func _on_storage_open(node:Storage):
	GameState.ui.storage_open(node, _on_storage_close)

func _on_storage_close(node:Storage):
	node.use()

func _on_usable_unlock(success:bool):
	if (success):
		GameState.item_unuse()
	elif (GameState.current_item != null):
		NotificationManager.notif(tr("Nothing happens with '%s'") % tr(str(GameState.current_item)))

#func update_oxygen():
#	if (GameState.oxygen <= 0):
#		audio.stream = sound_drowning_female if GameState.player_state.sex else sound_drowning_man
#		audio.play()
#		GameState.pause_game()
#		Tools.load_screen(self, Tools.SCREEN_GAMEOVER).open()

var last_collider = null
var last_collider_mesh = []
@onready var rayCast = $CameraPivot/Camera/RayCast
func _process(delta):
	rayCast.force_raycast_update()
	if (rayCast.is_colliding()):
		var collider:Node3D = rayCast.get_collider().get_parent()
		_reset_camera_collider()
		if (collider != null) and collider.is_in_group("roof") and (last_collider != collider):
			_set_camera_collider(collider)
			last_collider = collider

func _set_camera_collider(collider):
	var child_mesh = collider
	var mesh = child_mesh.mesh
	for i in range(0, mesh.get_surface_count()):
		var mat = mesh.surface_get_material(i).duplicate(0)
		if (mat is StandardMaterial3D):
			mat.albedo_color.a = 0.5
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			child_mesh.set_surface_override_material(i, mat)
			last_collider_mesh.push_back(child_mesh)

func _reset_camera_collider():
	if (last_collider != null):
		for mesh in last_collider_mesh:
			for i in range(0, mesh.mesh.get_surface_count()):
				mesh.set_surface_override_material(i, null)
		last_collider = null
		last_collider_mesh.clear()
