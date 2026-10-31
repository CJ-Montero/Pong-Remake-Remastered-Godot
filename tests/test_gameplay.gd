extends "res://tests/test_menu.gd"
## Source-derived fixtures plus real scene transitions and seeded full matches.

const BallScript := preload("res://scripts/gameplay/ball.gd")
const PaddleScript := preload("res://scripts/gameplay/paddle.gd")
const CPUScript := preload("res://scripts/gameplay/cpu.gd")

var effects_seen: Array[StringName] = []
var points_seen: Array[bool] = []
var stress_steps: int = 0
var stress_points: int = 0


func _run() -> void:
	root.size = Vector2i(640, 480)
	root.gui_embed_subwindows = true
	_test_ball()
	_test_cpu()
	await _test_board()
	await _test_full_matches()
	var audio: Node = root.get_node("AudioManager")
	audio.stop_all()
	await create_timer(0.1).timeout
	print("GAMEPLAY TESTS: %d checks, %d failures; %d simulated steps, %d natural points" % [checks, failures, stress_steps, stress_points])
	quit(0 if failures == 0 else 1)


func _test_ball() -> void:
	var ball := BallScript.new()
	var player := PaddleScript.new()
	var cpu := CPUScript.new()
	player.reset_paddle()
	cpu.reset_paddle()
	ball.effect_requested.connect(func(effect: StringName) -> void: effects_seen.append(effect))
	ball.point_scored.connect(func(for_player: bool) -> void: points_seen.append(for_player))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2018
	var serves: Dictionary = {}
	for i in 240:
		ball.serve(rng)
		check(ball.position.x == 320 and ball.position.y in [140.0, 240.0, 340.0] and ball.direction in [45.0, 135.0, 225.0, 315.0] and ball.speed == 5, "Legal serve %d" % i)
		serves[Vector2(ball.position.y, ball.direction)] = true
	check(serves.size() == 12, "All 12 serve combinations occur")
	ball.position = Vector2(320, 240)
	ball.direction = 45
	ball.move_after_steps()
	check(ball.position.is_equal_approx(Vector2(323.535534, 236.464466)), "45 degrees moves right/up by 5 pixels, not 5*delta")
	# Equality at a wall is not a collision; the next tick sees overshoot.
	ball.position = Vector2(320, 82)
	ball.direction = 45
	effects_seen.clear()
	ball.step(cpu, player)
	check(effects_seen.is_empty() and ball.direction == 45, "No premature wall bounce at y=82")
	ball.move_after_steps()
	ball.step(cpu, player)
	check(ball.position.y == 82 and ball.direction == 315 and effects_seen == [&"wall"], "Upper overshoot clamps, reverses and plays one wall effect")
	ball.position = Vector2(320, 441)
	ball.direction = 315
	effects_seen.clear()
	ball.step(cpu, player)
	check(ball.position.y == 440 and ball.direction == 45 and effects_seen == [&"wall"], "Lower wall bounce")
	# CPU: next position (35,240) overlaps its mask [12,28) by 2 pixels.
	ball.position = Vector2(40, 240)
	ball.direction = 180
	ball.speed = 5
	effects_seen.clear()
	ball.step(cpu, player)
	check(ball.direction == 0 and ball.speed == 5.5 and effects_seen == [&"paddle"], "CPU centre hit reverses and accelerates once")
	ball.move_after_steps()
	check(ball.position == Vector2(45.5, 240), "New speed applies to movement in the same tick")
	ball.position = Vector2(600, 220)
	ball.direction = 0
	ball.speed = 5
	ball.step(cpu, player)
	check(ball.direction == 150 and ball.speed == 5.5, "Player upper hit uses 180 - offset*1.5")
	ball.position = Vector2(600, 260)
	ball.direction = 0
	ball.speed = 5
	ball.step(cpu, player)
	check(ball.direction == 210, "Player lower hit changes vertical sign")
	ball.position = Vector2(40, 220)
	ball.direction = 180
	ball.speed = 5
	ball.step(cpu, player)
	check(ball.direction == 30, "CPU upper hit uses offset*1.5")
	# Both paddles still collide at the 25-pixel cap: effective width is 35.
	for x in [50.0, 590.0]:
		ball.position = Vector2(x, 240)
		ball.direction = 180 if x < 320 else 0
		ball.speed = 25
		effects_seen.clear()
		ball.step(cpu, player)
		check(ball.speed == 25 and effects_seen == [&"paddle"], "Maximum-speed hit at x=%s" % x)
	# Pixel-centre collision boundaries, including fractional overlaps.
	check(not BallScript.masks_overlap(Rect2(28, 211, 19, 20), cpu.collision_rect()), "Touching exclusive edges do not collide")
	check(not BallScript.masks_overlap(Rect2(27.6, 211, 19, 20), cpu.collision_rect()), "Subpixel overlap without a pixel centre is rejected")
	check(BallScript.masks_overlap(Rect2(27.4, 211, 19, 20), cpu.collision_rect()), "Fractional overlap covering a pixel centre collides")
	ball.position = Vector2(600, 280)
	ball.direction = 0
	ball.speed = 5
	effects_seen.clear()
	ball.step(cpu, player)
	check(ball.speed == 5 and effects_seen.is_empty(), "Vertical edge miss does not bounce")
	for boundary in [0.0, 640.0]:
		ball.active = true
		ball.position = Vector2(boundary, 150)
		ball.direction = 180 if boundary == 0 else 0
		points_seen.clear()
		ball.step(cpu, player)
		check(points_seen.is_empty(), "No point at exact room boundary %s" % boundary)
		ball.move_after_steps()
		ball.step(cpu, player)
		check(points_seen == [boundary == 0] and not ball.active and not ball.visible, "Correct scorer after leaving boundary %s" % boundary)
		ball.step(cpu, player)
		check(points_seen.size() == 1, "A destroyed ball cannot score twice")
	player.step_player(-100)
	check(player.position == Vector2(620, 106), "Player upper clamp")
	player.step_player(900)
	check(player.position == Vector2(620, 418), "Player lower clamp")
	player.step_player(237.5)
	check(player.position.y == 237.5, "Player preserves fractional absolute mouse position")
	ball.free()
	player.free()
	cpu.free()


