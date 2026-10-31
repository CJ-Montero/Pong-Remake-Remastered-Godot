extends Node
## Session state replacing obj_controlador and the persistent score globals.

signal match_requested(target_score: int)
signal score_changed

const PORTADA := "res://scenes/portada.tscn"
const OPCIONES := "res://scenes/opciones.tscn"
const CREDITOS := "res://scenes/creditos.tscn"
const TABLERO := "res://scenes/tablero.tscn"

var player_score: int = 0
var cpu_score: int = 0
var winning_score: int = 3
var current_screen: StringName = &"portada"
var transition_pending: bool = false
var quitting: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(request_quit)


func request_quit() -> void:
	if quitting:
		return
	quitting = true
	transition_pending = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.stop_all()
	# Let the audio thread release its stopped playback references before exit.
	await get_tree().create_timer(0.05, true, false, true).timeout
	get_tree().quit()


func request_match(target_score: int) -> void:
	if transition_pending:
		return
	player_score = 0
	cpu_score = 0
	winning_score = target_score
	score_changed.emit()
	match_requested.emit(target_score)
	navigate(TABLERO)


func award_point(for_player: bool) -> void:
	if for_player:
		player_score += 1
	else:
		cpu_score += 1
	score_changed.emit()


func match_finished() -> bool:
	return player_score >= winning_score or cpu_score >= winning_score


func enter_screen(screen: StringName) -> void:
	current_screen = screen
	transition_pending = false
	if screen == &"tablero":
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if screen == &"portada" else Input.MOUSE_MODE_CONFINED
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	AudioManager.set_in_match(screen == &"tablero")


func navigate(scene_path: String) -> void:
	if transition_pending:
		return
	transition_pending = true
	_change_scene.call_deferred(scene_path)


func _change_scene(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		transition_pending = false
		push_error("Cannot open scene %s: %s" % [scene_path, error_string(error)])


func _unhandled_key_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if current_screen == &"portada":
			request_quit()
		else:
			navigate(PORTADA)
