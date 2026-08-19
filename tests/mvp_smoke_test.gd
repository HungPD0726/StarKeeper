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
	var bench: Bench = world.get_node("WorldContent/Bench") as Bench

	_check_project_settings()
	_check_required_inputs()
	_check(player != null, "Player scene is missing")
	_check(telescope != null, "Telescope scene is missing")
	_check(hud != null, "HUD scene is missing")
	_check(observatory != null, "Observatory view is missing")
	_check(journal != null, "Journal panel is missing")
	_check(bench != null, "Bench interactable is missing")
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

	# Exercise the real Control mouse-input route by discovering The Beacon.
	var catalog: ConstellationCatalog = observatory.get_catalog()
	_check(catalog.get_total_count() == 6, "Expected 6 constellations in catalog")
	_check(catalog.get_discovered_count() == 0, "No constellations should be discovered at start")
	var beacon: ConstellationData = catalog.constellations[0]
	for connection: Vector2i in beacon.connections:
		await _click_observatory_star(observatory, connection.x)
		await _click_observatory_star(observatory, connection.y)
	_check(beacon.discovered, "Mouse clicks did not discover The Beacon constellation")
	_check(catalog.get_discovered_count() == 1, "Discovery count did not update after mouse input")

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
	_check(catalog != null, "Constellation catalog is null")
	_check(catalog.get_discovered_count() == 1, "The Beacon discovery was not retained")
	_check(not catalog.constellations[0].poem_hint.is_empty(), "Constellation 0 is missing poem_hint")
	_check(not catalog.constellations[3].poem_hint.is_empty(), "Constellation 3 is missing poem_hint")

	# Check edge validation
	var new_valid_edge: ConstellationData = catalog.get_constellation_for_edge(1, 6)
	_check(new_valid_edge != null, "Edge (1,6) should belong to The Hourglass constellation")
	var invalid_edge: ConstellationData = catalog.get_constellation_for_edge(0, 1)
	_check(invalid_edge == null, "Edge (0,1) should not belong to any constellation")

	# ── Journal test ──────────────────────────────────────────────────
	_check(not journal.visible, "Journal should be hidden at start")
	await _send_action("journal")
	await _wait_physics_frames(2)
	_check(journal.visible, "Journal did not open on J key press")
	var entries_scroll: ScrollContainer = journal.get_node("Panel/Margin/Content/EntriesScroll") as ScrollContainer
	var entries: VBoxContainer = journal.get_node("%EntriesContainer") as VBoxContainer
	_check(entries_scroll != null, "Journal entries are not inside a ScrollContainer")
	_check(entries.get_child_count() == 6, "Journal did not build all 6 constellation entries")
	var journal_scrollbar: VScrollBar = entries_scroll.get_v_scroll_bar()
	_check(
		journal_scrollbar.max_value > journal_scrollbar.page,
		"Journal content does not expose a usable vertical scroll range"
	)
	_check(
		(journal.get_node("%ProgressLabel") as Label).text == "Tiến độ: 1 / 6 chòm sao",
		"Journal discovery progress is incorrect"
	)
	await _capture_view("res://.godot/star_keeper_journal.png")
	# Close via ESC
	await _send_action("cancel")
	await _wait_physics_frames(2)
	_check(not journal.visible, "Journal did not close on ESC (cancel) key press")
	_check(hud.visible, "HUD was not restored after closing Journal via ESC")

	# ── Bench sitting and dynamic prompt test ─────────────────────────
	player.global_position = bench.global_position + Vector2(0.0, 22.0)
	await _wait_physics_frames(3)
	_check(interaction_panel.visible, "Interaction prompt did not appear near Bench")
	await _send_action("interact")
	_check(player.is_sitting(), "Bench interaction did not put Player into sitting state")
	_check(
		player.global_position.is_equal_approx(bench.get_sit_position()),
		"Player did not move to the Bench sit marker"
	)
	_check(prompt_label.text == "Nhấn E để đứng dậy", "Bench prompt did not update after sitting")
	var sitting_position: Vector2 = player.global_position
	Input.action_press("move_right")
	await _wait_physics_frames(12)
	Input.action_release("move_right")
	_check(player.global_position.is_equal_approx(sitting_position), "Player moved while sitting")
	await _send_action("interact")
	_check(not player.is_sitting(), "Second Bench interaction did not stand Player up")
	_check(prompt_label.text == "Nhấn E để ngồi nghỉ ngơi", "Bench prompt did not reset after standing")
	Input.action_press("move_right")
	await _wait_physics_frames(8)
	Input.action_release("move_right")
	_check(player.global_position.x > sitting_position.x, "Player movement did not resume after standing")

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

	# ── Phase 2 & 3: Atmosphere, Events & Environment test ───────────
	var sound_mgr: SoundManager = world.get_node("SoundManager") as SoundManager
	_check(sound_mgr != null, "SoundManager node is missing")

	var celestial_mgr: CelestialEventManager = world.get_node("CelestialEventManager") as CelestialEventManager
	_check(celestial_mgr != null, "CelestialEventManager node is missing")

	var leaf_particles: CPUParticles2D = world.get_node("WorldContent/LeafParticles") as CPUParticles2D
	_check(leaf_particles != null, "LeafParticles node is missing")

	# Check new Graphics Overhaul elements
	var star_plaza: Node2D = world.get_node("GroundVisuals/ObservatoryStarPlaza") as Node2D
	_check(star_plaza != null, "ObservatoryStarPlaza node is missing")

	var moonlight_pond: Node2D = world.get_node("GroundVisuals/MoonlightPond") as Node2D
	_check(moonlight_pond != null, "MoonlightPond node is missing")
	var pond_collision: StaticBody2D = world.get_node("Boundaries/MoonlightPond") as StaticBody2D
	_check(pond_collision != null, "MoonlightPond collision body is missing")
	player.global_position = Vector2(105.0, 520.0)
	await _wait_physics_frames(2)
	Input.action_press("move_right")
	await _wait_physics_frames(90)
	Input.action_release("move_right")
	_check(player.global_position.x < 125.0, "Player crossed through the MoonlightPond collision")

	var window_light: PointLight2D = world.get_node("WorldContent/HouseWindowLight") as PointLight2D
	_check(window_light != null, "HouseWindowLight node is missing")

	var house_occluder: LightOccluder2D = world.get_node("WorldContent/ObservatoryHouse/Occluder") as LightOccluder2D
	_check(house_occluder != null, "House LightOccluder2D is missing")

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


