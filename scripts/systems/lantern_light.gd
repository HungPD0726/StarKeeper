class_name LanternLight
extends PointLight2D

@export var max_energy: float = 1.1
@export var flicker_amount: float = 0.06
@export var flicker_speed: float = 3.5
@export var auto_night_cycle: bool = true

var _noise_offset: float = 0.0
var _target_opacity: float = 0.0
var _current_opacity: float = 0.0


func _ready() -> void:
	_noise_offset = randf() * 100.0
	energy = 0.0


func _process(delta: float) -> void:
	# Smoothly interpolate towards target opacity
	_current_opacity = move_toward(_current_opacity, _target_opacity, delta * 1.2)

	if _current_opacity <= 0.01:
		energy = 0.0
		return

	# Gentle organic breathing / flicker
	var time_val: float = Time.get_ticks_msec() / 1000.0 * flicker_speed + _noise_offset
	var flicker: float = sin(time_val) * 0.5 + sin(time_val * 2.3) * 0.3 + sin(time_val * 4.7) * 0.2
	var flicker_multiplier: float = 1.0 + flicker * flicker_amount

	energy = max_energy * _current_opacity * flicker_multiplier


func update_time(hour: float) -> void:
	if not auto_night_cycle:
		_target_opacity = 1.0
		return

	# Dusk transition: 17:30 to 19:30 (fade in)
	# Dawn transition: 04:30 to 06:30 (fade out)
	if hour >= 19.5 or hour < 4.5:
		_target_opacity = 1.0
	elif hour >= 17.5 and hour < 19.5:
		_target_opacity = (hour - 17.5) / 2.0
	elif hour >= 4.5 and hour < 6.5:
		_target_opacity = 1.0 - ((hour - 4.5) / 2.0)
	else:
		_target_opacity = 0.0
