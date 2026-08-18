class_name ObservatoryView
extends Control

signal closed

@export_range(1, 80, 1) var star_count: int = 24
@export var star_seed: int = 7319

var _elapsed: float = 0.0
var _stars: Array[ColorRect] = []
var _twinkle_speeds: Array[float] = []
var _twinkle_phases: Array[float] = []

@onready var stars_root: Control = %Stars


func _ready() -> void:
	_build_stars()
	hide()
	set_process(false)
	set_process_unhandled_input(false)


func _process(delta: float) -> void:
	_elapsed += delta
	for index: int in _stars.size():
		var star: ColorRect = _stars[index]
		var alpha: float = 0.72 + sin(
			_elapsed * _twinkle_speeds[index] + _twinkle_phases[index]
		) * 0.24
		var tint: Color = star.modulate
		tint.a = alpha
		star.modulate = tint


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel"):
		close_view()
		get_viewport().set_input_as_handled()


func open_view() -> void:
	show()
	set_process(true)
	set_process_unhandled_input(true)


func close_view() -> void:
	hide()
	set_process(false)
	set_process_unhandled_input(false)
	closed.emit()


func _build_stars() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = star_seed

	for index: int in star_count:
		var star: ColorRect = ColorRect.new()
		var pixel_size: int = random.randi_range(1, 3)
		star.name = "Star%02d" % index
		star.position = Vector2(
			random.randi_range(20, 617 - pixel_size),
			random.randi_range(16, 245)
		)
		star.size = Vector2(pixel_size, pixel_size)
		star.color = Color(0.9, 0.94 + random.randf_range(0.0, 0.06), 1.0, 1.0)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stars_root.add_child(star)
		_stars.append(star)
		_twinkle_speeds.append(random.randf_range(0.7, 1.8))
		_twinkle_phases.append(random.randf_range(0.0, TAU))
