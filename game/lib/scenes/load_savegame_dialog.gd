extends Dialog

@onready var list_saves = $Panel/Content/VBoxContainer/ListSavegames
@onready var button_cancel = $Panel/Content/VBoxContainer/Top/ButtonCancel
@onready var button_delete = $Panel/Content/VBoxContainer/Bottom/ButtonDelete
@onready var button_load = $Panel/Content/VBoxContainer/Bottom/ButtonLoad

var saves = {}
var savegame = null
var _on_load_savegame:Callable

func open(on_load_savegame):
	_on_load_savegame = on_load_savegame
	super._open()
	_refresh()

func set_shortcuts():
	Tools.set_shortcut_icon(button_delete, Tools.SHORTCUT_DELETE)
	Tools.set_shortcut_icon(button_load, Tools.SHORTCUT_ACCEPT)
	Tools.set_shortcut_icon(button_cancel, Tools.SHORTCUT_CANCEL)
	
func _refresh():
	list_saves.clear()
	for dir in StateSaver.get_savegames():
		list_saves.add_item(tr("[Auto save]") if dir==StateSaver.autosave_path else dir)
		list_saves.set_item_metadata(list_saves.item_count-1, dir)
	list_saves.grab_focus()
	if (list_saves.item_count > 0):
		list_saves.select(0)
		_on_list_savegames_item_selected(0)

func _input(event):
	if (Dialog.ignore_input()): return
	if ((event is InputEventJoypadButton) or (event is InputEventKey)) and (not event.pressed):
		if (Input.is_action_just_released("cancel")):
			close()
		elif (Input.is_action_just_released("accept") and list_saves.has_focus()):
			_on_button_load_pressed()
		elif (Input.is_action_just_released("delete") and list_saves.has_focus()):
			_on_button_delete_pressed()

func _on_list_savegames_item_selected(index):
	savegame = list_saves.get_item_metadata(index)

func _on_button_load_pressed():
	if (savegame != null): 
		close()
		_on_load_savegame.call(savegame)

func _on_button_delete_pressed():
	if (savegame != null): 
		var delete_confirm_dlg = Tools.load_dialog(self, Tools.DIALOG_CONFIRM, _on_confirm_close)
		delete_confirm_dlg.open("Delete ?", tr("Delete saved game ' %s' ?") % savegame, _on_confirm_delete)
		
func _on_confirm_close():
	list_saves.grab_focus()
	
func _on_confirm_delete(confirm:bool):
	if confirm:
		StateSaver.delete(savegame)
		_refresh()
	else:
		_on_confirm_close()
