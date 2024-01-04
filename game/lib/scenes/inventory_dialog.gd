extends Dialog

class InventoryScreenState extends State:
	var tab:int = 0
	func _init():
		super("inventory_screen")

@onready var tabs:TabContainer = $Panel/Content/Body/Content/Tabs
@onready var list_weapons:ItemList = $Panel/Content/Body/Content/Tabs/Weapons/List
@onready var list_clothes:ItemList = $Panel/Content/Body/Content/Tabs/Clothes/List
@onready var list_tools:ItemList = $Panel/Content/Body/Content/Tabs/Tools/List
@onready var list_consumables:ItemList = $Panel/Content/Body/Content/Tabs/Consumables/List
@onready var list_quest:ItemList = $Panel/Content/Body/Content/Tabs/Quests/List
@onready var list_miscellaneous:ItemList = $Panel/Content/Body/Content/Tabs/Miscellaneous/List
@onready var item_content = $Panel/Content/Body/Content/PanelItem/Content
@onready var item_title = $Panel/Content/Body/Content/PanelItem/Content/Title
@onready var node_3d = $"Panel/Content/Body/Content/PanelItem/Content/ViewContent/3DView/InsertPoint"
@onready var panel_crafting = $Panel/Content/Body/Content/PanelCrafting
@onready var list_crafting = $Panel/Content/Body/Content/PanelCrafting/Content/ListCraft
@onready var button_dropcraft = $Panel/Content/Body/Content/PanelCrafting/Content/Actions/DropCraft
@onready var button_craft = $Panel/Content/Body/Content/PanelCrafting/Content/Actions/Craft
@onready var label_recipe = $Panel/Content/Body/Content/PanelCrafting/Content/VBoxContainer/LabelRecipe
@onready var button_close = $Panel/Content/Top/HBoxContainer/ButtonBack
@onready var button_drop = $Panel/Content/Body/Content/PanelItem/Content/Actions/Drop
@onready var button_addcraft = $Panel/Content/Body/Content/PanelItem/Content/Actions/Craft
@onready var button_use = $Panel/Content/Body/Content/PanelItem/Content/Actions/Use
@onready var button_stopcraft = $Panel/Content/Body/Content/PanelCrafting/Content/Top/ButtonStopCraft

@onready var weapon_panel = $Panel/Content/Body/Content/Tabs/Weapons
@onready var weapon_damages = $Panel/Content/Body/Content/PanelItem/Content/InfosWeapons/LabelDamage
@onready var weapon_attackspeed = $Panel/Content/Body/Content/PanelItem/Content/InfosWeapons/LabelAttackSpeed
@onready var weapon_price = $Panel/Content/Body/Content/PanelItem/Content/InfosWeapons/LabelPrice

const tab_order = [ 
	Item.ItemType.ITEM_WEAPONS, 
	Item.ItemType.ITEM_CLOTHES, 
	Item.ItemType.ITEM_TOOLS, 
	Item.ItemType.ITEM_CONSUMABLES,
	Item.ItemType.ITEM_MISCELLANEOUS,
	Item.ItemType.ITEM_QUEST
]

@onready var list_content = {
	Item.ItemType.ITEM_WEAPONS : list_weapons,
	Item.ItemType.ITEM_CLOTHES : list_clothes,
	Item.ItemType.ITEM_TOOLS : list_tools,
	Item.ItemType.ITEM_CONSUMABLES : list_consumables,
	Item.ItemType.ITEM_MISCELLANEOUS : list_miscellaneous,
	Item.ItemType.ITEM_QUEST : list_quest
}

var state = InventoryScreenState.new()
var item:Item
var list:ItemList
var prev_tab = -1
var crafting_items = []
var crafting_recipe = null
var crafting_target = null

func open():
	super._open()
	_resize()
	StateSaver.loadState(state)
	_refresh()
	panel_crafting.visible = false
	if list_content[state.tab].item_count > 0:
		tabs.current_tab = state.tab

func set_shortcuts():
	Tools.set_shortcut_icon(button_close, Tools.SHORTCUT_CANCEL)
	Tools.set_shortcut_icon(button_drop, Tools.SHORTCUT_DROP)
	Tools.set_shortcut_icon(button_use, Tools.SHORTCUT_ACCEPT)
	Tools.set_shortcut_icon(button_addcraft, Tools.SHORTCUT_CRAFT)
	Tools.set_shortcut_icon(button_craft, Tools.SHORTCUT_CRAFT)
	Tools.set_shortcut_icon(button_stopcraft, Tools.SHORTCUT_CANCEL)

