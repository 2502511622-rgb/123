class_name YinAudioManager
extends Node
var player: AudioStreamPlayer
var muted: bool = false
func start() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_environment("YINTIAN_SILENT") == "1": return
	player = AudioStreamPlayer.new()
	player.stream = preload("res://assets/ambience.wav")
	player.volume_db = -28
	add_child(player)
	player.finished.connect(player.play)
	player.play()
func set_night(night: bool) -> void:
	if player != null: player.volume_db = -21 if night else -28
func toggle() -> void:
	muted = not muted
	if player != null: player.stream_paused = muted
	for voice in voices:voice.stream_paused=muted
func _exit_tree() -> void:
	if is_instance_valid(player):
		player.stop()
		player.stream = null

var cues: Dictionary={}
var voices: Array[AudioStreamPlayer]=[]
static func synth_cue(kind: String) -> AudioStreamWAV:
	var rate: int=22050
	var length_value: float=0.19 if kind=="heavy" else (0.23 if kind in ["fire","seal","spirit"] else 0.11)
	var frames: int=int(rate*length_value)
	var bytes:=PackedByteArray()
	bytes.resize(frames*2)
	var rng:=RandomNumberGenerator.new()
	rng.seed=kind.hash()
	var low: float=0
	for i in range(frames):
		var t: float=float(i)/rate
		var p: float=t/length_value
		var noise: float=rng.randf_range(-1,1)
		low=lerpf(low,noise,0.12 if kind=="heavy" else 0.42)
		var sample: float=low*0.9
		if kind=="heavy":sample+=sin(TAU*(95*t-80*t*t))*0.45
		elif kind in ["fire","seal","spirit"]:sample=sample*0.4+sin(TAU*640*t)*0.15+sin(TAU*960*t)*0.12
		elif kind!="swing":sample+=sin(TAU*1400*t)*0.12
		var envelope: float=minf(1,t*1200)*exp(-p*(7 if kind!="swing" else 4))
		bytes.encode_s16(i*2,roundi(clampf(sample*envelope,-0.8,0.8)*32767))
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=rate
	stream.data=bytes
	return stream
func play_cue(kind: String) -> void:
	if muted or DisplayServer.get_name()=="headless" or OS.get_environment("YINTIAN_SILENT")=="1":return
	if not cues.has(kind):cues[kind]=synth_cue(kind)
	var voice: AudioStreamPlayer=null
	for candidate in voices:
		if not candidate.playing:voice=candidate;break
	if voice==null:
		if voices.size()>=6:return
		voice=AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	voice.stream=cues[kind]
	voice.volume_db=-17 if kind=="heavy" else -22
	voice.play()
