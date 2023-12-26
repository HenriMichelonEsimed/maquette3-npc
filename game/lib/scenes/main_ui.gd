class_name MainUI extends Control

@export var player:Player
@export var camera_pivot:IsometricCameraPivot
@export var  highlighter_material:Material

@onready var label_saving:Label = $LabelSaving
@onready var time_saving:Timer = $LabelSaving/Timer
@onready var label_info:Label = $HUD/LabelInfo
@onready var focused_button:Button = $Menu/MainMenu/ButtonInventory
@onready var label_notif:Label = $HUD/LabelNotification
@onready var timer_notif:Timer = $HUD/LabelNotification/Timer
@onready var icon_menu_open = $HUD/MenuOpen
@onready var icon_menu_close = $MenuClose
@onready var icon_use = $HUD/LabelInfo/Icon
@onready var button_iventory = $Menu/MainMenu/ButtonInventory
@onready var button_save = $Menu/SubMenu/ButtonSave
@onready var panel_item = $HUD/PanelTool
@onready var panel_oxygen = $HUD/Oxygen
@onready var value_oxygen = $HUD/Oxygen
@onready var compass = $HUD/Compass
@onready var menu = $Menu
@onready var hud = $HUD
@onready var blur = $Blur
@onready var hp = $HUD/HP
@onready var xp = $HUD/XP
@onready var endurance = $HUD/Endurance

const compass_rotation = [ 0.0, -90.0, -180.0, -270.0 ]

var _displayed_node:Node
var _restart_timer_notif:bool = false
var _talk_screen:Dialog
var _trade_screen:Dialog
var _highlighted_mesh:MeshInstance3D
var _highlighted_mat:Material
var _notifs = {}
var _last_enemy_info:int
var _enemies_info:Array[Node3D]

func _ready():
	blur.visible = false
	label_saving.visible = false
	label_info.visible = false
	menu.visible = false
	label_notif.visible = false
	panel_item.visible = false
	icon_menu_close.visible = false
	panel_oxygen.visible = false
	NotificationManager.connect("new_notification",display_notification)
	NotificationManager.connect("new_node_notification",display_node_notification)
	NotificationManager.connect("new_hit", display_new_hit)
	NotificationManager.connect("xp_gain", display_xp_gain)
	GameState.connect("saving_start", _on_saving_start)
	GameState.connect("saving_end", _on_saving_end)
	camera_pivot.camera.connect("view_rotate", _on_camera_view_rotate)
	player.interactions.connect("display_info", _on_display_info)
	player.interactions.connect("hide_info", hide_info)
	player.connect("endurance_change", endurance_change)
	#player.connect("update_oxygen", update_oxygen)
	Input.connect("joy_connection_changed", _on_joypad_connection_changed)
	display_xp()
	set_shortcuts()
	_on_camera_view_rotate(GameState.camera.view)
	hp.max_value = GameState.player_state.hp_max
	hp.value = GameState.player_state.hp
	endurance_change()

func set_shortcuts():
	panel_item.set_shortcuts()
	Tools.set_shortcut_icon(icon_use, Tools.SHORTCUT_USE)
	Tools.set_shortcut_icon(icon_menu_open, Tools.SHORTCUT_MENU)
	Tools.set_shortcut_icon(icon_menu_close, Tools.SHORTCUT_CANCEL)
	Tools.set_shortcut_icon(button_iventory, Tools.SHORTCUT_INVENTORY)

func _on_joypad_connection_changed(_id, _connected):
	set_shortcuts()
	Dialog.refresh_shortcuts()

func _input(event):
	if (not Dialog.dialogs_stack.is_empty()) or Dialog.ignore_input(): return
	if ((event is InputEventJoypadButton) or (event is InputEventKey)) and (not event.pressed):
		if (Input.is_action_just_released("menu") and not menu.visible):
			menu_open()
		elif (Input.is_action_just_released("cancel") and menu.visible):
			menu_close()
		elif (Input.is_action_just_released("quit")):
			_on_save_before_quit_confirm(true)
		elif Input.is_action_just_released("inventory"):
			inventory_open()
		elif Input.is_action_just_released("info"):
			display_enemy_info()
			