func _input(event):
	if (Dialog.ignore_input()): return
	if Input.is_action_just_pressed("cancel"):
		if panel_crafting.visible:
			_on_button_stop_craft_pressed()
		else:
			_on_button_back_pressed()
		return
	if Input.is_action_just_released("delete"):
		_on_drop_pressed()
		return
	if Input.is_action_just_released("accept"):
		_on_use_pressed()
		return
	if Input.is_action_just_pressed("craft"):
		if panel_crafting.visible and (crafting_target != null):
			_on_crafting_pressed()
		else:
			_on_craft_pressed()
		return 
	if (get_viewport().gui_get_focus_owner() == null):
		_focus_current_tab()
	if Input.is_action_just_pressed("ui_left"):
		_set_tab(-1)
	elif Input.is_action_just_pressed("ui_right"):
		_set_tab(1)

func list_focused():
	return list_consumables.has_focus() or list_tools.has_focus() or list_miscellaneous.has_focus() or list_quest.has_focus()

func _resize(with_crafting = false):
	panel_crafting.visible = with_crafting
	button_dropcraft.disabled = true
	button_craft.disabled = true
	var ratio = size.x / size.y
	var vsize = get_viewport().size / get_viewport().content_scale_factor
	size.x = vsize.x / (1.5 if vsize.x > 1200 else 1.2)
	size.y = size.x / ratio
	position.x = (vsize.x - size.x) / 2
	position.y = (vsize.y - size.y) / 2
	tabs.custom_minimum_size.x = size.x/(3 if with_crafting else 2)

func _on_button_back_pressed():
	close()
	_clear_crafting()

func _on_list_weapons_item_selected(index):
	list_consumables.deselect_all()
	list_tools.deselect_all()
	list_miscellaneous.deselect_all()
	list_quest.deselect_all()
	list_clothes.deselect_all()
	_item_details(GameState.inventory.getone_bytype(index, Item.ItemType.ITEM_WEAPONS), index)

func _on_list_clothes_item_selected(index):
	list_weapons.deselect_all()
	list_tools.deselect_all()
	list_consumables.deselect_all()
	list_miscellaneous.deselect_all()
	list_quest.deselect_all()
	_item_details(GameState.inventory.getone_bytype(index, Item.ItemType.ITEM_CLOTHES), index)

func _on_list_tools_item_selected(index):
	list_weapons.deselect_all()
	list_clothes.deselect_all()
	list_consumables.deselect_all()
	list_miscellaneous.deselect_all()
	list_quest.deselect_all()
	_item_details(GameState.inventory.getone_bytype(index, Item.ItemType.ITEM_TOOLS), index)
	
func _on_list_miscellaneous_item_selected(index):
	list_weapons.deselect_all()
	list_clothes.deselect_all()
	list_consumables.deselect_all()
	list_quest.deselect_all()
	list_tools.deselect_all()
	_item_details(GameState.inventory.getone_bytype(index, Item.ItemType.ITEM_MISCELLANEOUS), index)

func _on_list_item_quest_selected(index):
	list_weapons.deselect_all()
	list_clothes.deselect_all()
	list_consumables.deselect_all()
	list_miscellaneous.deselect_all()
	list_tools.deselect_all()
	_item_details(GameState.inventory.getone_bytype(index, Item.ItemType.ITEM_QUEST), index)

func _on_list_item_consumable_selected(index):
	list_weapons.deselect_all()
	list_clothes.deselect_all()
	list_miscellaneous.deselect_all()
	list_quest.deselect_all()
	list_tools.deselect_all()
	_item_details(GameState.inventory.getone_bytype(index, Item.ItemType.ITEM_CONSUMABLES), index)

func _item_details(_item:Item, index):
	item = _item
	item_title.text = item.label
	Tools.show_item(_item, node_3d)
	item_content.visible = true
	button_addcraft.disabled = not button_craft.disabled
	weapon_panel.visible = false
	match (_item.type):
		Item.ItemType.ITEM_WEAPONS:
			weapon_damages.text = tr("Damages : %s") % [ _item.damages_roll ]
			weapon_attackspeed.text = tr("Attack Speed (%s) : %d")  % [ _item.speed_roll,  _item.speed ]
			weapon_price.text = tr("Price: %d" % _item.price)
			weapon_panel.visible = true