func _test_cpu() -> void:
	var cpu := CPUScript.new()
	var ball := BallScript.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2018
	cpu.reset_paddle()
	ball.position = Vector2(500, 140)
	ball.direction = 180
	cpu.step_cpu(1.0 / 60.0, ball, rng)
	check(not cpu.incoming_shot and cpu.target_y == 261 and cpu.position.y == 241.5, "First CPU sample does not immediately affect the decision")
	for i in 3:
		cpu.step_cpu(1.0 / 60.0, ball, rng)
	check(not cpu.incoming_shot, "0.06-second observation interval rounds up to four 60 Hz ticks")
	# Change the live trajectory; the next decision must still use the old shot.
	ball.position.y = 400
	ball.direction = 0
	cpu.step_cpu(1.0 / 60.0, ball, rng)
	check(cpu.incoming_shot and cpu.target_y >= 132 and cpu.target_y <= 148, "Decision uses previous y=140 sample despite live y=400 and reversed ball")
	check(cpu.current_speed > 0, "Inertia prevents instant reversal toward a new upper target")
	for i in 4:
		cpu.step_cpu(1.0 / 60.0, ball, rng)
	check(not cpu.incoming_shot and cpu.target_y == 261 and cpu.shot_error == 0, "Next observation returns CPU to rest for an outgoing shot")
	cpu.reset_paddle()
	ball.position = Vector2(300, 200)
	ball.direction = 225
	cpu.step_cpu(0.06, ball, rng)
	cpu.step_cpu(0.06, ball, rng)
	check(absf(cpu.target_y - cpu.shot_error - 225.455844) < 0.001, "Anticipation limited to 7.2 steps in own half")
	var previous_error: float = cpu.shot_error
	cpu.step_cpu(0.06, ball, rng)
	check(cpu.shot_error == previous_error, "Aim error stays constant throughout an observed shot")
	cpu.reset_paddle()
	ball.position = Vector2(500, 200)
	cpu.step_cpu(0.06, ball, rng)
	cpu.step_cpu(0.06, ball, rng)
	check(is_equal_approx(cpu.target_y - cpu.shot_error, 200), "No anticipation in the opponent's half")
	cpu.reset_paddle()
	ball.position = Vector2(300, 900)
	ball.direction = 180
	var reached_maximum := false
	var bounded := true
	for i in 200:
		var previous_speed: float = cpu.current_speed
		cpu.step_cpu(1.0 / 60.0, ball, rng)
		bounded = bounded and cpu.position.y >= 115 and cpu.position.y <= 410 and absf(cpu.current_speed) <= 7
		if cpu.position.y > 115 and cpu.position.y < 410:
			bounded = bounded and absf(cpu.current_speed - previous_speed) <= 1.50001
		reached_maximum = reached_maximum or is_equal_approx(cpu.current_speed, 7)
	check(bounded and reached_maximum, "CPU reaches speed 7 with bounded acceleration and y limits")
	for i in 200:
		cpu.step_cpu(1.0 / 60.0, null, rng)
	check(absf(cpu.position.y - 261) <= 3.1 and absf(cpu.current_speed) < 0.001, "CPU settles in rest dead zone without a ball")
	ball.free()
	cpu.free()