func _process(delta):
	hp.value = GameState.player_state.hp

func _physics_process(delta):
	for node in _notifs.keys():
		for label in _notifs[node]:
			var count = label.get_meta("count")
			count -= 1
			if (count == 0):
				_notifs[node].erase(label)
				label.queue_free()
			else:
				label.set_meta("count", count)
				label.position.y -= 2
		if _notifs[node].is_empty():
			_notifs.erase(node)

func _on_camera_view_rotate(view:int):
	compass.rotation_degrees = compass_rotation[view]

func pause_game():
	if (not timer_notif.is_stopped()):
		timer_notif.stop()
		_restart_timer_notif = true
	hud.visible = false
	blur.visible = true

func resume_game(_dummy=null):
	hud.visible = true
	blur.visible = false
	if( _restart_timer_notif):
		timer_notif.start()
		_restart_timer_notif = false

func menu_open():
	GameState.pause_game()
	menu.visible = true
	icon_menu_close.visible = true
	focused_button.grab_focus()

func menu_close(_dummy=null):
	menu.visible = false
	icon_menu_close.visible = false
	GameState.resume_game()
	
func npc_talk(_char:InteractiveCharacter, phrase:String, answers:Array):
	if (_talk_screen != null and _talk_screen.trading): return
	if (_talk_screen == null):
		_talk_screen = Tools.load_dialog(self, Tools.SCREEN_NPC_TALK)
		_talk_screen.open(_char)
	_talk_screen.talk(phrase, answers)

func npc_end_talk():
	if (_talk_screen != null):
		_talk_screen.close()
		_talk_screen = null

func npc_trade(_char:InteractiveCharacter):
	if (_talk_screen.trading): return
	_talk_screen.trading = true
	_trade_screen = Tools.load_dialog(self, Tools.SCREEN_NPC_TRADE)
	_trade_screen.open(_char, npc_trade_end)

func npc_trade_end():
	_talk_screen.trading = false
	_talk_screen.player_text_list.grab_focus()

func storage_open(node:Storage, on_storage_close:Callable):
	var dlg = Tools.load_dialog(self, Tools.DIALOG_TRANSFERT_ITEMS, resume_game)
	dlg.open(node, on_storage_close)

func inventory_open():
	var dlg = Tools.load_dialog(self, Tools.SCREEN_INVENTORY, menu_close)
	dlg.open()

func load_savegame_open():
	var dlg = Tools.load_dialog(self, Tools.DIALOG_LOAD_SAVEGAME, menu_close)
	dlg.open(_on_load_savegame)

func settings_open():
	var dlg = Tools.load_dialog(self, Tools.DIALOG_SETTINGS, menu_close)
	dlg.open()

func savegame_open():
	var dlg = Tools.load_dialog(self, Tools.DIALOG_INPUT, func():button_save.grab_focus())
	dlg.open("Save game", StateSaver.get_last_savegame(), _on_savegame_input)

func display_keymaps():
	Tools.load_dialog(self, Tools.DIALOG_CONTROLLER, menu_close).open()

func display_notification(message:String):
	timer_notif.stop()
	label_notif.text = message
	label_notif.visible = true
	timer_notif.start()

func display_new_hit(target:Node3D, weapons:ItemWeapon, damage_points:int, positive:bool):
	display_moving_notification(target, "%d" % damage_points, 100, Consts.COLOR_POSITIVE if positive else  Consts.COLOR_NEGATIVE )
	
func display_xp_gain(xp:int):
	display_moving_notification(GameState.player, tr("+%d XP") % xp, 150)

func display_xp():
	xp.max_value = GameState.player_state.xp_next_level
	xp.value = GameState.player_state.xp

func display_node_notification(node:Node3D, message:String):
	display_moving_notification(node, message, 100)

