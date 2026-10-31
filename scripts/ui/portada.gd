extends Node2D

var exit_steps: int = -1
@onready var message_dialog: AcceptDialog = $MessageDialog


func _ready() -> void:
	GameState.enter_screen(&"portada")
	$ThreePoints.pressed.connect(_request_match.bind(3))
	$TenPoints.pressed.connect(_request_match.bind(10))
	$Options.pressed.connect(_navigate.bind(GameState.OPCIONES))
	$Credits.pressed.connect(_navigate.bind(GameState.CREDITOS))
	$Exit.pressed.connect(_request_exit)
	$Title.message_requested.connect(_show_message)
	message_dialog.confirmed.connect(_close_message)
	message_dialog.canceled.connect(_close_message)


func _navigate(path: String) -> void:
	AudioManager.play_click()
	GameState.navigate(path)


func _request_match(target: int) -> void:
	AudioManager.play_click()
	GameState.request_match(target)


func _request_exit() -> void:
	if exit_steps <= 0:
		AudioManager.play_click()
		exit_steps = maxi(1, ceili(AudioManager.click_stream.get_length() * 60.0) + 1)


func _physics_process(_delta: float) -> void:
	if exit_steps > 0:
		exit_steps -= 1
		if exit_steps == 0:
			GameState.request_quit()


func _show_message(text: String) -> void:
	message_dialog.dialog_text = text
	get_tree().paused = true
	message_dialog.popup_centered()


func _close_message() -> void:
	get_tree().paused = false
