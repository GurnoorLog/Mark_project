extends Node

const MUSIC_PATH := "res://assets/audio/mark_game.wav"

var player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = AudioStreamPlayer.new()
	player.name = "music_player"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	var stream := load(MUSIC_PATH)
	player.stream = stream
	player.volume_db = 0.0
	player.play()

func _process(_delta: float) -> void:
	if player == null or player.stream == null:
		return
	if not player.playing:
		player.play()

func set_volume(value_db: float) -> void:
	if player != null:
		player.volume_db = value_db

func stop_music() -> void:
	if player != null:
		player.stop()

func start_music() -> void:
	if player != null:
		player.play()
