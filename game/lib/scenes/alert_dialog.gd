extends Dialog

@onready var button_ok:Button = $Panel/Content/VBoxContainer/Bottom/ButtonOk
@onready var title:Label = $Panel/Content/VBoxContainer/Top/Label
@onready var message:Label = $Panel/Content/VBoxContainer/Label

func _input(event):
	if (Dialog.ignore_input()): return
	if ((event is InputEventJoypadButton) or (event is InputEventKey)) and (not event.pressed):
		if (Input.is_action_just_released("cancel") or Input.is_action_just_released("accept")):
			close()

func open(_title:String, _message:String, _free=true):
	super._open()
	title.text = tr(_title)
	message.text = tr(_message)
	button_ok.grab_focus()

func set_shortcuts():
	Tools.set_shortcut_icon(button_ok, Tools.SHORTCUT_ACCEPT)
