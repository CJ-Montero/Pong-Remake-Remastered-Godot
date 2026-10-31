extends Node
## One persistent music voice and independent, overlapping sound effects.

signal music_changed(index: int)

const MUSIC_NAMES := ["OFICIAL", "EPICA", "ORIGINAL"]
const MUSIC_PATHS := [
	"res://assets/audio/snd_musica_oficial.wav",
	"res://assets/audio/snd_musica_epica.wav",
	"res://assets/audio/snd_melodia.wav",
]
var click_stream: AudioStreamWAV
var effects: Dictionary = {}

var music_index: int = 0
var in_match: bool = false
var music_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	click_stream = load("res://assets/audio/snd_click.wav")
	effects = {
		&"wall": load("res://assets/audio/snd_pared.wav"),
		&"paddle": load("res://assets/audio/snd_toque.wav"),
		&"miss": load("res://assets/audio/snd_fallo.wav"),
	}
	music_player = AudioStreamPlayer.new()
	music_player.name = "Music"
	add_child(music_player)
	_play_selected_music()


func _play_selected_music() -> void:
	music_player.stop()
	var stream := load(MUSIC_PATHS[music_index]).duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	music_player.stream = stream
	_update_gain()
	music_player.play()


func cycle_music() -> void:
	music_index = (music_index + 1) % MUSIC_PATHS.size()
	_play_selected_music()
	music_changed.emit(music_index)


func set_in_match(value: bool) -> void:
	in_match = value
	_update_gain()


func _update_gain() -> void:
	if is_instance_valid(music_player):
		music_player.volume_db = linear_to_db(0.3 if in_match else 1.0)


func play_effect(stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.finished.connect(player.queue_free)
	player.play()
	return player


func play_click() -> void:
	play_effect(click_stream)


func play_game_effect(effect: StringName) -> void:
	play_effect(effects[effect])


func stop_all() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null


func _exit_tree() -> void:
	stop_all()
