extends "res://tests/test_menu.gd"
## Real physics clock, actual viewport mouse events and mixed audio capture.


func _run() -> void:
	root.size = Vector2i(640, 480)
	var state: Node = root.get_node("GameState")
	var audio: Node = root.get_node("AudioManager")
	var capture_effect := AudioEffectCapture.new()
	capture_effect.buffer_length = 1.0
	AudioServer.add_bus_effect(0, capture_effect)
	var capture_index := AudioServer.get_bus_effect_count(0) - 1
	state.request_match(10)
	await frames()
	var board: Node = current_scene
	var started := Time.get_ticks_usec()
	var maximum_sample := 0.0
	for tick in 360:
		var motion := InputEventMouseMotion.new()
		motion.position = Vector2(320, board.ball.position.y if is_instance_valid(board.ball) else 240.0)
		root.push_input(motion, true)
		await physics_frame
		await process_frame
		var samples := capture_effect.get_buffer(capture_effect.get_frames_available())
		for sample in samples:
			maximum_sample = maxf(maximum_sample, maxf(absf(sample.x), absf(sample.y)))
	var elapsed := (Time.get_ticks_usec() - started) / 1000000.0
	check(elapsed >= 5.8 and elapsed <= 7.0, "360 real physics ticks run at 60 Hz (%.3f s)" % elapsed)
	check(current_scene.name == "Tablero" and board.player.position.y >= 106 and board.player.position.y <= 418, "Live rally accepts mouse events and keeps player in bounds")
	check(maximum_sample > 0.001, "Audio mixer produces non-silent output (peak %.4f)" % maximum_sample)
	# Start a controlled rally, then let the actual physics clock handle its goal.
	board.start_round()
	board.ball.position = Vector2(-1, 150)
	await board.point_awarded
	var scored_at := Time.get_ticks_usec()
	check(board.ball == null, "Live goal removes the ball")
	await board.round_started
	var wait_seconds := (Time.get_ticks_usec() - scored_at) / 1000000.0
	check(absf(wait_seconds - 1.5) < 0.08, "Real-time point delay is 1.5 seconds (%.3f s)" % wait_seconds)
	await capture("partida-en-ejecucion")
	escape()
	await frames()
	check(current_scene.name == "Portada", "Escape leaves a live running match")
	AudioServer.remove_bus_effect(0, capture_index)
	audio.stop_all()
	await create_timer(0.1).timeout
	print("REALTIME TESTS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
