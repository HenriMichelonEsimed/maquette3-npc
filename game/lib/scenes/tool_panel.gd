extends Panel

@onready var insert_point:Node3D = $"ViewContent/3DView/InsertPoint"
@onready var label_item:Label = $LabelTool
@onready var icon_unuse:TextureRect = $IconUnuse

func set_shortcuts():
	Tools.set_shortcut_icon(icon_unuse, Tools.SHORTCUT_DROP)

func use():
	Tools.show_item(GameState.current_item, insert_point)
	label_item.text = tr(str(GameState.current_item))
	visible = true

func unuse():
	visible = false
	for c in insert_point.get_children():
		c.queue_free()
