class_name ConstellationCatalog
extends RefCounted

## The three starter constellations mapped onto the 24 stars produced by
## ObservatoryView's RNG (seed 7319).  Star indices are 0-based.

var constellations: Array[ConstellationData] = []

## Fast lookup: star_index -> list of ConstellationData that use it.
var _star_to_constellations: Dictionary = {}


func _init() -> void:
	_build_catalog()
	_build_lookup()


## Returns all constellations that contain the given star index.
func get_constellations_for_star(star_index: int) -> Array[ConstellationData]:
	if _star_to_constellations.has(star_index):
		return _star_to_constellations[star_index] as Array[ConstellationData]
	var empty: Array[ConstellationData] = []
	return empty


## Checks whether a specific connection (edge) belongs to any undiscovered
## constellation.  Returns the ConstellationData if the edge is valid,
## or null if it does not belong to any constellation.
func get_constellation_for_edge(idx_a: int, idx_b: int) -> ConstellationData:
	var edge := Vector2i(mini(idx_a, idx_b), maxi(idx_a, idx_b))
	for constellation: ConstellationData in constellations:
		if constellation.discovered:
			continue
		for connection: Vector2i in constellation.connections:
			var normalised := Vector2i(mini(connection.x, connection.y), maxi(connection.x, connection.y))
			if normalised == edge:
				return constellation
	return null


## Checks whether all connections of a constellation have been drawn.
## `drawn_edges` should contain normalised Vector2i (min, max).
func is_constellation_complete(
	constellation: ConstellationData, drawn_edges: Array[Vector2i]
) -> bool:
	for connection: Vector2i in constellation.connections:
		var normalised := Vector2i(mini(connection.x, connection.y), maxi(connection.x, connection.y))
		if not drawn_edges.has(normalised):
			return false
	return true


func get_discovered_count() -> int:
	var count: int = 0
	for constellation: ConstellationData in constellations:
		if constellation.discovered:
			count += 1
	return count


func get_total_count() -> int:
	return constellations.size()


# ── Catalog construction ──────────────────────────────────────────────

func _build_catalog() -> void:
	# The Beacon  (Ngọn Hải Đăng) — a simple triangle, 3 stars
	var beacon := ConstellationData.new()
	beacon.id = "beacon"
	beacon.display_name = "The Beacon"
	beacon.description = "Ngọn Hải Đăng — Kim tự tháp ánh sáng dẫn đường cho những kẻ lạc lối giữa đêm đen."
	beacon.required_star_indices = [2, 7, 11]
	beacon.connections = [Vector2i(2, 7), Vector2i(7, 11), Vector2i(11, 2)]
	constellations.append(beacon)

	# The Little Fox  (Cáo Nhỏ) — a quadrilateral, 4 stars
	var fox := ConstellationData.new()
	fox.id = "little_fox"
	fox.display_name = "The Little Fox"
	fox.description = "Cáo Nhỏ — Chú cáo tinh nghịch chạy ngang bầu trời, tìm kiếm quả mọng rơi từ các vì sao."
	fox.required_star_indices = [0, 5, 14, 19]
	fox.connections = [Vector2i(0, 5), Vector2i(5, 14), Vector2i(14, 19), Vector2i(19, 0)]
	constellations.append(fox)

	# The Crown  (Vương Miện) — a diamond/kite shape, 4 stars
	var crown := ConstellationData.new()
	crown.id = "crown"
	crown.display_name = "The Crown"
	crown.description = "Vương Miện — Vương miện bị mất của vị vua cổ đại, nay tỏa sáng vĩnh cửu trên bầu trời."
	crown.required_star_indices = [4, 9, 16, 21]
	crown.connections = [Vector2i(4, 9), Vector2i(9, 16), Vector2i(16, 21), Vector2i(21, 4)]
	constellations.append(crown)


func _build_lookup() -> void:
	_star_to_constellations.clear()
	for constellation: ConstellationData in constellations:
		for star_index: int in constellation.required_star_indices:
			if not _star_to_constellations.has(star_index):
				var list: Array[ConstellationData] = []
				_star_to_constellations[star_index] = list
			(_star_to_constellations[star_index] as Array[ConstellationData]).append(constellation)
