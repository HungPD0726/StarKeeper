class_name StarKeeperWorld
extends Node2D

@onready var player: Player = %Player
@onready var telescope: Telescope = %Telescope
@onready var time_manager: TimeManager = %TimeManager
@onready var environment_tint: CanvasModulate = %EnvironmentTint
@onready var hud: HUD = %HUD
@onready var observatory_view: ObservatoryView = %ObservatoryView
@onready var journal_panel: JournalPanel = %JournalPanel

var _sound_manager: SoundManager


func _ready() -> void:
	# Create sound manager
	_sound_manager = SoundManager.new()
	_sound_manager.name = "SoundManager"
	add_child(_sound_manager)

	player.interaction_prompt_changed.connect(hud.set_interaction_prompt)
	telescope.observatory_requested.connect(_open_observatory)
	observatory_view.closed.connect(_on_observatory_closed)
	observatory_view.constellation_discovered.connect(_on_constellation_discovered)
	time_manager.time_changed.connect(_on_time_changed)
	time_manager.day_changed.connect(_on_day_changed)
	hud.set_day_text(time_manager.get_day_text())
	_on_time_changed(time_manager.get_time_text(), time_manager.get_environment_color())

	# Setup observatory with sound manager
	observatory_view.set_sound_manager(_sound_manager)

	# Setup journal with the catalog from observatory
	journal_panel.setup(observatory_view.get_catalog())
	journal_panel.closed.connect(_on_journal_closed)

	# Connect footstep sound
	player.step_taken.connect(_on_step_taken)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		if not observatory_view.visible:
			_toggle_journal()
			get_viewport().set_input_as_handled()


func _open_observatory() -> void:
	if not time_manager.is_night_time():
		hud.show_notification("Trời còn quá sáng để quan sát các vì sao.\nHãy quay lại sau 19:00.")
		return

	player.set_controls_enabled(false)
	hud.hide()
	observatory_view.open_view()


func _on_observatory_closed() -> void:
	observatory_view.hide()
	hud.show()
	player.set_controls_enabled(true)


func _on_time_changed(time_text: String, environment_color: Color) -> void:
	hud.set_time_text(time_text)
	environment_tint.color = environment_color

	var current_hour: float = time_manager.get_current_hour()
	# Update all lanterns in scene
	get_tree().call_group(&"lantern_lights", &"update_time", current_hour)

	# Update fireflies
	var fireflies: CPUParticles2D = get_node_or_null("WorldContent/Fireflies") as CPUParticles2D
	if fireflies != null:
		fireflies.emitting = time_manager.is_night_time()


func _on_day_changed(_day_number: int, day_text: String) -> void:
	hud.set_day_text(day_text)


func _on_constellation_discovered(_data: ConstellationData) -> void:
	# Journal will auto-refresh on next open.
	pass




func _toggle_journal() -> void:
	if journal_panel.visible:
		journal_panel.close_journal()
	else:
		player.set_controls_enabled(false)
		hud.hide()
		journal_panel.open_journal()
		if _sound_manager != null:
			_sound_manager.play_notification()


func _on_journal_closed() -> void:
	hud.show()
	player.set_controls_enabled(true)



func _on_step_taken(_world_position: Vector2) -> void:
	if _sound_manager != null:
		_sound_manager.play_step()
