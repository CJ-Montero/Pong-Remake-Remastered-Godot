extends Node2D
## Bitmap text positioned using the original draw_text_transformed coordinates.

const FONT: Font = preload("res://assets/fonts/fnt_marcador.fnt")
const FONT_SIZE := 43


func gm_text(at: Vector2, text: String, factor: float, color: Color = Color.WHITE,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		middle: bool = true, separation: float = 43.0) -> void:
	var lines := text.split("\n")
	var height := 43.0 + (lines.size() - 1) * separation
	var top := -height / 2.0 if middle else 0.0
	draw_set_transform(at, 0.0, Vector2.ONE * factor)
	for i in lines.size():
		var width := FONT.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var left := 0.0
		if align == HORIZONTAL_ALIGNMENT_CENTER:
			left = -width / 2.0
		elif align == HORIZONTAL_ALIGNMENT_RIGHT:
			left = -width
		draw_string(FONT, Vector2(left, top + i * separation + FONT.get_ascent(FONT_SIZE)),
			lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
	draw_set_transform(Vector2.ZERO)
