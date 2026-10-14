class_name YinGameClock
extends Node
signal minute_changed(day: int, hour: int, minute: int)
signal dawn(day: int)
var state: FarmState
var last_day: int = -1
var last_minute: int = -1
func bind(data: FarmState) -> void:
	if state != data:
		state = data
		last_day = -1
		last_minute = -1
	publish()
func advance(delta: float, paused: bool) -> void:
	if state == null or paused: return
	state.tick(delta)
	publish()
func publish() -> void:
	if state == null: return
	if last_day != state.day:
		last_day = state.day
		dawn.emit(last_day)
	var whole: int = int(state.minutes)
	if last_minute != whole:
		last_minute = whole
		minute_changed.emit(state.day, int(whole / 60), whole % 60)
