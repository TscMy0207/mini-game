extends FrameworkService

var music_enabled := true
var sound_enabled := true
var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _context: Node

func _init() -> void:
	super(&"audio")

func initialize(context: Node) -> bool:
	_context = context
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_context.add_child(_music_player)
	for index in range(4):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer_%d" % index
		_context.add_child(player)
		_sfx_players.append(player)
	return super.initialize(context)

func play_music(stream: AudioStream, volume_db := 0.0) -> void:
	if not music_enabled or _music_player == null or stream == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()

func play_sfx(stream: AudioStream, volume_db := 0.0) -> void:
	if not sound_enabled or stream == null:
		return
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.play()
			return

func stop_music() -> void:
	if _music_player:
		_music_player.stop()

func shutdown() -> void:
	for player in _sfx_players:
		if is_instance_valid(player):
			player.queue_free()
	_sfx_players.clear()
	if is_instance_valid(_music_player):
		_music_player.queue_free()
	_music_player = null
	super.shutdown()
