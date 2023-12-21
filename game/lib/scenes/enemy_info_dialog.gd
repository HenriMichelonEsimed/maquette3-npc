extends Dialog

@onready var label = $Panel/MarginContainer/VBoxContainer/Label
@onready var xp = $Panel/MarginContainer/VBoxContainer/LabelXP
@onready var hitpoints = $Panel/MarginContainer/VBoxContainer/LabelHitPoints
@onready var damages = $Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/LabelDamage
@onready var attackspeed = $Panel/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/LabelAttackSpeed
@onready var walkingspeed = $Panel/MarginContainer/VBoxContainer/LabelWalkingSpeed
@onready var runningspeed = $Panel/MarginContainer/VBoxContainer/LabelRunningSpeed
@onready var detection = $Panel/MarginContainer/VBoxContainer/LabelDetectionDistance
@onready var hear = $Panel/MarginContainer/VBoxContainer/LabelHearDistance
@onready var weapon = $Panel/MarginContainer/VBoxContainer/LabelWeapon
@onready var icon_cancel = $Panel/MarginContainer/VBoxContainer/HBoxContainer/IconCancel
@onready var help = $Panel/MarginContainer/VBoxContainer/LabelHelpDistance

func _input(event):
	if Input.is_action_just_pressed("cancel"):
		close()
		
func set_shortcuts():
	Tools.set_shortcut_icon(icon_cancel, Tools.SHORTCUT_CANCEL)
	
func open(enemy:EnemyCharacter):
	super._open()
	xp.text = tr("XP Gain : %d")  % enemy.xp 
	label.text = str(enemy)
	weapon.text = str(enemy.weapon)
	damages.text = tr("Damages : %s") % [ enemy.weapon.damages_roll ]
	attackspeed.text = tr("Attack Speed (%s) : %d")  % [enemy.weapon.speed_roll,  enemy.weapon.speed ]
	hitpoints.text = tr("Hit Points (%s) : %d")  % [enemy.hit_points_roll,  enemy.hit_points ]
	walkingspeed.text = tr("Walking Speed (%s) : %d")  % [enemy.walking_speed_roll,  enemy.walking_speed ]
	runningspeed.text = tr("Running Speed (%s) : %d")  % [enemy.running_speed_roll,  enemy.running_speed ]
	detection.text = tr("Detection Distance (%s) : %dm")  % [enemy.detection_distance_roll,  enemy.detection_distance ]
	hear.text = tr("Hear&Smell Distance: %dm")  % enemy.hear_distance
	help.text = tr("Helping Distance (%s) : %dm") % [enemy.help_distance_roll,  enemy.help_distance ]
