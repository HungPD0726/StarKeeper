class_name ObservatoryView
extends Control

signal closed
signal constellation_discovered(data: ConstellationData)

@export_range(1, 80, 1) var star_count: int = 24
@export var star_seed: int = 7319

var _elapsed: float = 0.0
var _stars: Array[ColorRect] = []
var _twinkle_speeds: Array[float] = []
var _twinkle_phases: Array[float] = []
var _catalog: ConstellationCatalog

## The star index currently selected (first click). -1 means nothing selected.
var _selected_star_index: int = -1
## Normalised edges drawn so far: Vector2i(min_idx, max_idx).
var _drawn_edges: Array[Vector2i] = []
## Visual Line2D nodes for each drawn edge.
var _drawn_lines: Array[Line2D] = []

## Glow ring shown around the currently selected star.
var _selection_ring: ColorRect
## Temporary line from selected star to mouse cursor.
var _preview_line: Line2D

## Atmosphere layers
var _nebula_blobs: Array[Polygon2D] = []
var _cloud_strips: Array[ColorRect] = []
var _shooting_star_system: ShootingStarSystem
var _sound_manager: SoundManager

@onready var stars_root: Control = %Stars
@onready var lines_container: Control = %LinesContainer
@onready var discovery_banner: PanelContainer = %DiscoveryBanner
@onready var discovery_label: Label = %DiscoveryLabel


func _ready() -> void:
	_catalog = ConstellationCatalog.new()
	_build_nebula()
	_build_clouds()
	_build_stars()
	_build_shooting_stars()
	_build_selection_ring()
	_build_preview_line()
	hide()
	discovery_banner.hide()
	set_process(false)
	set_process_unhandled_input(false)


