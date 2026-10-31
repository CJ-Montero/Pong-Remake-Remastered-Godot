class_name PongBall
extends Node2D
## obj_bola Step and automatic motion are separate phases of the same 60 Hz tick.

signal point_scored(for_player: bool)
signal effect_requested(effect: StringName)

const MASK := Rect2(-9, -10, 19, 20)
const TOP := 82.0
const BOTTOM := 440.0
const BASE_SPEED := 5.0
const SPEED_INCREMENT := 0.5
const MAX_SPEED := 25.0
const SERVE_Y := [140.0, 240.0, 340.0]
const SERVE_DIRECTIONS := [45.0, 135.0, 225.0, 315.0]

var speed: float = BASE_SPEED
var direction: float = 45.0
var active: bool = true


func serve(rng: RandomNumberGenerator) -> void:
	position = Vector2(320, SERVE_Y[rng.randi_range(0, 2)])
	direction = SERVE_DIRECTIONS[rng.randi_range(0, 3)]
	speed = BASE_SPEED
	active = true
	show()


func velocity_per_step() -> Vector2:
	var angle := deg_to_rad(direction)
	# Positive GameMaker directions turn upwards, unlike Vector2.from_angle().
	return Vector2(cos(angle), -sin(angle)) * speed


static func masks_overlap(first: Rect2, second: Rect2) -> bool:
	# Modern GameMaker rectangles use exclusive right/bottom boundaries and
	# reject overlaps that contain no pixel centre (collision compatibility off).
	if not first.intersects(second):
		return false
	var overlap := first.intersection(second)
	return (floorf(overlap.position.x + 0.5) != floorf(overlap.end.x + 0.5)
		and floorf(overlap.position.y + 0.5) != floorf(overlap.end.y + 0.5))


func would_hit(paddle: PongPaddle) -> bool:
	var next_position := position + velocity_per_step()
	return masks_overlap(Rect2(next_position + MASK.position, MASK.size), paddle.collision_rect())


func step(cpu: PongPaddle, player: PongPaddle) -> void:
	if not active:
		return
	var wall_hit := false
	if position.y < TOP:
		position.y = TOP
		wall_hit = true
	if position.y > BOTTOM:
		position.y = BOTTOM
		wall_hit = true
	if wall_hit:
		direction = fposmod(-direction, 360.0)
		effect_requested.emit(&"wall")

	var paddle_hit := false
	if would_hit(cpu):
		direction = fposmod((cpu.position.y - position.y) * 1.5, 360.0)
		paddle_hit = true
	if would_hit(player):
		direction = fposmod(180.0 - (player.position.y - position.y) * 1.5, 360.0)
		paddle_hit = true
	if paddle_hit:
		speed = minf(speed + SPEED_INCREMENT, MAX_SPEED)
		effect_requested.emit(&"paddle")

	# Check the current position, as in GML, before automatic movement.
	if position.x < 0.0 or position.x > 640.0:
		active = false
		hide()
		effect_requested.emit(&"miss")
		point_scored.emit(position.x < 0.0)


func move_after_steps() -> void:
	if active:
		position += velocity_per_step()
