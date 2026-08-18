class_name TimeManager
extends Node

signal time_changed(time_text: String, environment_color: Color)

@export_range(30.0, 600.0, 1.0) var day_duration_seconds: float = 150.0
@export_range(0.0, 23.99, 0.25) var starting_hour: float = 8.0
@export var environment_gradient: Gradient

var _current_hour: float


func _ready() -> void:
	_current_hour = fposmod(starting_hour, 24.0)
	_emit_time_changed()


func _process(delta: float) -> void:
	var hours_per_second: float = 24.0 / day_duration_seconds
	_current_hour = fposmod(_current_hour + hours_per_second * delta, 24.0)
	_emit_time_changed()


func get_time_text() -> String:
	var total_minutes: int = int(floor(_current_hour * 60.0)) % 1440
	var hour: int = int(total_minutes / 60)
	var minute: int = total_minutes % 60
	return "%02d:%02d" % [hour, minute]


func get_environment_color() -> Color:
	if environment_gradient == null:
		return Color.WHITE
	return environment_gradient.sample(_current_hour / 24.0)


func _emit_time_changed() -> void:
	time_changed.emit(get_time_text(), get_environment_color())