func _process(delta: float) -> void:
	_elapsed += delta

	# ── Twinkle ──
	for index: int in _stars.size():
		var star: ColorRect = _stars[index]
		var alpha: float = 0.72 + sin(
			_elapsed * _twinkle_speeds[index] + _twinkle_phases[index]
		) * 0.24
		var tint: Color = star.modulate
		tint.a = alpha
		star.modulate = tint

	# ── Nebula subtle breathing ──
	for blob: Polygon2D in _nebula_blobs:
		var breath: float = sin(_elapsed * 0.3 + blob.position.x * 0.01) * 0.04
		blob.modulate.a = 0.12 + breath

	# ── Cloud drift ──
	for cloud: ColorRect in _cloud_strips:
		cloud.position.x -= delta * (8.0 + cloud.position.y * 0.02)
		if cloud.position.x + cloud.size.x < -10.0:
			cloud.position.x = 650.0

	# ── Preview line follows mouse ──
	if _selected_star_index >= 0 and _preview_line.visible:
		_preview_line.set_point_position(1, get_local_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("cancel"):
		close_view()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed:
			if mouse_event.button_index == MOUSE_BUTTON_LEFT:
				_on_left_click(mouse_event.position)
				get_viewport().set_input_as_handled()
			elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
				_cancel_selection()
				get_viewport().set_input_as_handled()


func open_view() -> void:
	show()
	set_process(true)
	set_process_unhandled_input(true)
	_cancel_selection()
	if _shooting_star_system != null:
		_shooting_star_system.set_process(true)


func close_view() -> void:
	hide()
	set_process(false)
	set_process_unhandled_input(false)
	_cancel_selection()
	if _shooting_star_system != null:
		_shooting_star_system.set_process(false)
	closed.emit()


func get_catalog() -> ConstellationCatalog:
	return _catalog


func set_sound_manager(manager: SoundManager) -> void:
	_sound_manager = manager


# ── Atmosphere construction ───────────────────────────────────────────

func _build_nebula() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 4821

	# Create soft glowing nebula blobs behind the stars
	var nebula_configs: Array[Dictionary] = [
		{"pos": Vector2(120, 80), "color": Color(0.25, 0.1, 0.35, 0.12), "scale": 2.2},
		{"pos": Vector2(380, 60), "color": Color(0.1, 0.15, 0.35, 0.10), "scale": 2.8},
		{"pos": Vector2(520, 120), "color": Color(0.2, 0.08, 0.28, 0.09), "scale": 2.0},
		{"pos": Vector2(250, 150), "color": Color(0.12, 0.18, 0.3, 0.08), "scale": 1.6},
	]

	for config: Dictionary in nebula_configs:
		var blob: Polygon2D = Polygon2D.new()
		blob.name = "NebulaSoft"
		# Soft diamond/blob shape
		var s: float = 40.0 * (config["scale"] as float)
		blob.polygon = PackedVector2Array([
			Vector2(0, -s * 0.6),
			Vector2(s * 0.45, -s * 0.2),
			Vector2(s * 0.5, s * 0.1),
			Vector2(s * 0.3, s * 0.5),
			Vector2(0, s * 0.6),
			Vector2(-s * 0.3, s * 0.5),
			Vector2(-s * 0.5, s * 0.1),
			Vector2(-s * 0.45, -s * 0.2),
		])
		blob.color = config["color"] as Color
		blob.position = config["pos"] as Vector2
		blob.z_index = -2
		add_child(blob)
		move_child(blob, 1)  # Place behind stars
		_nebula_blobs.append(blob)


func _build_clouds() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 5512

	for i: int in 5:
		var cloud: ColorRect = ColorRect.new()
		cloud.name = "Cloud%d" % i
		cloud.size = Vector2(
			random.randf_range(80.0, 200.0),
			random.randf_range(3.0, 8.0)
		)
		cloud.position = Vector2(
			random.randf_range(-50.0, 640.0),
			random.randf_range(30.0, 240.0)
		)
		cloud.color = Color(0.15, 0.18, 0.3, random.randf_range(0.03, 0.07))
		cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cloud.z_index = 1
		add_child(cloud)
		_cloud_strips.append(cloud)


func _build_shooting_stars() -> void:
	_shooting_star_system = ShootingStarSystem.new()
	_shooting_star_system.name = "ShootingStars"
	_shooting_star_system.area_size = Vector2(640, 260)
	_shooting_star_system.min_interval = 6.0
	_shooting_star_system.max_interval = 15.0
	_shooting_star_system.set_process(false)
	add_child(_shooting_star_system)


# ── Star construction ─────────────────────────────────────────────────

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

	# Highlight constellation-relevant stars slightly larger
	for constellation: ConstellationData in _catalog.constellations:
		for star_index: int in constellation.required_star_indices:
			if star_index >= 0 and star_index < _stars.size():
				var star: ColorRect = _stars[star_index]
				star.size = Vector2(3, 3)


func _build_selection_ring() -> void:
	_selection_ring = ColorRect.new()
	_selection_ring.name = "SelectionRing"
	_selection_ring.size = Vector2(7, 7)
	_selection_ring.color = Color(0.6, 1.4, 2.2, 0.85)
	_selection_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selection_ring.hide()
	add_child(_selection_ring)


func _build_preview_line() -> void:
	_preview_line = Line2D.new()
	_preview_line.name = "PreviewLine"
	_preview_line.width = 1.0
	_preview_line.default_color = Color(0.7, 1.2, 1.8, 0.5)
	_preview_line.add_point(Vector2.ZERO)
	_preview_line.add_point(Vector2.ZERO)
	_preview_line.hide()
	add_child(_preview_line)


func _get_star_center(index: int) -> Vector2:
	var star: ColorRect = _stars[index]
	return star.position + star.size * 0.5


# ── Click interaction ─────────────────────────────────────────────────

func _on_left_click(click_position: Vector2) -> void:
	var hit_index: int = _find_closest_star(click_position, 12.0)
	if hit_index < 0:
		_cancel_selection()
		return

	if _selected_star_index < 0:
		# First selection
		_select_star(hit_index)
	elif hit_index == _selected_star_index:
		# Clicked same star — deselect
		_cancel_selection()
	else:
		# Second selection — try to draw edge
		_try_draw_edge(_selected_star_index, hit_index)
		_cancel_selection()


func _find_closest_star(click_position: Vector2, max_distance: float) -> int:
	var best_index: int = -1
	var best_dist_sq: float = max_distance * max_distance
	for index: int in _stars.size():
		var center: Vector2 = _get_star_center(index)
		var dist_sq: float = click_position.distance_squared_to(center)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_index = index
	return best_index


func _select_star(index: int) -> void:
	_selected_star_index = index
	var center: Vector2 = _get_star_center(index)
	_selection_ring.position = center - _selection_ring.size * 0.5
	_selection_ring.show()
	_preview_line.set_point_position(0, center)
	_preview_line.set_point_position(1, center)
	_preview_line.show()
	if _sound_manager != null:
		_sound_manager.play_star_click(index)


func _cancel_selection() -> void:
	_selected_star_index = -1
	_selection_ring.hide()
	_preview_line.hide()


func _try_draw_edge(idx_a: int, idx_b: int) -> void:
	var edge := Vector2i(mini(idx_a, idx_b), maxi(idx_a, idx_b))
	# Don't duplicate edges
	if _drawn_edges.has(edge):
		return

	# Check if this edge belongs to any constellation
	var constellation: ConstellationData = _catalog.get_constellation_for_edge(idx_a, idx_b)
	if constellation == null:
		# Invalid edge — small visual flash feedback
		_flash_invalid()
		if _sound_manager != null:
			_sound_manager.play_edge_invalid()
		return

	# Draw the valid edge
	_drawn_edges.append(edge)
	var line: Line2D = _create_edge_line(idx_a, idx_b, Color(0.8, 1.4, 2.2, 0.8))
	_drawn_lines.append(line)
	if _sound_manager != null:
		_sound_manager.play_edge_valid()

	# Check if constellation is now complete
	if _catalog.is_constellation_complete(constellation, _drawn_edges):
		_on_constellation_complete(constellation)


func _create_edge_line(idx_a: int, idx_b: int, line_color: Color) -> Line2D:
	var line: Line2D = Line2D.new()
	line.width = 1.0
	line.default_color = line_color
	line.add_point(_get_star_center(idx_a))
	line.add_point(_get_star_center(idx_b))
	lines_container.add_child(line)

	# Animate line fading in
	line.modulate.a = 0.0
	var tween: Tween = line.create_tween()
	tween.tween_property(line, "modulate:a", 1.0, 0.3)
	return line


func _flash_invalid() -> void:
	# Brief red flash on the selection ring
	var original_color: Color = _selection_ring.color
	_selection_ring.color = Color(1.8, 0.4, 0.4, 0.9)
	var tween: Tween = create_tween()
	tween.tween_property(_selection_ring, "color", original_color, 0.25)


# ── Constellation completion ──────────────────────────────────────────

func _on_constellation_complete(constellation: ConstellationData) -> void:
	constellation.discovered = true

	# Glow up all lines belonging to this constellation
	for connection: Vector2i in constellation.connections:
		var normalised := Vector2i(mini(connection.x, connection.y), maxi(connection.x, connection.y))
		var edge_index: int = _drawn_edges.find(normalised)
		if edge_index >= 0 and edge_index < _drawn_lines.size():
			var line: Line2D = _drawn_lines[edge_index]
			var glow_tween: Tween = line.create_tween()
			glow_tween.tween_property(line, "default_color", Color(1.7, 1.35, 0.4, 1.0), 0.5)
			line.width = 2.0

	# Glow the constellation's stars
	for star_index: int in constellation.required_star_indices:
		if star_index >= 0 and star_index < _stars.size():
			var star: ColorRect = _stars[star_index]
			star.size = Vector2(4, 4)
			star.color = Color(1.7, 1.45, 0.6, 1.0)

	# Sound
	if _sound_manager != null:
		_sound_manager.play_constellation_complete()

	# Show discovery banner
	_show_discovery_banner(constellation.display_name)

	constellation_discovered.emit(constellation)


func _show_discovery_banner(constellation_name: String) -> void:
	discovery_label.text = "✦ Đã khám phá: %s ✦" % constellation_name
	discovery_banner.modulate.a = 0.0
	discovery_banner.show()

	var tween: Tween = create_tween()
	tween.tween_property(discovery_banner, "modulate:a", 1.0, 0.4)
	tween.tween_interval(2.5)
	tween.tween_property(discovery_banner, "modulate:a", 0.0, 0.6)
	tween.tween_callback(discovery_banner.hide)
