class_name PongCPU
extends PongPaddle
## obj_cpu: decide from the previous observation, then store a new sample.

const MAX_SPEED := 7.0
const RETURN_SPEED := 4.0
const ACCELERATION := 1.5
const REACTION_INTERVAL := 0.06
const MAX_ANTICIPATION := 0.12
const AIM_ERROR := 8.0
const DEAD_ZONE := 3.0
const TOP := 115.0
const BOTTOM := 410.0
const REST_Y := 261.0

var target_y: float = 240.0
var current_speed: float = 0.0
var observation_time: float = 0.0
var shot_error: float = 0.0
var target_ball_id: int = 0
var incoming_shot: bool = false
var observation_valid: bool = false
var observed_ball_id: int = 0
var observed_position := Vector2.ZERO
var observed_velocity := Vector2.ZERO


func reset_paddle() -> void:
	position = Vector2(20, 240)
	target_y = position.y
	current_speed = 0.0
	observation_time = 0.0
	shot_error = 0.0
	target_ball_id = 0
	incoming_shot = false
	observation_valid = false
	observed_ball_id = 0
	observed_position = Vector2.ZERO
	observed_velocity = Vector2.ZERO


func step_cpu(delta: float, ball: PongBall, rng: RandomNumberGenerator) -> void:
	observation_time -= delta
	if observation_time <= 0.0:
		var incoming := observation_valid and observed_velocity.x < -0.001 and observed_position.x > position.x
		if incoming:
			if not incoming_shot or target_ball_id != observed_ball_id:
				shot_error = rng.randf_range(-AIM_ERROR, AIM_ERROR)
			target_ball_id = observed_ball_id
			target_y = observed_position.y + shot_error
			if observed_position.x <= 320.0:
				var contact_steps := maxf(0.0, (observed_position.x - collision_rect().end.x) / -observed_velocity.x)
				var anticipation_steps := minf(contact_steps, MAX_ANTICIPATION * 60.0)
				target_y += observed_velocity.y * anticipation_steps
			target_y = clampf(target_y, TOP, BOTTOM)
		else:
			target_y = REST_Y
			target_ball_id = 0
			shot_error = 0.0
		incoming_shot = incoming

		observation_valid = is_instance_valid(ball) and ball.active
		if observation_valid:
			observed_ball_id = ball.get_instance_id()
			observed_position = ball.position
			observed_velocity = ball.velocity_per_step()
		else:
			observed_ball_id = 0
		observation_time = REACTION_INTERVAL

	var limit := MAX_SPEED if incoming_shot else RETURN_SPEED
	var distance := target_y - position.y
	var desired_speed := 0.0
	if absf(distance) > DEAD_ZONE:
		var braking := sqrt(2.0 * ACCELERATION * (absf(distance) - DEAD_ZONE))
		desired_speed = signf(distance) * minf(limit, braking)
	current_speed += clampf(desired_speed - current_speed, -ACCELERATION, ACCELERATION)
	var next_y := position.y + current_speed
	var clamped_y := clampf(next_y, TOP, BOTTOM)
	position.y = clamped_y
	# Vector2 stores float32; compare before assignment so harmless rounding
	# is not mistaken for hitting a boundary and does not cancel inertia.
	if clamped_y != next_y:
		current_speed = 0.0
