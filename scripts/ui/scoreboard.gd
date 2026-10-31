extends "res://scripts/ui/gm_text.gd"


func _ready() -> void:
	GameState.score_changed.connect(queue_redraw)


func _draw() -> void:
	gm_text(Vector2(288, 28), str(GameState.cpu_score), 1.0, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	gm_text(Vector2(354, 28), str(GameState.player_score), 1.0)
