class_name ConstellationCatalog
extends RefCounted

## The 6 starter constellations mapped onto the 24 stars produced by
## ObservatoryView's RNG (seed 7319). Star indices are 0-based (0 to 23).

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
## constellation. Returns the ConstellationData if the edge is valid,
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
	# 1. The Beacon (Ngọn Hải Đăng) — 3 stars
	var beacon := ConstellationData.new()
	beacon.id = "beacon"
	beacon.display_name = "The Beacon"
	beacon.poem_hint = "Ba điểm ngời sáng giữa màn đêm / Dẫn lối thuyền xa tới bến êm."
	beacon.description = "Ngọn Hải Đăng — Kim tự tháp ánh sáng dẫn đường cho những kẻ lạc lối giữa đêm đen."
	beacon.required_star_indices = [2, 7, 11]
	beacon.connections = [Vector2i(2, 7), Vector2i(7, 11), Vector2i(11, 2)]
	constellations.append(beacon)

	# 2. The Little Fox (Cáo Nhỏ) — 4 stars
	var fox := ConstellationData.new()
	fox.id = "little_fox"
	fox.display_name = "The Little Fox"
	fox.poem_hint = "Dáng hình thoăn thoắt lướt ngang mây / Bốn góc chân trời bóng cáo gầy."
	fox.description = "Cáo Nhỏ — Chú cáo tinh nghịch chạy ngang bầu trời, tìm kiếm quả mọng rơi từ các vì sao."
	fox.required_star_indices = [0, 5, 14, 19]
	fox.connections = [Vector2i(0, 5), Vector2i(5, 14), Vector2i(14, 19), Vector2i(19, 0)]
	constellations.append(fox)

	# 3. The Crown (Vương Miện) — 4 stars
	var crown := ConstellationData.new()
	crown.id = "crown"
	crown.display_name = "The Crown"
	crown.poem_hint = "Báu vật vương triều ngự đỉnh cao / Tỏa ánh kim cương lấp lánh sao."
	crown.description = "Vương Miện — Vương miện bị mất của vị vua cổ đại, nay tỏa sáng vĩnh cửu trên bầu trời."
	crown.required_star_indices = [4, 9, 16, 21]
	crown.connections = [Vector2i(4, 9), Vector2i(9, 16), Vector2i(16, 21), Vector2i(21, 4)]
	constellations.append(crown)

	# 4. The Hourglass (Đồng Hồ Cát) — 4 stars
	var hourglass := ConstellationData.new()
	hourglass.id = "hourglass"
	hourglass.display_name = "The Hourglass"
	hourglass.poem_hint = "Hạt cát ngưng đọng giữa tầng không / Đong đếm ngàn thu mối tơ lòng."
	hourglass.description = "Đồng Hồ Cát — Đo đếm từng khắc thời gian vĩnh cửu của vũ trụ, nơi quá khứ và tương lai giao thoa."
	hourglass.required_star_indices = [1, 6, 12, 18]
	hourglass.connections = [Vector2i(1, 6), Vector2i(6, 18), Vector2i(18, 12), Vector2i(12, 1), Vector2i(1, 18)]
	constellations.append(hourglass)

	# 5. The Wanderer's Ship (Thuyền Viễn Xứ) — 5 stars
	var ship := ConstellationData.new()
	ship.id = "wanderers_ship"
	ship.display_name = "The Wanderer's Ship"
	ship.poem_hint = "Cánh buồm vượt sóng biển thiên hà / Rẽ lối nghìn trùng gió cuốn xa."
	ship.description = "Thuyền Viễn Xứ — Con tàu huyền thoại lướt qua dải Ngân Hà, chở theo ước vọng của những kẻ lữ hành."
	ship.required_star_indices = [3, 8, 13, 17, 22]
	ship.connections = [Vector2i(3, 8), Vector2i(8, 13), Vector2i(13, 17), Vector2i(17, 22), Vector2i(22, 3), Vector2i(8, 17)]
	constellations.append(ship)

	# 6. The Northern Feather (Lông Vũ Phương Bắc) — 4 stars
	var feather := ConstellationData.new()
	feather.id = "northern_feather"
	feather.display_name = "The Northern Feather"
	feather.poem_hint = "Chiếc lông chim tuyết rụng lưng trời / Nhẹ nâng giấc mộng giữa ngàn khơi."
	feather.description = "Lông Vũ Phương Bắc — Rơi từ đôi cánh thiên nga tuyết, mang hơi thở băng thanh dịu dàng soi sáng màn đêm."
	feather.required_star_indices = [10, 15, 20, 23]
	feather.connections = [Vector2i(10, 15), Vector2i(15, 20), Vector2i(20, 23), Vector2i(10, 23)]
	constellations.append(feather)


func _build_lookup() -> void:
	_star_to_constellations.clear()
	for constellation: ConstellationData in constellations:
		for star_index: int in constellation.required_star_indices:
			if not _star_to_constellations.has(star_index):
				var list: Array[ConstellationData] = []
				_star_to_constellations[star_index] = list
			(_star_to_constellations[star_index] as Array[ConstellationData]).append(constellation)
