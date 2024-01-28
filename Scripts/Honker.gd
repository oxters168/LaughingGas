extends Node2D
class_name Honker

var _audio_players: Array[AudioStreamPlayer2D]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var need_removal = []
	for audio_player in _audio_players:
		if !audio_player.playing:
			need_removal.append(audio_player)
	for audio_player in need_removal:
		audio_player.queue_free()
		_audio_players.erase(audio_player)
	if Input.is_action_just_pressed("honk"):
		var audio_stream = AudioStreamPlayer2D.new()
		add_child(audio_stream)
		_audio_players.append(audio_stream)
		audio_stream.stream = load("res://Audio/251611__inplay__clown_horn.mp3")
		audio_stream.play()
