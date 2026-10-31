class_name PongPaddle
extends Node2D
## GameMaker spr_jugador: origin (8, 29), 16 x 59 rectangular mask.

const MASK := Rect2(-8, -29, 16, 59)
const PLAYER_TOP := 106.0
const PLAYER_BOTTOM := 418.0


func collision_rect() -> Rect2:
	return Rect2(position + MASK.position, MASK.size)


func step_player(mouse_y: float) -> void:
	position.y = clampf(mouse_y, PLAYER_TOP, PLAYER_BOTTOM)


func reset_paddle() -> void:
	position = Vector2(620, 240)
