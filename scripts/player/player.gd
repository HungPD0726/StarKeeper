class_name Player
extends CharacterBody2D

signal interaction_prompt_changed(text: String, visible: bool)
signal step_taken(world_position: Vector2)

@export_category("Movement")
@export_range(10.0, 300.0, 1.0) var speed: float = 85.0
@export_range(100.0, 2000.0, 10.0) var acceleration: float = 900.0
@export_range(100.0, 2500.0, 10.0) var deceleration: float = 1200.0

@export_category("Movement Feedback")
@export_range(8.0, 32.0, 1.0) var step_distance: float = 16.0
@export_range(0.0, 3.0, 1.0) var walk_bob_pixels: float = 1.0
@export_range(0.0, 2.0, 1.0) var walk_sway_pixels: float = 1.0
@export var step_dust_color: Color = Color(0.91, 0.66, 0.27, 0.65)

var _controls_enabled: bool = true
var _nearby_interactables: Array[Interactable] = []
var _active_interactable: Interactable
var _walk_cycle_distance: float = 0.0
var _step_side: float = 1.0
var _facing_name: StringName = &"down"
var _sprite_rest_position: Vector2
var _shadow_rest_scale: Vector2

@onready var interaction_area: Area2D = $InteractionArea
@onready var animated_sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var shadow: Polygon2D = $Visual/Shadow
@onready var footstep_origin: Marker2D = $FootstepOrigin


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_sprite_rest_position = animated_sprite.position
	_shadow_rest_scale = shadow.scale
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)


func _physics_process(delta: float) -> void:
	var input_direction: Vector2 = Vector2.ZERO
	if _controls_enabled:
		input_direction = Input.get_vector(
			"move_left", "move_right", "move_up", "move_down"
		)
		var target_velocity: Vector2 = input_direction * speed
		var velocity_change_rate: float = (
			acceleration if not input_direction.is_zero_approx() else deceleration
		)
		velocity = velocity.move_toward(target_velocity, velocity_change_rate * delta)
	else:
		velocity = Vector2.ZERO

	var position_before_move: Vector2 = global_position
	move_and_slide()
	var distance_moved: float = global_position.distance_to(position_before_move)
	var movement_direction: Vector2 = (
		get_last_motion().normalized() if distance_moved > 0.01 else input_direction
	)
	_update_movement_feedback(movement_direction, distance_moved)
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
		_reset_movement_feedback()
	_emit_current_prompt()


func _update_movement_feedback(movement_direction: Vector2, distance_moved: float) -> void:
	if not _controls_enabled or distance_moved <= 0.01:
		_reset_movement_feedback()
		return

	_facing_name = _get_facing_name(movement_direction)
	_play_movement_animation(&"walk")
	animated_sprite.speed_scale = clampf(velocity.length() / speed, 0.65, 1.15)

	_walk_cycle_distance += distance_moved
	if _walk_cycle_distance >= step_distance:
		_walk_cycle_distance = fposmod(_walk_cycle_distance, step_distance)
		_step_side *= -1.0
		_spawn_step_dust(movement_direction)

	var cycle_progress: float = _walk_cycle_distance / step_distance
	var is_foot_lifted: bool = cycle_progress >= 0.12 and cycle_progress < 0.58
	var bob_offset: float = -walk_bob_pixels if is_foot_lifted else 0.0
	var sway_offset: float = _step_side * walk_sway_pixels if is_foot_lifted else 0.0
	animated_sprite.position = _sprite_rest_position + Vector2(sway_offset, bob_offset)
	shadow.scale = _shadow_rest_scale * (Vector2(0.84, 0.78) if is_foot_lifted else Vector2.ONE)


func _reset_movement_feedback() -> void:
	_walk_cycle_distance = 0.0
	animated_sprite.position = _sprite_rest_position
	animated_sprite.speed_scale = 1.0
	shadow.scale = _shadow_rest_scale
	_play_movement_animation(&"idle")


func _get_facing_name(movement_direction: Vector2) -> StringName:
	if absf(movement_direction.x) > absf(movement_direction.y):
		return &"left" if movement_direction.x < 0.0 else &"right"
	return &"up" if movement_direction.y < 0.0 else &"down"


func _play_movement_animation(state_name: StringName) -> void:
	var animation_name: StringName = StringName("%s_%s" % [state_name, _facing_name])
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)


func _spawn_step_dust(movement_direction: Vector2) -> void:
	var dust_parent: Node = get_parent()
	if dust_parent == null:
		return

	var dust: Polygon2D = Polygon2D.new()
	dust.name = "StepDust"
	dust.polygon = PackedVector2Array([
		Vector2(-1.0, 0.0),
		Vector2(0.0, -1.0),
		Vector2(1.0, 0.0),
		Vector2(0.0, 1.0),
	])
	dust.color = step_dust_color
	dust.z_index = -1
	dust.add_to_group(&"step_dust")
	dust_parent.add_child(dust)

	var side_direction: Vector2 = Vector2(-movement_direction.y, movement_direction.x)
	var start_position: Vector2 = footstep_origin.global_position + side_direction * _step_side * 2.0
	dust.global_position = start_position
	var drift: Vector2 = -movement_direction * 3.0 + Vector2(0.0, -2.0)
	var tween: Tween = dust.create_tween().set_parallel()
	tween.tween_property(dust, "global_position", start_position + drift, 0.24).set_trans(Tween.TRANS_SINE)
	tween.tween_property(dust, "modulate:a", 0.0, 0.24)
	tween.finished.connect(dust.queue_free)
	step_taken.emit(start_position)


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
