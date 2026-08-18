extends SceneTree

const WORLD_SCENE: PackedScene = preload("res://scenes/world/world.tscn")

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var world: StarKeeperWorld = WORLD_SCENE.instantiate() as StarKeeperWorld
	root.add_child(world)
	current_scene = world
	await process_frame
	await physics_frame

	var player: Player = world.get_node("WorldContent/Player") as Player
	var telescope: Telescope = world.get_node("WorldContent/Telescope") as Telescope
	var hud: HUD = world.get_node("Interface/HUD") as HUD
	var observatory: ObservatoryView = world.get_node("Interface/ObservatoryView") as ObservatoryView
	var environment_tint: CanvasModulate = world.get_node("EnvironmentTint") as CanvasModulate
	var time_manager: TimeManager = world.get_node("TimeManager") as TimeManager
	var journal: JournalPanel = world.get_node("Interface/JournalPanel") as JournalPanel

	_check_project_settings()
	_check_required_inputs()
	_check(player != null, "Player scene is missing")
	_check(telescope != null, "Telescope scene is missing")
	_check(hud != null, "HUD scene is missing")
	_check(observatory != null, "Observatory view is missing")
	_check(journal != null, "Journal panel is missing")
	if not _failures.is_empty():
		_finish()
		return

	_check((player.get_node("Camera2D") as Camera2D).enabled, "Player camera is not enabled")
	var player_sprite: AnimatedSprite2D = player.get_node("Visual/AnimatedSprite2D") as AnimatedSprite2D
	_check(player_sprite != null, "Player pixel-art sprite is missing")
	if player_sprite != null:
		for direction: StringName in [&"down", &"left", &"right", &"up"]:
			var idle_animation: StringName = StringName("idle_%s" % direction)
			var walk_animation: StringName = StringName("walk_%s" % direction)
			_check(
				player_sprite.sprite_frames.get_frame_count(idle_animation) == 1,
				"Player is missing idle animation: %s" % idle_animation
			)
			_check(
				player_sprite.sprite_frames.get_frame_count(walk_animation) == 4,
				"Player is missing 4-frame walk animation: %s" % walk_animation
			)
		_check(player_sprite.is_playing(), "Player directional animation is not playing")
	_check(world.get_node("WorldContent/ObservatoryHouse/Sprite2D") is Sprite2D, "Observatory pixel-art sprite is missing")
	_check(observatory.get_node("Stars").get_child_count() == 24, "Sky did not create exactly 24 stars")
	await _capture_view("res://.godot/star_keeper_world.png")

	var step_positions: Array[Vector2] = []
	player.step_taken.connect(
		func(step_position: Vector2) -> void:
			step_positions.append(step_position)
	)
	var sprite_rest_position: Vector2 = player_sprite.position
	player.global_position = Vector2(520.0, 590.0)
	Input.action_press("move_right")
	await _wait_physics_frames(22)
	await _capture_view("res://.godot/star_keeper_movement.png")
	_check(player_sprite.animation == &"walk_right", "Player did not select the right-facing walk animation")
	await _wait_physics_frames(8)
	Input.action_release("move_right")
	_check(not step_positions.is_empty(), "Player movement did not emit a step event")
	await _wait_physics_frames(8)
	_check(player.velocity.is_zero_approx(), "Player did not decelerate to a stop")
	_check(player_sprite.position.is_equal_approx(sprite_rest_position), "Player visual did not return to its rest position")
	_check(player_sprite.animation == &"idle_right", "Player did not keep its facing direction after stopping")

	var initial_tint: Color = environment_tint.color
	player.global_position = Vector2(20.0, 420.0)
	Input.action_press("move_left")
	await _wait_physics_frames(40)
	Input.action_release("move_left")
	_check(player.global_position.x >= 4.5, "Player crossed the left world boundary")
	_check(not environment_tint.color.is_equal_approx(initial_tint), "Day/night tint did not change")

	# ── Night-time gating test ────────────────────────────────────────
	_check(time_manager.is_night_time() == false, "Starting hour 8:00 should be daytime")

	player.global_position = telescope.global_position + Vector2(0.0, 40.0)
	await _wait_physics_frames(3)
	var interaction_panel: PanelContainer = hud.get_node("InteractionPanel") as PanelContainer
	var prompt_label: Label = interaction_panel.get_node("PromptLabel") as Label
	_check(interaction_panel.visible, "Interaction prompt did not appear near Telescope")
	_check(prompt_label.text == "Press E to interact", "Interaction prompt text is incorrect")

	# Interact during daytime — should NOT open observatory
	await _send_action("interact")
	_check(not observatory.visible, "Observatory opened during daytime — night gating failed")
	_check(hud.visible, "HUD was hidden after daytime telescope interaction")

	# Fast-forward to night (set hour to 21:00)
	time_manager._current_hour = 21.0
	time_manager._emit_time_changed()
	_check(time_manager.is_night_time() == true, "Hour 21:00 should be night time")

	# Now interact — should open observatory
	await _send_action("interact")
	_check(observatory.visible, "Interact did not open Observatory View at night")
	_check(not hud.visible, "HUD stayed visible during Observatory View")
	await _capture_view("res://.godot/star_keeper_observatory.png")

	var position_before_locked_input: Vector2 = player.global_position
	Input.action_press("move_right")
	await _wait_physics_frames(15)
	Input.action_release("move_right")
	_check(
		player.global_position.is_equal_approx(position_before_locked_input),
		"Player moved while Observatory View was open"
	)

	await _send_action("cancel")
	_check(not observatory.visible, "Cancel did not close Observatory View")
	_check(hud.visible, "HUD did not return after closing Observatory View")
	_check(
		player.global_position.is_equal_approx(position_before_locked_input),
		"Player position changed while entering or leaving Observatory View"
	)

	Input.action_press("move_right")
	await _wait_physics_frames(10)
	Input.action_release("move_right")
	_check(player.global_position.x > position_before_locked_input.x, "Player controls did not resume")

	# ── Constellation catalog test ────────────────────────────────────
	var catalog: ConstellationCatalog = observatory.get_catalog()
	_check(catalog != null, "Constellation catalog is null")
	_check(catalog.get_total_count() == 3, "Expected 3 constellations in catalog")
	_check(catalog.get_discovered_count() == 0, "No constellations should be discovered at start")

	# Check edge validation
	var valid_edge: ConstellationData = catalog.get_constellation_for_edge(2, 7)
	_check(valid_edge != null, "Edge (2,7) should belong to The Beacon constellation")
	var invalid_edge: ConstellationData = catalog.get_constellation_for_edge(0, 1)
	_check(invalid_edge == null, "Edge (0,1) should not belong to any constellation")

	# ── Journal test ──────────────────────────────────────────────────
	_check(not journal.visible, "Journal should be hidden at start")
	await _send_action("journal")
	await _wait_physics_frames(2)
	_check(journal.visible, "Journal did not open on J key press")
	# Close via ESC
	await _send_action("cancel")
	await _wait_physics_frames(2)
	_check(not journal.visible, "Journal did not close on ESC (cancel) key press")
	_check(hud.visible, "HUD was not restored after closing Journal via ESC")

	# ── Day Progression test ──────────────────────────────────────────
	_check(time_manager.get_day() == 1, "Initial day should be 1")
	# Simulate crossing 24:00 into Day 2
	time_manager._process(150.0)  # advance by 1 full day duration
	_check(time_manager.get_day() == 2, "Day counter did not advance to Day 2")
	_check(hud.get_node("%DayLabel").text == "Day 2", "HUD DayLabel did not update to Day 2")


	# ── Lighting & Glow Environment test ──────────────────────────────
	var world_env: WorldEnvironment = world.get_node("WorldEnvironment") as WorldEnvironment
	_check(world_env != null, "WorldEnvironment node is missing")
	if world_env != null and world_env.environment != null:
		_check(world_env.environment.glow_enabled, "WorldEnvironment Glow is not enabled")

	var house_lantern: LanternLight = world.get_node("WorldContent/ObservatoryHouseLantern") as LanternLight
	_check(house_lantern != null, "Observatory House Lantern is missing")

	var telescope_lantern: LanternLight = world.get_node("WorldContent/TelescopeLantern") as LanternLight
	_check(telescope_lantern != null, "Telescope Lantern is missing")

	var fireflies: CPUParticles2D = world.get_node("WorldContent/Fireflies") as CPUParticles2D
	_check(fireflies != null, "Fireflies particle node is missing")

	# ── Phase 2: Atmosphere & Sound test ──────────────────────────────
	var sound_mgr: SoundManager = world.get_node("SoundManager") as SoundManager
	_check(sound_mgr != null, "SoundManager node is missing")

	# Check observatory atmosphere layers (built at runtime)
	var shooting_stars: ShootingStarSystem = observatory.get_node("ShootingStars") as ShootingStarSystem
	_check(shooting_stars != null, "ShootingStarSystem is missing from ObservatoryView")

	_finish()



