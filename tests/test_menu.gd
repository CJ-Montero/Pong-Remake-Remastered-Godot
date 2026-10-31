extends SceneTree
## Integration checks against the original menu's coordinates and transitions.
## Run: godot --headless --path godot --script res://tests/test_menu.gd

var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)


func frames(count: int = 3) -> void:
	for i in count:
		await process_frame


func click(at: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = button
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)


func escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)


func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png("/tmp/opencode/pong-" + label + ".png")


func _run() -> void:
	root.size = Vector2i(640, 480)
	root.gui_embed_subwindows = true
	var state: Node = root.get_node("GameState")
	var audio: Node = root.get_node("AudioManager")
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/metadata.json"))
	for sprite_name in metadata:
		var texture := load("res://assets/sprites/%s.png" % sprite_name) as Texture2D
		var dimensions: Array = metadata[sprite_name]["size"]
		check(texture != null and texture.get_size() == Vector2(dimensions[0], dimensions[1]), "Original sprite dimensions: " + sprite_name)
	for font_name in ["fnt_marcador"]:
		var font := load("res://assets/fonts/%s.fnt" % font_name) as Font
		check(font != null and font.has_char(65), "Bitmap font imports: " + font_name)
	for sound in ["snd_click", "snd_fallo", "snd_melodia", "snd_musica_oficial", "snd_musica_epica", "snd_pared", "snd_toque"]:
		var stream := load("res://assets/audio/%s.wav" % sound) as AudioStreamWAV
		check(stream != null and stream.get_length() > 0 and stream.format == AudioStreamWAV.FORMAT_16_BITS, "Uncompressed original audio: " + sound)
	change_scene_to_file("res://scenes/portada.tscn")
	await frames()
	check(current_scene.name == "Portada", "Portada loads")
	check(Engine.physics_ticks_per_second == 60, "Fixed 60 Hz")
	check(audio.music_player.playing and audio.music_index == 0, "Official music autoplays")
	var music_id: int = audio.music_player.get_instance_id()
	await capture("portada")
	# Inert PNG padding must not activate the 3-point button.
	click(Vector2(381, 240))
	await frames()
	check(not paused and state.winning_score == 3, "Transparent padding does not activate")
	for target in [3, 10]:
		state.player_score = 2
		state.cpu_score = 1
		click(Vector2(480, 256) if target == 3 else Vector2(471, 305))
		await frames()
		check(state.winning_score == target and state.player_score == 0 and state.cpu_score == 0, "Mode %d resets score" % target)
		check(not paused and current_scene.name == "Tablero", "Mode %d enters gameplay" % target)
		escape()
		await frames()
		check(current_scene.name == "Portada", "Escape returns from gameplay")
	# Title easter eggs, using real input dispatch and original coordinates.
	for pair in [[MOUSE_BUTTON_LEFT, "TOUCH ME!"], [MOUSE_BUTTON_RIGHT, "TOUCH ME HARDER!"], [MOUSE_BUTTON_MIDDLE, "DUELE!"]]:
		click(Vector2(163, 159), pair[0])
		await frames()
		check(paused and pair[1] in current_scene.get_node("MessageDialog").dialog_text, "Title mouse button %s" % pair[0])
		current_scene.get_node("MessageDialog").get_ok_button().pressed.emit()
		await frames()
	var title: Node = current_scene.get_node("Title")
	title.set_physics_process(false)
	title.gm_angle = 0.0
	title.direction = -1
	for i in 20:
		title._physics_process(1.0 / 60.0)
	check(is_equal_approx(title.gm_angle, -9.5), "Title endpoint at step 20 follows GML's two ifs")
	for i in 39:
		title._physics_process(1.0 / 60.0)
	check(is_equal_approx(title.gm_angle, 10.0), "Title opposite endpoint at step 59")
	click(Vector2(55, 110))
	await frames()
	check(paused and current_scene.get_node("MessageDialog").dialog_text == "TOUCH ME!", "Rotated title uses its axis-aligned GameMaker mask")
	current_scene.get_node("MessageDialog").get_ok_button().pressed.emit()
	await frames()
	click(Vector2(160, 352))
	await frames()
	check(current_scene.name == "Opciones", "Options button navigates")
	check(audio.music_player.get_instance_id() == music_id, "Music voice survives scene change")
	for expected in [1, 2, 0]:
		click(Vector2(466, 120))
		await frames()
		check(audio.music_index == expected and audio.music_player.playing, "Music cycles to %d" % expected)
		check(audio.music_player.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Selected track loops")
	click(Vector2(576, 142))
	await frames()
	check(audio.music_index == 1, "Music rectangle includes its right/bottom edge")
	click(Vector2(576.1, 142))
	await frames()
	check(audio.music_index == 1, "Point beyond music rectangle does not activate")
	audio.cycle_music()
	audio.cycle_music()
	await capture("opciones")
	audio.set_in_match(true)
	for i in 3:
		check(is_equal_approx(db_to_linear(audio.music_player.volume_db), 0.3), "Music track %d lowers in match" % audio.music_index)
		audio.cycle_music()
	for i in 3:
		audio.cycle_music()
	audio.set_in_match(false)
	check(is_equal_approx(db_to_linear(audio.music_player.volume_db), 1.0), "Menus recover full gain")
	escape()
	await frames()
	check(current_scene.name == "Portada", "Escape returns from options")
	click(Vector2(160, 384))
	await frames()
	check(current_scene.name == "Creditos", "Credits button navigates")
	await capture("creditos")
	escape()
	await frames()
	check(current_scene.name == "Portada", "Escape returns from credits")
	current_scene.set_physics_process(false)
	click(Vector2(521, 384))
	check(current_scene.exit_steps == 12, "Exit waits ceil(0.169161 * 60) + 1 = 12 steps")
	current_scene.exit_steps = 5
	click(Vector2(521, 384))
	check(current_scene.exit_steps == 5, "Repeated exit click does not reset countdown")
	audio.stop_all()
	# Allow the audio mixing thread to release finished playbacks before teardown.
	await create_timer(0.1).timeout
	print("MENU TESTS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
