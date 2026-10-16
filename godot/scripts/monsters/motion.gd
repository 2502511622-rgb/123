class_name YinMonsterMotion
extends RefCounted
var state: String="idle"
var time: float=0
var travel: float=0
var last_at:=Vector2.ZERO
var initialized: bool=false
var previous_windup: float=0
var release: float=0
var recovery: float=0
var previous_state: String="idle"
var anticipation: float=0
func update(actor,delta: float) -> void:
	if not initialized:last_at=actor.position;initialized=true
	var distance_value: float=actor.position.distance_to(last_at)
	last_at=actor.position
	if actor.freeze_lock>0 or actor.hit_stop>0:
		state="frozen" if actor.freeze_lock>0 else "contact"
		return
	time+=delta
	if distance_value<80:travel+=distance_value
	release=maxf(0,release-delta)
	recovery=maxf(0,recovery-delta)
	if previous_windup>0 and actor.windup<=0 and actor.stun<=0:
		release=0.18;recovery=0.38
	anticipation=clampf(1-actor.windup/(0.8 if actor.record.kind in YinAbilities.BOSSES else 0.5),0,1)
	previous_windup=actor.windup
	previous_state=state
	if actor.record.dead:state="dead"
	elif actor.stun>0:state="stagger"
	elif actor.windup>0:state="anticipation"
	elif actor.charge_time>0 or release>0:state="strike"
	elif recovery>0:state="recover"
	elif distance_value>0.02:state="move"
	else:state="idle"
func descriptor(kind: String) -> Dictionary:
	var data: Dictionary=YinBodyProfile.spec(kind)
	var action: float=0.0
	if state=="anticipation":action=-0.2-0.6*smoothstep(0,1,anticipation)
	elif state=="strike":action=lerpf(1.0,0.0,1-release/0.18)
	elif state=="recover":action=recovery/0.38*0.2
	return {"state":state,"gait":travel/data.stride*TAU,"action":action,"clock":time,"floating":data.floating}
