extends "res://scripts/ui/gm_text.gd"

const MUSIC_RECT := Rect2(356, 98, 220, 44)
var active: bool = false


func _ready() -> void:
	GameState.enter_screen(&"opciones")
	AudioManager.music_changed.connect(_on_music_changed)


func _on_music_changed(_index: int) -> void:
	queue_redraw()


func _physics_process(_delta: float) -> void:
	var hovering := contains_music_point(get_local_mouse_position())
	if hovering != active:
		active = hovering
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_position: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if contains_music_point(local_position):
			get_viewport().set_input_as_handled()
			AudioManager.play_click()
			AudioManager.cycle_music()


func contains_music_point(point: Vector2) -> bool:
	# GML point_in_rectangle includes the right/bottom edges; Rect2.has_point does not.
	return (point.x >= MUSIC_RECT.position.x and point.x <= MUSIC_RECT.end.x
		and point.y >= MUSIC_RECT.position.y and point.y <= MUSIC_RECT.end.y)


func _draw() -> void:
	gm_text(Vector2(32, 32), "OPCIONES", 0.5)
	gm_text(Vector2(32, 120), "ALTERNAR MUSICA", 0.3125)
	var tint := Color(1, 1, 1, 1.0 if active else 0.7)
	draw_rect(MUSIC_RECT, tint, false, 1.0)
	var label: String = AudioManager.MUSIC_NAMES[AudioManager.music_index]
	var label_width := FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x * 0.25
	var left := 466.0 - (label_width + 10.5) / 2.0
	gm_text(Vector2(left, 120), label, 0.25, tint)
	# The original atlas has no '>' glyph. Draw the indicator instead of tofu.
	var arrow := Vector2(left + label_width + 7.5, 120)
	draw_polyline(PackedVector2Array([
		arrow + Vector2(-2, -3), arrow + Vector2(1, 0), arrow + Vector2(-2, 3),
	]), tint, 1.0)
	gm_text(Vector2(320, 432), "ESC PARA VOLVER A LA PORTADA", 0.1875, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
