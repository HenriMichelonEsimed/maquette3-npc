class_name GameMechanics extends Object

const ATTACK_COOLDOWN:Array[float] = [ 0.2, 0.5, 0.8, 1.2, 1.5, 1.9, 2.2, 2.5 ]
const ANIM_SCALE:Array[float] = [ 8.0, 4.5, 3.0, 2.0, 1.6, 1.3, 1.15, 1.0 ]

static func attack_cooldown(speed:int) -> float:
	return ATTACK_COOLDOWN[speed]
	
static func anim_scale(speed:int) -> float:
	return ANIM_SCALE[speed]
