extends Dialog

signal input(text)

@onready var label_title = $Panel/Content/VBoxContainer/Top/Label
@onready var edit:LineEdit = $Panel/Content/VBoxContainer/Edit
@onready var button_cancel = $Panel/Content/VBoxContainer/Top/ButtonCancel
@onready var button_ok = $Panel/Content/VBoxContainer/Bottom/ButtonOk

var _on_savegame_input:Callable

func _input(event):
	if (Dialog.ignore_input()): return
	if ((event is InputEventJoypadButton) or (event is InputEventKey)) and (not event.pressed):
		if Input.is_action_just_released("cancel"):
			close()
		elif Input.is_action_just_released("accept"):
			_on_button_ok_pressed()
		
func open(title:String, text:String, on_savegame_input):
	super._open()
	_on_savegame_input = on_savegame_input
	label_title.text = tr(title)
	edit.text = tr(text)
	edit.grab_focus()

func set_shortcuts():
	Tools.set_shortcut_icon(button_cancel, Tools.SHORTCUT_CANCEL)
	Tools.set_shortcut_icon(button_ok, Tools.SHORTCUT_ACCEPT)

func _on_button_ok_pressed():
	close()
	_on_savegame_input.call(edit.text)
