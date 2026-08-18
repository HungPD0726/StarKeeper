class_name ShootingStarSystem
extends Node2D

@export_range(4.0, 30.0, 0.5) var min_interval: float = 6.0
@export_range(6.0, 45.0, 0.5) var max_interval: float = 15.0
@export var area_size: Vector2 = Vector2(640, 260)

var is_meteor_shower: bool = false
var _timer: float = 0.0
var _next_spawn: float = 0.0


func _ready() -> void:
	_schedule_next()


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _next_spawn:
		_spawn_shooting_star()
		if is_meteor_shower and randf() < 0.5:
			# Double stars in meteor shower
			_spawn_shooting_star()
		_schedule_next()


func set_meteor_shower_mode(enabled: bool) -> void:
	is_meteor_shower = enabled
	_schedule_next()


func _schedule_next() -> void:
	_timer = 0.0
	if is_meteor_shower:
		_next_spawn = randf_range(0.8, 2.2)
	else:
		_next_spawn = randf_range(min_interval, max_interval)


func _spawn_shooting_star() -> void:
	var start_x: float = randf_range(area_size.x * 0.1, area_size.x * 0.95)
	var start_y: float = randf_range(10.0, area_size.y * 0.45)
	var start: Vector2 = Vector2(start_x, start_y)

	var angle: float = randf_range(2.2, 2.9)
	var length: float = randf_range(60.0, 160.0)
	var end: Vector2 = start + Vector2(cos(angle), sin(angle)) * length

	var trail_color: Color
	if is_meteor_shower:
		var colors: Array[Color] = [
			Color(1.8, 1.4, 0.8, 0.95),  # Gold
			Color(0.9, 1.6, 2.0, 0.95),  # Cyan
			Color(1.8, 1.1, 1.6, 0.95),  # Lavender
		]
		trail_color = colors[randi() % colors.size()]
	else:
		trail_color = Color(1.6, 1.5, 1.2, 0.9)

	var trail: Line2D = Line2D.new()
	trail.name = "ShootingStar"
	trail.width = 1.0
	trail.default_color = trail_color
	trail.add_point(start)
	trail.add_point(start)
	add_child(trail)

	var head: ColorRect = ColorRect.new()
	head.size = Vector2(2, 2)
	head.color = Color(2.0, 1.8, 1.4, 1.0)
	head.position = start - Vector2(1, 1)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(head)

	var duration: float = randf_range(0.25, 0.55)
	var tween: Tween = create_tween()

	tween.tween_method(
		func(t: float) -> void:
			var current_pos: Vector2 = start.lerp(end, t)
			head.position = current_pos - Vector2(1, 1)
			trail.set_point_position(1, current_pos),
		0.0, 1.0, duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.tween_property(trail, "modulate:a", 0.0, 0.35)
	tween.parallel().tween_property(head, "modulate:a", 0.0, 0.25)

	tween.tween_callback(trail.queue_free)
	tween.tween_callback(head.queue_free)
