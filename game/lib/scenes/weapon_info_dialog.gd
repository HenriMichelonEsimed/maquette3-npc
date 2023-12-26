extends Dialog

@onready var label = $Panel/MarginContainer/VBoxContainer/Label
@onready var damages = $Panel/MarginContainer/VBoxContainer/LabelDamage
@onready var attackspeed = $Panel/MarginContainer/VBoxContainer/LabelAttackSpeed
@onready var button_cancel = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ButtonCancel
@onready var price = $Panel/MarginContainer/VBoxContainer/LabelPrice

func _input(event):
	if Input.is_action_just_pressed("cancel"):
		close()

func set_shortcuts():
	Tools.set_shortcut_icon(button_cancel, Tools.SHORTCUT_CANCEL)
	
func open(weapon:ItemWeapon):
	super._open()
	label.text = str(weapon)
	damages.text = tr("Damages : %s") % [ weapon.damages_roll ]
	attackspeed.text = tr("Attack Speed (%s) : %d")  % [ weapon.speed_roll,  weapon.speed ]
	price.text = tr("Price: %d" % weapon.price)
