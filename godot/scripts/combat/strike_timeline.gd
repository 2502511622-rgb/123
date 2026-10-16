class_name YinStrikeTimeline
extends Resource
# Original implementation of data-driven attack phases. See docs/ARPG_RESEARCH_V022.md.
@export var duration: float=0.22
@export var contact: float=0.50
@export var recovery: float=0.32
@export var damage_scale: float=1.0
@export var reach_bonus: float=0
const LOAD_END: float=0.36
const RELEASE_END: float=0.61
static func resolve(kind: String,heavy: bool=false) -> YinStrikeTimeline:
	var result:=YinStrikeTimeline.new()
	result.duration=0.3 if kind=="whip" else 0.22
	result.recovery=float(YinBalance.WEAPONS.get(kind,YinBalance.WEAPONS.sword).interval)
	if heavy:
		result.duration=0.7 if kind=="whip" else 0.62
		result.recovery=maxf(result.recovery,0.82)
		result.damage_scale=2.15;result.reach_bonus=12
	return result
func frame(elapsed: float,count: int=6) -> int:
	return pose_frame(clampf(elapsed/maxf(duration,0.01),0,1),count)
static func pose_frame(phase: float,count: int=6) -> int:
	# Authored poses 0/1 load, 2 contact, 3 follow-through, 4 recovery, 5 neutral.
	if phase<LOAD_END:return 0 if phase<0.15 else 1
	if phase<0.5:return 2
	if phase<RELEASE_END:return 3
	return 4 if phase<0.88 else mini(5,count-1)
