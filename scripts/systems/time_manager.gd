class_name TimeManager
extends Node

signal time_changed(time_text: String, environment_color: Color)
signal day_changed(day_number: int, day_text: String)

@export_range(30.0, 600.0, 1.0) var day_duration_seconds: float = 150.0
@export_range(0.0, 23.99, 0.25) var starting_hour: float = 8.0
@export_range(1, 999, 1) var starting_day: int = 1
@export var environment_gradient: Gradient
@export_range(0.0, 23.99, 0.25) var night_start_hour: float = 19.0
@export_range(0.0, 23.99, 0.25) var night_end_hour: float = 5.0

var _current_hour: float
var _current_day: int


func _ready() -> void:
	_current_day = starting_day
	_current_hour = fposmod(starting_hour, 24.0)
	_emit_time_changed()
	day_changed.emit(_current_day, get_day_text())


func _process(delta: float) -> void:
	var hours_per_second: float = 24.0 / day_duration_seconds
	var next_hour: float = _current_hour + hours_per_second * delta
	if next_hour >= 24.0:
		_current_day += int(next_hour / 24.0)
		_current_hour = fposmod(next_hour, 24.0)
		day_changed.emit(_current_day, get_day_text())
	else:
		_current_hour = next_hour
	_emit_time_changed()


func get_time_text() -> String:
	var total_minutes: int = int(floor(_current_hour * 60.0)) % 1440
	var hour: int = int(total_minutes / 60)
	var minute: int = total_minutes % 60
	return "%02d:%02d" % [hour, minute]


func get_day() -> int:
	return _current_day


func get_day_text() -> String:
	return "Day %d" % _current_day


func get_environment_color() -> Color:
	if environment_gradient == null:
		return Color.WHITE
	return environment_gradient.sample(_current_hour / 24.0)


func _emit_time_changed() -> void:
	time_changed.emit(get_time_text(), get_environment_color())


func is_night_time() -> bool:
	if night_start_hour > night_end_hour:
		return _current_hour >= night_start_hour or _current_hour < night_end_hour
	return _current_hour >= night_start_hour and _current_hour < night_end_hour


func get_current_hour() -> float:
	return _current_hour