func _start_match(target: int) -> Node:
	var state: Node = root.get_node("GameState")
	state.request_match(target)
	await frames()
	var board: Node = current_scene
	board.set_physics_process(false)
	return board


func _test_board() -> void:
	var state: Node = root.get_node("GameState")
	var audio: Node = root.get_node("AudioManager")
	var board: Node = await _start_match(3)
	check(board.name == "Tablero" and is_instance_valid(board.ball), "Gameplay scene has a ball")
	if DisplayServer.get_name() != "headless":
		check(Input.mouse_mode == Input.MOUSE_MODE_CONFINED_HIDDEN, "Gameplay confines and hides cursor")
	check(is_equal_approx(db_to_linear(audio.music_player.volume_db), 0.3), "Gameplay lowers modern music to 30 percent")
	var music: Node = audio.music_player
	board.start_round()
	check(board.player.position == Vector2(620, 240) and board.cpu.position == Vector2(20, 240), "Every round resets both paddles to Create positions")
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(400, 100)
	root.push_input(motion, true)
	board.simulate_step()
	check(board.player.position.y == 106, "Actual viewport input moves the player")
	# Ball's Step sees the old paddle position; CPU observes before ball motion.
	board.start_round()
	board.ball.position = Vector2(600, 240)
	board.ball.direction = 0
	board.mouse_y = 418
	board.simulate_step()
	check(board.ball.direction == 180 and board.player.position.y == 418, "Collision Step precedes current mouse positioning")
	check(board.cpu.observed_position == Vector2(600, 240) and board.ball.position == Vector2(594.5, 240), "CPU observes before automatic ball motion")
	board.start_round()
	board.ball.position = Vector2(-1, 150)
	board.simulate_step()
	check(state.player_score == 1 and state.cpu_score == 0 and board.ball == null and board.point_wait == 90, "Left goal awards exactly one player point and starts a 90-tick alarm")
	var old_round: int = board.round_number
	board.mouse_y = 418
	for i in 89:
		board.simulate_step()
	check(board.ball == null and board.point_wait == 1 and board.player.position.y == 418, "During the full delay ball is absent but paddles keep moving")
	board.simulate_step()
	check(board.round_number == old_round + 1 and is_instance_valid(board.ball) and board.ball.speed == 5, "Tick 90 starts a fresh serve")
	check(state.player_score == 1 and state.cpu_score == 0, "Score survives round reset")
	check(board.mouse_y == 240 and board.cpu.current_speed == 0 and not board.cpu.observation_valid, "Round resets mouse and all AI memory")
	await capture("tablero")
	# Check all effect mappings create playing voices; resources were validated by menu tests.
	for effect in [&"wall", &"paddle", &"miss"]:
		audio.play_game_effect(effect)
		var voice: AudioStreamPlayer = audio.get_child(audio.get_child_count() - 1)
		check(voice.playing and voice.stream == audio.effects[effect], "Gameplay sound: " + effect)
	# Every combination of mode and winner traverses the entire score flow.
	for target in [3, 10]:
		for player_wins in [true, false]:
			state.navigate(state.PORTADA)
			await frames()
			board = await _start_match(target)
			for point in target:
				board.ball.position = Vector2(-1 if player_wins else 641, 150)
				board.simulate_step()
				for i in 89:
					board.simulate_step()
				check(current_scene == board and board.point_wait == 1, "Mode %d winner %s point %d waits 89 steps" % [target, player_wins, point + 1])
				board.simulate_step()
				await frames()
			check(current_scene.name == "Portada", "Mode %d winner %s returns to menu" % [target, player_wins])
			check((state.player_score == target and state.cpu_score == 0) if player_wins else (state.cpu_score == target and state.player_score == 0), "Final score retained until next game")
			check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and is_equal_approx(db_to_linear(audio.music_player.volume_db), 1.0), "Menu restores cursor and music gain")
			check(audio.music_player == music and music.playing, "Music never restarts on round or scene transitions")
	# Escape cancels a pending point alarm without a later unintended scene change.
	board = await _start_match(10)
	board.ball.position = Vector2(-1, 150)
	board.simulate_step()
	escape()
	await frames()
	check(current_scene.name == "Portada", "Escape works during point delay")
	await create_timer(1.6).timeout
	check(current_scene.name == "Portada", "Leaving a match discards its alarm")


