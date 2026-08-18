class_name ShootingStarSystem
extends Node2D

@export_range(4.0, 30.0, 0.5) var min_interval: float = 6.0
@export_range(6.0, 45.0, 0.5) var max_interval: float = 15.0
@export var area_size: Vector2 = Vector2(640, 260)

var _timer: float = 0.0
var _next_spawn: float = 0.0


func _ready() -> void:
	_schedule_next()


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _next_spawn:
		_spawn_shooting_star()
		_schedule_next()


func _schedule_next() -> void:
	_timer = 0.0
	_next_spawn = randf_range(min_interval, max_interval)


func _spawn_shooting_star() -> void:
	# Random start position along the top-right area
	var start_x: float = randf_range(area_size.x * 0.2, area_size.x * 0.95)
	var start_y: float = randf_range(10.0, area_size.y * 0.4)
	var start: Vector2 = Vector2(start_x, start_y)

	# Direction: mostly left-downward with some variation
	var angle: float = randf_range(2.3, 2.9)  # radians, roughly 130-165 degrees
	var length: float = randf_range(60.0, 140.0)
	var end: Vector2 = start + Vector2(cos(angle), sin(angle)) * length

	# Tail trail
	var trail: Line2D = Line2D.new()
	trail.name = "ShootingStar"
	trail.width = 1.0
	trail.default_color = Color(1.6, 1.5, 1.2, 0.9)
	trail.add_point(start)
	trail.add_point(start)
	add_child(trail)

	# Head glow dot
	var head: ColorRect = ColorRect.new()
	head.size = Vector2(2, 2)
	head.color = Color(2.0, 1.8, 1.3, 1.0)
	head.position = start - Vector2(1, 1)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(head)

	# Animate: head moves, trail follows, then fade out
	var duration: float = randf_range(0.3, 0.6)
	var tween: Tween = create_tween()

	# Phase 1: streak across the sky
	tween.tween_method(
		func(t: float) -> void:
			var current_pos: Vector2 = start.lerp(end, t)
			head.position = current_pos - Vector2(1, 1)
			trail.set_point_position(1, current_pos),
		0.0, 1.0, duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Phase 2: fade out
	tween.tween_property(trail, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(head, "modulate:a", 0.0, 0.3)

	# Cleanup
	tween.tween_callback(trail.queue_free)
	tween.tween_callback(head.queue_free)
