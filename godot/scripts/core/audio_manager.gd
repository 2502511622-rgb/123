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
func _exit_tree() -> void:
	if is_instance_valid(player):
		player.stop()
		player.stream = null
