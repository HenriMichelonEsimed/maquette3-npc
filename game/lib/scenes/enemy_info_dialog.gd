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


func _input(event):
	if Input.is_action_just_pressed("cancel"):
		close()

func open(enemy:EnemyCharacter):
	xp.text = "XP Gain : %d"  % enemy.xp 
	label.text = str(enemy)
	weapon.text = str(enemy.weapon)
	damages.text = "Damages : %s" % [ enemy.weapon.damages_roll ]
	attackspeed.text = "Attack Speed (%s) : %d"  % [enemy.weapon.speed_roll,  enemy.weapon.speed ]
	hitpoints.text = "Hit Points (%s) : %d"  % [enemy.hit_points_roll,  enemy.hit_points ]
	walkingspeed.text = "Walking Speed (%s) : %d"  % [enemy.walking_speed_roll,  enemy.walking_speed ]
	runningspeed.text = "Running Speed (%s) : %d"  % [enemy.running_speed_roll,  enemy.running_speed ]
	detection.text = "Detection Distance (%s) : %dm"  % [enemy.detection_distance_roll,  enemy.detection_distance ]
	hear.text = "Hearing Distance: %dm"  % enemy.hear_distance
