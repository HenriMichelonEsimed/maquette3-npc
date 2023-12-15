class_name ItemsTransfertDialog extends Dialog

signal item_collected(item:Item, quantity:int)
signal item_dropped(item:Item, quantity:int)

@onready var button_drop:Button = $Content/VBoxContainer/Lists/Buttons/Middle/ButtonDrop
@onready var button_pick:Button = $Content/VBoxContainer/Lists/Buttons/Middle/ButtonPick
@onready var button_close:Button = $Content/VBoxContainer/HBoxContainer/ButtonClose
@onready var button_all:Button = $Content/VBoxContainer/Lists/Buttons/ButtonAll
@onready var label:Label = $Content/VBoxContainer/Lists/Left/Label
@onready var list_container:ItemList = $Content/VBoxContainer/Lists/Left/ListContainer
@onready var list_inventory:ItemList = $Content/VBoxContainer/Lists/Right/ListInventory

var current_list:ItemList
var storage:Storage
var transfered_item:Item
var on_storage_close:Callable

func _input(event):
	if (Dialog.ignore_input()): return
	if ((event is InputEventJoypadButton) or (event is InputEventKey)) and (not event.pressed):
		if Input.is_action_just_released("cancel"):
			close()
		elif Input.is_action_just_released("accept") and (list_container.has_focus() or list_inventory.has_focus()):
			_transfert()
		elif Input.is_action_just_released("collect_all") and (list_container.has_focus() or list_inventory.has_focus()):
			_on_button_all_pressed()

func open(node:Storage, on_storage_close):
	super._open()
	self.on_storage_close = on_storage_close
	label.text = tr(str(node))
	storage = node
	current_list = list_container
	connect("item_dropped", GameState.current_zone.on_item_dropped)
	connect("item_collected", GameState.current_zone.on_item_collected)
	_refresh()

func set_shortcuts():
	Tools.set_shortcut_icon(button_close, Tools.SHORTCUT_CANCEL)
	Tools.set_shortcut_icon(button_pick, Tools.SHORTCUT_ACCEPT)
	Tools.set_shortcut_icon(button_drop, Tools.SHORTCUT_ACCEPT)
	Tools.set_shortcut_icon(button_all, Tools.SHORTCUT_ALL)

func close():
	super.close()
	on_storage_close.call(storage)

func _transfert():
	if (current_list == list_container):
		for idx:int in list_container.get_selected_items():
			var item:Item = storage.get_items()[idx];
			if (item is ItemMultiple) and (item.quantity > 1):
				open_select_quantity(item)
			else:
				container_to_inventory(item)
			break
	else:
		for idx in list_inventory.get_selected_items():
			var item:Item = GameState.inventory.getone(idx)
			if (item is ItemMultiple) and (item.quantity > 1):
				open_select_quantity(item)
			else:
				inventory_to_container(item)
			break

func _on_button_all_pressed():
	for item:Item in storage.get_items():
		container_to_inventory(item, -1, false)
	close()

func open_select_quantity(item:Item):
	transfered_item = item
	var dlg = Tools.load_dialog(self, Tools.DIALOG_SELECT_QUANTITY)
	dlg.open(item, true, _on_select_quantity_dialog_quantity)

func _on_select_quantity_dialog_quantity(quantity):
	if (current_list == list_container):
		container_to_inventory(transfered_item, quantity)
	else:
		inventory_to_container(transfered_item, quantity)

func inventory_to_container(item:Item,quantity:int=-1,refresh:bool=true):
	item.set_meta("storage", storage)
	item_dropped.emit(item, quantity)
	if (refresh): 
		_refresh()

func container_to_inventory(item:Item,quantity:int=-1,refresh:bool=true):
	item.set_meta("storage", storage)
	item_collected.emit(item,quantity)
	if (refresh): 
		_refresh()

func _refresh():
	list_container.clear()
	list_inventory.clear()
	for item:Item in storage.get_items():
		list_container.add_item(tr(str(item)))
	for item:Item in GameState.inventory.getall():
		list_inventory.add_item(tr(str(item)))
	current_list.grab_focus()
	if (current_list.item_count > 0):
		current_list.select(0)

func _on_list_container_focus_entered():
	current_list = list_container
	if (current_list.item_count > 0):
		current_list.select(0)
	button_drop.visible = false
	button_pick.visible = true
	
func _on_list_inventory_focus_entered():
	current_list = list_inventory
	if (current_list.item_count > 0):
		current_list.select(0)
	button_drop.visible = true
	button_pick.visible = false