func _check_required_inputs() -> void:
	for action: StringName in [
		&"move_up", &"move_down", &"move_left", &"move_right", &"interact", &"cancel", &"journal"
	]:
		_check(InputMap.has_action(action), "Missing input action: %s" % action)

	_check_physical_key(&"move_up", 87)
	_check_physical_key(&"move_down", 83)
	_check_physical_key(&"move_left", 65)
	_check_physical_key(&"move_right", 68)
	_check_physical_key(&"interact", 69)
	_check_physical_key(&"cancel", 4194305)
	_check_physical_key(&"journal", 74)


func _check_project_settings() -> void:
	_check(ProjectSettings.get_setting("display/window/size/viewport_width") == 640, "Viewport width is not 640")
	_check(ProjectSettings.get_setting("display/window/size/viewport_height") == 360, "Viewport height is not 360")
	_check(ProjectSettings.get_setting("display/window/stretch/mode") == "viewport", "Stretch mode is not viewport")
	_check(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep", "Stretch aspect is not keep")
	_check(ProjectSettings.get_setting("display/window/stretch/scale_mode") == "integer", "Stretch scale mode is not integer")
	_check(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter") == 0, "Texture filtering is not nearest")
	_check(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel"), "2D transform snapping is disabled")


func _check_physical_key(action: StringName, expected_keycode: int) -> void:
	var found: bool = false
	for input_event: InputEvent in InputMap.action_get_events(action):
		if input_event is InputEventKey:
			var key_event: InputEventKey = input_event as InputEventKey
			if int(key_event.physical_keycode) == expected_keycode:
				found = true
				break
	_check(found, "Input action %s has the wrong physical key" % action)


func _wait_physics_frames(frame_count: int) -> void:
	for _frame: int in frame_count:
		await physics_frame


func _send_action(action: StringName) -> void:
	var pressed_event: InputEventAction = InputEventAction.new()
	pressed_event.action = action
	pressed_event.pressed = true
	Input.parse_input_event(pressed_event)
	await process_frame

	var released_event: InputEventAction = InputEventAction.new()
	released_event.action = action
	released_event.pressed = false
	Input.parse_input_event(released_event)
	await process_frame


func _capture_view(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("SCREENSHOT_SKIPPED_HEADLESS: %s" % path)
		return

	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	var result: Error = image.save_png(ProjectSettings.globalize_path(path))
	_check(result == OK, "Could not save viewport capture: %s" % path)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("MVP_SMOKE_TEST: PASS")
		quit(0)
		return

	for failure: String in _failures:
		push_error(failure)
	print("MVP_SMOKE_TEST: FAIL (%d checks)" % _failures.size())
	quit(1)
