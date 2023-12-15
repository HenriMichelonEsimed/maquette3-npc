extends Dialog

@onready var slider_quantity:Slider = $Content/Body/SliderQuantity
@onready var label_quantity:Label = $Content/Body/LabelQuantity
@onready var label_name:Label = $Content/Body/Top/LabelName
@onready var button_drop:Button = $Content/Body/Buttons/ButtonDrop
@onready var button_cancel:Button = $Content/Body/Top/ButtonCancel

var quantity_tostring:Callable
var quantity:Callable

func _input(event):
	if (Dialog.ignore_input()): return
	if ((event is InputEventJoypadButton) or (event is InputEventKey)) and (not event.pressed):
		if Input.is_action_just_released("cancel"):
			_on_button_cancel_pressed()
			return
		if slider_quantity.has_focus():
			if Input.is_action_just_released("accept"):
				_on_button_drop_pressed()
				return

func open(item:Item, all:bool, qty:Callable, label:String="Transfert", qty_str:Callable=_quantity_tostring):
	super._open()
	button_drop.text = tr(label)
	label_name.text = tr(item.label)
	quantity_tostring = qty_str
	quantity = qty
	slider_quantity.max_value = item.quantity
	slider_quantity.value = item.quantity if all else 1
	label_quantity.text = quantity_tostring.call(slider_quantity.value)
	slider_quantity.grab_focus()

func set_shortcuts():
	Tools.set_shortcut_icon(button_cancel, Tools.SHORTCUT_CANCEL)
	Tools.set_shortcut_icon(button_drop, Tools.SHORTCUT_ACCEPT)

func _quantity_tostring(value) -> String:
	return str(value)

func _on_slider_quantity_value_changed(value):
	label_quantity.text = quantity_tostring.call(value)

func _on_button_cancel_pressed():
	close()

func _on_button_drop_pressed():
	close()
	quantity.call(slider_quantity.value)
