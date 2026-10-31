extends Sprite2D
## The two independent branches deliberately preserve obj_titulo's endpoint timing.

signal message_requested(message: String)

var direction: int = -1
var gm_angle: float = 0.0
const HIT_RECT := Rect2(-112, -36, 225, 72)


func _physics_process(_delta: float) -> void:
	if direction == -1:
		gm_angle -= 0.5
		if gm_angle <= -10.0:
			direction = 1
	if direction == 1:
		gm_angle += 0.5
		if gm_angle >= 10.0:
			direction = -1
	# GameMaker positive angles rotate counterclockwise; Godot uses clockwise.
	rotation_degrees = -gm_angle


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	# collisionKind=1 is the axis-aligned bounding box of the rotated sprite,
	# even though collision_point(..., true, ...) requests precise checking.
	var screen_bounds: Rect2 = get_global_transform_with_canvas() * HIT_RECT
	if not screen_bounds.has_point(event.position):
		return
	var message := ""
	match event.button_index:
		MOUSE_BUTTON_MIDDLE:
			message = "Oye!, no me hagas click con la rueda del mouse, DUELE!"
		MOUSE_BUTTON_LEFT:
			message = "TOUCH ME!"
		MOUSE_BUTTON_RIGHT:
			message = "TOUCH ME HARDER!"
	if not message.is_empty():
		get_viewport().set_input_as_handled()
		message_requested.emit(message)
