class_name YinActionMotion
extends RefCounted
static func phase(remaining: float,duration: float) -> float:
	return clampf(1.0-remaining/maxf(duration,0.01),0,1)
static func swing(progress: float) -> float:
	# Anticipation, fast acceleration through contact, then a weighted recovery.
	if progress<0.36:return lerpf(-1.05,-1.8,smoothstep(0,0.36,progress))
	if progress<0.61:return lerpf(-1.8,1.3,smoothstep(0.36,0.61,progress))
	return lerpf(1.3,0.6,smoothstep(0.61,1,progress))
static func force(progress: float) -> float:
	return sin(clampf((progress-0.36)/0.30,0,1)*PI)
static func body_offset(direction: Vector2,progress: float,heavy: bool) -> Vector2:
	var drive: float=force(progress)*(3.8 if heavy else 2.0)
	var load: float=sin(clampf(progress/0.36,0,1)*PI)*1.2 if progress<0.36 else 0.0
	return direction*(drive-load)+Vector2(0,-drive*0.25)
