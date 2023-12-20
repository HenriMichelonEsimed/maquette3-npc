extends Dialog

@onready var label = $Panel/MarginContainer/VBoxContainer/Label
@onready var xp = $Panel/MarginContainer/VBoxContainer/LabelXP
@onready var hitpoints = $Panel/MarginContainer/VBoxContainer/LabelHitPoints
@onready var damages = $Panel/MarginContainer/VBoxContainer/LabelDamage
@onready var attackspeed = $Panel/MarginContainer/VBoxContainer/LabelAttackSpeed
@onready var walkingspeed = $Panel/MarginContainer/VBoxContainer/LabelWalkingSpeed
@onready var runningspeed = $Panel/MarginContainer/VBoxContainer/LabelRunningSpeed
@onready var detection = $Panel/MarginContainer/VBoxContainer/LabelDetectionDistance
@onready var hear = $Panel/MarginContainer/VBoxContainer/LabelHearDistance


func _input(event):
	if Input.is_anything_pressed():
		close()

func open(enemy:EnemyCharacter):
	xp.text = "XP Gain : %d"  % enemy.xp 
	label.text = str(enemy)
	damages.text = "Damages : %s" % [ enemy.damages_roll ]
	hitpoints.text = "Hit Points (%s) : %d"  % [enemy.hit_points_roll,  enemy.hit_points ]
	attackspeed.text = "Attack Speed (%s) : %d"  % [enemy.attack_speed_roll,  enemy.attack_speed ]
	walkingspeed.text = "Walking Speed (%s) : %d"  % [enemy.walking_speed_roll,  enemy.walking_speed ]
	runningspeed.text = "Running Speed (%s) : %d"  % [enemy.running_speed_roll,  enemy.running_speed ]
	detection.text = "Detection Distance (%s) : %d"  % [enemy.detection_distance_roll,  enemy.detection_distance ]
	hear.text = "Hearing Distance: %d"  % enemy.hear_distance
