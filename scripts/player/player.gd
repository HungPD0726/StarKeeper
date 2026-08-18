class_name Player
extends CharacterBody2D

signal interaction_prompt_changed(text: String, visible: bool)

@export_range(10.0, 300.0, 1.0) var speed: float = 85.0

var _controls_enabled: bool = true
var _nearby_interactables: Array[Interactable] = []
var _active_interactable: Interactable

@onready var interaction_area: Area2D = $InteractionArea
@onready var animated_sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)


func _physics_process(_delta: float) -> void:
	if _controls_enabled:
		var input_direction: Vector2 = Input.get_vector(
			"move_left", "move_right", "move_up", "move_down"
		)
		velocity = input_direction * speed
		if not is_zero_approx(input_direction.x):
			animated_sprite.flip_h = input_direction.x < 0.0
		animated_sprite.speed_scale = 1.35 if not input_direction.is_zero_approx() else 1.0
	else:
		velocity = Vector2.ZERO
		animated_sprite.speed_scale = 1.0

	move_and_slide()
	_refresh_active_interactable()


func _unhandled_input(event: InputEvent) -> void:
	if not _controls_enabled or not event.is_action_pressed("interact"):
		return

	if is_instance_valid(_active_interactable):
		_active_interactable.interact(self)
		get_viewport().set_input_as_handled()


func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
	_emit_current_prompt()


func _on_interaction_area_entered(area: Area2D) -> void:
	if area is not Interactable:
		return

	var interactable: Interactable = area as Interactable
	if not _nearby_interactables.has(interactable):
		_nearby_interactables.append(interactable)
	_refresh_active_interactable()


func _on_interaction_area_exited(area: Area2D) -> void:
	if area is not Interactable:
		return

	_nearby_interactables.erase(area as Interactable)
	_refresh_active_interactable()


func _refresh_active_interactable() -> void:
	var closest: Interactable
	var closest_distance_squared: float = INF

	for candidate: Interactable in _nearby_interactables:
		if not is_instance_valid(candidate):
			continue
		var distance_squared: float = global_position.distance_squared_to(candidate.global_position)
		if distance_squared < closest_distance_squared:
			closest = candidate
			closest_distance_squared = distance_squared

	if closest == _active_interactable:
		return

	_active_interactable = closest
	_emit_current_prompt()


func _emit_current_prompt() -> void:
	if _controls_enabled and is_instance_valid(_active_interactable):
		interaction_prompt_changed.emit(_active_interactable.prompt_text, true)
	else:
		interaction_prompt_changed.emit("", false)
