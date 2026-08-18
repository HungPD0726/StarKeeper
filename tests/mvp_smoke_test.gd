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

	_check_project_settings()
	_check_required_inputs()
	_check(player != null, "Player scene is missing")
	_check(telescope != null, "Telescope scene is missing")
	_check(hud != null, "HUD scene is missing")
	_check(observatory != null, "Observatory view is missing")
	if not _failures.is_empty():
		_finish()
		return

	_check((player.get_node("Camera2D") as Camera2D).enabled, "Player camera is not enabled")
	var player_sprite: AnimatedSprite2D = player.get_node("Visual/AnimatedSprite2D") as AnimatedSprite2D
	_check(player_sprite != null, "Player pixel-art sprite is missing")
	if player_sprite != null:
		_check(player_sprite.sprite_frames.get_frame_count(&"idle") == 8, "Player idle animation does not have 8 frames")
		_check(player_sprite.is_playing(), "Player idle animation is not playing")
	_check(world.get_node("WorldContent/ObservatoryHouse/Sprite2D") is Sprite2D, "Observatory pixel-art sprite is missing")
	_check(observatory.get_node("Stars").get_child_count() == 24, "Sky did not create exactly 24 stars")
	await _capture_view("res://.godot/star_keeper_world.png")

	var initial_tint: Color = environment_tint.color
	player.global_position = Vector2(20.0, 420.0)
	Input.action_press("move_left")
	await _wait_physics_frames(40)
	Input.action_release("move_left")
	_check(player.global_position.x >= 4.5, "Player crossed the left world boundary")
	_check(not environment_tint.color.is_equal_approx(initial_tint), "Day/night tint did not change")

	player.global_position = telescope.global_position + Vector2(0.0, 40.0)
	await _wait_physics_frames(3)
	var interaction_panel: PanelContainer = hud.get_node("InteractionPanel") as PanelContainer
	var prompt_label: Label = interaction_panel.get_node("PromptLabel") as Label
	_check(interaction_panel.visible, "Interaction prompt did not appear near Telescope")
	_check(prompt_label.text == "Press E to interact", "Interaction prompt text is incorrect")
	await _send_action("interact")
	_check(observatory.visible, "Interact did not open Observatory View")
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

	_finish()


func _check_required_inputs() -> void:
	for action: StringName in [
		&"move_up", &"move_down", &"move_left", &"move_right", &"interact", &"cancel"
	]:
		_check(InputMap.has_action(action), "Missing input action: %s" % action)

	_check_physical_key(&"move_up", 87)
	_check_physical_key(&"move_down", 83)
	_check_physical_key(&"move_left", 65)
	_check_physical_key(&"move_right", 68)
	_check_physical_key(&"interact", 69)
	_check_physical_key(&"cancel", 4194305)


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
