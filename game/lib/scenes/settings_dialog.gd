extends Dialog

@onready var i18n = $Background/Borders/Content/Panel/Borders/Settings/i18n/OptionButton
@onready var button_close = $Background/Borders/Content/Top/ButtonClose
@onready var button_save = $Background/Borders/Content/Panel/Borders/Settings/Bottom/ButtonSave

func _input(event):
	if (Dialog.ignore_input()): return
	if ((event is InputEventJoypadButton) or (event is InputEventKey)) and (not event.pressed):
		if (Input.is_action_just_released("cancel")):
			close()

func open():
	super._open()
	for i in range(0, i18n.item_count):
		if (Settings.langs[GameState.settings.lang] == i18n.get_item_text(i)):
			i18n.select(i)
	i18n.grab_focus()

func set_shortcuts():
	Tools.set_shortcut_icon(button_close, Tools.SHORTCUT_CANCEL)

func _on_button_save_pressed():
	var item = i18n.get_item_text(i18n.selected)
	for lang in Settings.langs:
		if (Settings.langs[lang] == item):
			GameState.settings.lang = lang
			TranslationServer.set_locale(lang)
	if not(GameState.game_started):
		StateSaver.saveState(GameState.settings, true)
	close()
