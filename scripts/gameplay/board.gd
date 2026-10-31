extends Node2D
## Central ordering avoids depending on Godot's traversal order for Step events.

signal round_started(number: int)
signal point_awarded(for_player: bool)

const BALL_SCENE: PackedScene = preload("res://scenes/components/ball.tscn")
const POINT_WAIT_STEPS := 90

var ball: PongBall
var rng := RandomNumberGenerator.new()
var point_wait: int = 0
var round_number: int = 0
var mouse_y: float = 240.0

@onready var player: PongPaddle = $Player
@onready var cpu: PongCPU = $CPU


func _ready() -> void:
	rng.randomize()
	GameState.enter_screen(&"tablero")
	start_round()


func start_round() -> void:
	if is_instance_valid(ball):
		ball.queue_free()
	player.reset_paddle()
	cpu.reset_paddle()
	mouse_y = 240.0
	if DisplayServer.get_name() != "headless":
		get_viewport().warp_mouse(Vector2(320, 240))
	ball = BALL_SCENE.instantiate() as PongBall
	add_child(ball)
	ball.serve(rng)
	ball.point_scored.connect(_on_point)
	ball.effect_requested.connect(AudioManager.play_game_effect)
	point_wait = 0
	round_number += 1
	round_started.emit(round_number)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var local_position: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		mouse_y = local_position.y


func _physics_process(delta: float) -> void:
	simulate_step(delta)


func simulate_step(delta: float = 1.0 / 60.0) -> void:
	if GameState.transition_pending:
		return
	# Alarms run before Step in GameMaker. A point scored this tick starts
	# counting down at the beginning of the next tick, not immediately.
	if point_wait > 0:
		point_wait -= 1
		if point_wait == 0:
			if GameState.match_finished():
				GameState.navigate(GameState.PORTADA)
			else:
				start_round()
			return

	# Room creation order: ball, player, CPU. Automatic movement comes last.
	if is_instance_valid(ball):
		ball.step(cpu, player)
	player.step_player(mouse_y)
	cpu.step_cpu(delta, ball, rng)
	if is_instance_valid(ball):
		ball.move_after_steps()


func _on_point(for_player: bool) -> void:
	GameState.award_point(for_player)
	point_wait = POINT_WAIT_STEPS
	ball.queue_free()
	ball = null
	point_awarded.emit(for_player)