func _set_tab(diff:int):
	state.tab = tabs.current_tab
	state.tab += diff
	if (state.tab < 0):
		state.tab = 5
	elif (state.tab > 5):
		state.tab = 0
	tabs.current_tab = state.tab

func _fill_list(type:Item.ItemType, list:ItemList):
	list.clear()
	for item in GameState.inventory.getall_bytype(type):
		list.add_item(tr(str(item)))

func _on_drop_pressed():
	if (item == null): return
	if (item is ItemMultiple) and (item.quantity > 1):
		var select_dialog = Tools.load_dialog(self, Tools.DIALOG_SELECT_QUANTITY, _on_select_close)
		select_dialog.open(item, false, _drop, tr("Drop"))
	else:
		_drop()

func _on_select_close():
	_focus_current_tab()

func _drop(quantity:int=1):
	GameState.current_zone.on_item_dropped(item, quantity)
	_refresh()

func _refresh():
	item_content.visible = false
	_fill_lists()
	_focus_current_tab()

func _focus_current_tab(index:int=0):
	list = list_content[tab_order[tabs.current_tab]]
	list.grab_focus()
	if (list.item_count > 0):
		if not list.is_anything_selected():
			if (index > (list.item_count-1)):
				index = list.item_count-1
			list.select(index)
			list.item_selected.emit(index)
	else:
		item = null

func _on_tabs_tab_selected(tab):
	if (prev_tab == tab): return
	prev_tab = tab
	_focus_current_tab()
	state.tab = tab
	StateSaver.saveState(state)

func _fill_crafting_list():
	list_crafting.clear()
	for citem in crafting_items:
		list_crafting.add_item(tr(str(citem)))
	_resize(true)

func _fill_lists():
	for type in list_content: 
		_fill_list(type, list_content[type])

func _clear_crafting():
	for itm in crafting_items:
		GameState.inventory.add(itm)
	crafting_items.clear()

func _on_craft_pressed():
	if (item == null) or crafting_items.find(item) != -1: return
	list = list_content[tab_order[tabs.current_tab]]
	var index = list.get_selected_items()[0]
	var craft_item = item.dup()
	if item is ItemUnique:
		item_content.visible = false
	else:
		craft_item.quantity = 1
		if (item.quantity == 1):
			item_content.visible = false
	crafting_items.push_back(craft_item)
	_fill_crafting_list()
	GameState.inventory.remove(craft_item)
	_fill_lists()
	var ingredients = []
	for i in crafting_items:
		ingredients.push_back(i.key)
	ingredients.sort()
	for i in CraftingRecipes.ingredients:
		if (item.key == i):
			var targets = CraftingRecipes.ingredients[i]
			for target in targets:
				var target_ingredients = CraftingRecipes.recipes[target][1]
				var have_recipe = target_ingredients == ingredients
				button_craft.disabled = not have_recipe
				label_recipe.text = "-"
				if have_recipe:
					crafting_target = Tools.load_item(CraftingRecipes.recipes[target][0], target)
					if (crafting_target != null):
						crafting_recipe = target
						label_recipe.text = tr(str(crafting_target))
					else:
						button_craft.disabled = true
	button_addcraft.disabled = not button_craft.disabled
	_focus_current_tab(index)

func _on_button_stop_craft_pressed():
	_clear_crafting()
	list_crafting.clear()
	crafting_target = null
	_resize(false)
	_refresh()

func _on_drop_craft_pressed():
	if list_crafting.get_selected_items().size() == 0: return
	var selected = list_crafting.get_selected_items()[0]
	var craft_item = crafting_items[selected]
	crafting_items.remove_at(selected)
	GameState.inventory.add(craft_item)
	item_content.visible = false
	_fill_lists()
	if (crafting_items.is_empty()):
		_on_button_stop_craft_pressed()
	else:
		_fill_crafting_list()

func _on_list_craft_item_selected(index):
	button_dropcraft.disabled = false

func _on_crafting_pressed():
	if (crafting_target == null): return
	GameState.inventory.add(crafting_target)
	crafting_items.clear()
	list_crafting.clear()
	crafting_target = null
	label_recipe.text = "-"
	_resize(false)
	_refresh()

func _on_use_pressed():
	if (item == null): return
	_on_button_back_pressed()
	CurrentItemManager.use(item)
