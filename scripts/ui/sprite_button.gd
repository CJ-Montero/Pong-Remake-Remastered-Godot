extends Node2D
## obj_btn: use the sprite's GameMaker bounding box, not its whole PNG.

signal pressed

@export var sprite_name: String = "spr_btn_3_puntos"

var active: bool = false
var bounds: Rect2
var sprite: Sprite2D


func _ready() -> void:
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/metadata.json"))
	var data: Dictionary = metadata[sprite_name]
	var origin := Vector2(data.origin[0], data.origin[1])
	var box: Array = data.bbox
	bounds = Rect2(Vector2(box[0], box[1]) - origin, Vector2(box[2] - box[0] + 1, box[3] - box[1] + 1))
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/sprites/%s.png" % sprite_name)
	sprite.centered = false
	sprite.position = -origin
	add_child(sprite)
	_update_hover()


func _physics_process(_delta: float) -> void:
	_update_hover()


func _update_hover() -> void:
	active = bounds.has_point(get_local_mouse_position())
	sprite.modulate.a = 1.0 if active else 0.7


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var local_position: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if bounds.has_point(local_position):
			get_viewport().set_input_as_handled()
			pressed.emit()