func display_moving_notification(node:Node3D, text:String, cooldown:int, color=null):
	var label = Label.new()
	label.text = text
	if (color != null):
		label.add_theme_color_override("font_color", color)
	label.set_meta("count", cooldown)
	var pos3d = node.position
	pos3d.y += node.height
	var pos = camera_pivot.camera.unproject_position(pos3d)
	label.position = pos
	label.position.y -= label.size.y
	label.position.x -= label.size.x / 2
	if (not _notifs.has(node)):
		_notifs[node] = []
	elif (not _notifs[node].is_empty()):
		var last = _notifs[node].back()
		var bottom = last.position.y + last.size.y
		if (label.position.y < bottom):
			label.position.y = bottom 
	_notifs[node].push_back(label)
	hud.add_child(label)

func _on_load_savegame(savegame:String):
	menu.visible = false
	GameState.load_game(savegame)
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")
	
func _on_savegame_input(savegame):
	if (savegame != null):
		if (StateSaver.savegame_exists(savegame)):
			GameState.savegame_name = savegame
			var dlg = Tools.load_dialog(self, Tools.DIALOG_CONFIRM, menu_close)
			dlg.open("Save game", "Overwrite existing save?", _on_savegame_confirm)
		else:
			GameState.save_game(savegame)
			menu_close()

func _on_savegame_confirm(overwrite:bool):
	if (overwrite):
		GameState.save_game(GameState.savegame_name)
		menu_close()

func _on_saving_start():
	label_saving.visible = true

func _on_saving_end():
	time_saving.start()

func _on_saving_timer_timeout():
	label_saving.visible = false

func update_oxygen():
	if (GameState.oxygen < 100.0):
		panel_oxygen.visible = true
		value_oxygen.value = GameState.oxygen
	else:
		panel_oxygen.visible = false

func _on_display_info(node:Node3D):
	_displayed_node = node
	var label:String = tr(str(_displayed_node))
	if (label.is_empty()): 
		label = str(node)
	label_info.position =  get_viewport().get_camera_3d().unproject_position(node.global_position)
	label_info.text = label
	label_info.visible = true
	var meshes = node.find_children("", "MeshInstance3D")
	if (not meshes.is_empty()):
		var mesh = meshes[0]
		var mat = mesh.get_surface_override_material (0)
		if (mat != null):
			_highlighted_mat = mat
			_highlighted_mesh = mesh
			mat = mat.duplicate(0)
			mat.next_pass = highlighter_material
			mesh.set_surface_override_material(0, mat)

func hide_info():
	label_info.visible = false
	label_info.text = ''
	if (_highlighted_mesh != null):
		_highlighted_mesh.set_surface_override_material(0, _highlighted_mat)
		_highlighted_mesh = null

func _on_button_quit_pressed():
	var dlg = Tools.load_dialog(self, Tools.DIALOG_CONFIRM, menu_close)
	dlg.open("Save ?", "Save game before exiting ?", _on_save_before_quit_confirm)

func _on_save_before_quit_confirm(save:bool):
	if (save): 
		GameState.save_game()
	#get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	get_tree().quit()

func _on_timer_notif_timeout():
	label_notif.visible = false

func _on_button_pressed():
	get_tree().quit()

func endurance_change():
	endurance.max_value = GameState.player_state.endurance_max
	endurance.value = GameState.player_state.endurance

func display_enemy_info(next:bool=false):
	if (not next):
		_enemies_info = []
		for enemy:EnemyCharacter in get_parent().find_children("", "EnemyCharacter", true, false):
			if (enemy.player_in_info_area):
				_enemies_info.push_back(enemy)
		if (_enemies_info.is_empty()): return
		var nearest = Tools.get_nearest_node(GameState.player, _enemies_info)
		_last_enemy_info = _enemies_info.find(nearest)
	else:
		_last_enemy_info += 1
		if (_last_enemy_info >= _enemies_info.size()):
			_last_enemy_info = 0
	Tools.load_dialog(self, Tools.DIALOG_ENEMY_INFO, GameState.resume_game).open(_enemies_info[_last_enemy_info], true)