func _click_observatory_star(observatory: ObservatoryView, star_index: int) -> void:
	var star: ColorRect = observatory.get_node("Stars/Star%02d" % star_index) as ColorRect
	var viewport_size: Vector2 = root.get_visible_rect().size
	var window_size: Vector2 = Vector2(DisplayServer.window_get_size())
	var star_center: Vector2 = star.global_position + star.size * 0.5
	var click_position: Vector2 = star_center
	if DisplayServer.get_name() != "headless":
		var input_scale: float = minf(window_size.x / viewport_size.x, window_size.y / viewport_size.y)
		var letterbox_offset: Vector2 = (window_size - viewport_size * input_scale) * 0.5
		click_position = letterbox_offset + star_center * input_scale
	var pressed_event: InputEventMouseButton = InputEventMouseButton.new()
	pressed_event.button_index = MOUSE_BUTTON_LEFT
	pressed_event.position = click_position
	pressed_event.global_position = click_position
	pressed_event.pressed = true
	Input.parse_input_event(pressed_event)
	await process_frame

	var released_event: InputEventMouseButton = pressed_event.duplicate() as InputEventMouseButton
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
	var exit_code: int = 0
	if _failures.is_empty():
		print("MVP_SMOKE_TEST: PASS")
	else:
		exit_code = 1
		for failure: String in _failures:
			push_error(failure)
		print("MVP_SMOKE_TEST: FAIL (%d checks)" % _failures.size())

	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	await process_frame
	await process_frame
	quit(exit_code)
