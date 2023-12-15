extends Dialog

@onready var button_yes = $Panel/Content/VBoxContainer/Bottom/ButtonYes
@onready var button_no = $Panel/Content/VBoxContainer/Bottom/ButtonNo
@onready var button_cancel = $Panel/Content/VBoxContainer/Top/ButtonCancel
@onready var label_title = $Panel/Content/VBoxContainer/Top/Label
@onready var label_message = $Panel/Content/VBoxContainer/Label

var _on_confirm:Callable

func _input(event):
	if (Dialog.ignore_input()): return
	if ((event is InputEventJoypadButton) or (event is InputEventKey)) and (not event.pressed):
		if (Input.is_action_just_released("cancel")):
			close()
		elif Input.is_action_just_released("accept") and not button_no.has_focus() and not button_cancel.has_focus():
			_on_button_yes_pressed()
		elif Input.is_action_just_released("decline"):
			_on_button_no_pressed()

func open(title:String, text:String, on_confirm):
	super._open()
	_on_confirm = on_confirm
	label_title.text = tr(title)
	label_message.text = tr(text)
	button_yes.grab_focus()

func set_shortcuts():
	Tools.set_shortcut_icon(button_yes, Tools.SHORTCUT_ACCEPT)
	Tools.set_shortcut_icon(button_cancel, Tools.SHORTCUT_CANCEL)
	Tools.set_shortcut_icon(button_no, Tools.SHORTCUT_DECLINE)

func _on_button_yes_pressed():
	close()
	_on_confirm.call(true)

func _on_button_no_pressed():
	close()
	_on_confirm.call(false)

