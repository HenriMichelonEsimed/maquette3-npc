extends Panel

@onready var insert_point:Node3D = $"ViewContent/3DView/InsertPoint"
@onready var label_item:Label = $LabelTool
@onready var icon_unuse:TextureButton = $Unuse
@onready var icon_help:TextureButton = $Help

var current_item:CurrentItemManager

func set_shortcuts():
	Tools.set_shortcut_icon(icon_unuse, Tools.SHORTCUT_DROP)
	Tools.set_shortcut_icon(icon_help, Tools.SHORTCUT_HELP)

func use():
	Tools.show_item(GameState.current_item, insert_point)
	label_item.text = tr(str(GameState.current_item))
	if (GameState.current_item is ItemWeapon):
		label_item.text += "\nDMG %s AS %d" % [ GameState.current_item.damages_roll, GameState.current_item.speed ]
	visible = true

func unuse():
	visible = false
	for c in insert_point.get_children():
		c.queue_free()

func _on_help_pressed():
	Tools.load_dialog(get_tree().root, Tools.DIALOG_WEAPON_INFO).open(GameState.current_item)

func _on_unuse_pressed():
	NotificationManager.unuse_current_item()