func _test_full_matches() -> void:
	var state: Node = root.get_node("GameState")
	var audio: Node = root.get_node("AudioManager")
	var wins := [0, 0]
	# Run genuine rallies, not injected goals, across both scoring modes.
	for trial in 12:
		var target := 3 if trial < 6 else 10
		var board: Node = await _start_match(target)
		board.rng.seed = 2018 + trial
		board.start_round()
		var last_round := -1
		var healthy := true
		var steps := 0
		while not state.transition_pending and steps < 100000:
			if is_instance_valid(board.ball):
				if board.round_number != last_round:
					board.ball.effect_requested.disconnect(audio.play_game_effect)
					last_round = board.round_number
				# Alternate an accurate player with an intentionally stationary one.
				board.mouse_y = board.ball.position.y if trial % 2 == 0 else 106.0
			board.simulate_step()
			steps += 1
			if is_instance_valid(board.ball):
				healthy = healthy and board.ball.position.is_finite() and board.ball.speed <= 25
			healthy = healthy and board.cpu.position.y >= 115 and board.cpu.position.y <= 410
			if steps % 600 == 0 and not state.transition_pending:
				# Flush queued nodes between batches without enabling real-time simulation.
				await frames(1)
		stress_steps += steps
		stress_points += state.player_score + state.cpu_score
		check(healthy and steps < 100000, "Seed %d completes a finite match with legal speeds and bounds" % (2018 + trial))
		if state.player_score >= target:
			wins[0] += 1
		elif state.cpu_score >= target:
			wins[1] += 1
		else:
			check(false, "Stress match has a winner")
		await frames()
		check(current_scene.name == "Portada", "Natural match %d finishes in menu" % trial)
	check(wins[0] > 0 and wins[1] > 0, "Both CPU and player can win natural matches")
	print("Natural match wins — player: %d, CPU: %d" % [wins[0], wins[1]])
