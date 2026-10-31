extends SceneTree
## Run in a separate process; optional user argument: -- escape.

var started: int = 0
var use_escape: bool = false
var use_window: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file("res://scenes/portada.tscn")
	for i in 3:
		await process_frame
	use_escape = "escape" in OS.get_cmdline_user_args()
	use_window = "window" in OS.get_cmdline_user_args()
	root.tree_exiting.connect(_on_exit)
	started = Time.get_ticks_usec()
	if use_window:
		root.close_requested.emit()
	elif use_escape:
		var key := InputEventKey.new()
		key.keycode = KEY_ESCAPE
		key.pressed = true
		root.push_input(key, true)
	else:
		var click := InputEventMouseButton.new()
		click.position = Vector2(521, 384)
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		root.push_input(click, true)
	create_timer(1.0).timeout.connect(func() -> void:
		push_error("Exit did not terminate the game")
		quit(1)
	)


func _on_exit() -> void:
	var seconds := (Time.get_ticks_usec() - started) / 1000000.0
	var valid := seconds < 0.2 if use_escape or use_window else seconds >= 0.2 and seconds <= 0.4
	var method := "window" if use_window else ("Escape" if use_escape else "button")
	print("EXIT TEST: %s, %.3f seconds, %s" % [method, seconds, "PASS" if valid else "FAIL"])
