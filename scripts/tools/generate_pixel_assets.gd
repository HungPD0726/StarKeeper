@tool
extends SceneTree

func _init() -> void:
	print("Generating cozy pixel art assets...")
	_generate_telescope()
	_generate_bench()
	_generate_lamp_post()
	_generate_fences()
	_generate_decorations()
	_generate_star_desk()
	print("Asset generation complete!")
	quit()


func _generate_star_desk() -> void:
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var c_wood_dark: Color = Color.hex(0x362214ff)
	var c_wood_mid: Color = Color.hex(0x563820ff)
	var c_wood_light: Color = Color.hex(0x845630ff)
	var c_wood_high: Color = Color.hex(0xb27e48ff)
	var c_paper_base: Color = Color.hex(0xe0d4b8ff)
	var c_paper_ink: Color = Color.hex(0x385478ff)
	var c_paper_gold: Color = Color.hex(0xd4a838ff)
	var c_book_cover: Color = Color.hex(0x6e2428ff)
	var c_book_pages: Color = Color.hex(0xf0e4c8ff)
	var c_mug_clay: Color = Color.hex(0xa85032ff)
	var c_mug_tea: Color = Color.hex(0x5a2e18ff)
	var c_shadow: Color = Color.hex(0x181c2460)

	# 1. Shadow under desk
	for x: int in range(3, 29):
		for y: int in range(24, 30):
			var dx: float = (float(x) - 15.5) / 12.5
			var dy: float = (float(y) - 26.5) / 2.5
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, c_shadow)

	# 2. Desk Legs (4 legs)
	# Back left leg
	for y: int in range(16, 26):
		img.set_pixel(5, y, c_wood_dark)
		img.set_pixel(6, y, c_wood_mid)
	# Back right leg
	for y: int in range(16, 26):
		img.set_pixel(25, y, c_wood_dark)
		img.set_pixel(26, y, c_wood_mid)
	# Front left leg
	for y: int in range(18, 28):
		img.set_pixel(7, y, c_wood_mid)
		img.set_pixel(8, y, c_wood_light)
	# Front right leg
	for y: int in range(18, 28):
		img.set_pixel(23, y, c_wood_mid)
		img.set_pixel(24, y, c_wood_light)

	# 3. Desk Tabletop (y=10..18, x=3..28)
	for x: int in range(3, 29):
		for y: int in range(11, 18):
			img.set_pixel(x, y, c_wood_mid)
	for x: int in range(3, 29):
		img.set_pixel(x, 10, c_wood_high)
		img.set_pixel(x, 11, c_wood_light)
		img.set_pixel(x, 17, c_wood_dark)
		img.set_pixel(x, 18, c_wood_dark)

	# 4. Star Chart Map (rolled parchment in center-left, x=6..18, y=11..16)
	for x: int in range(6, 19):
		for y: int in range(11, 16):
			img.set_pixel(x, y, c_paper_base)
	# Star constellation ink lines & stars
	img.set_pixel(8, 12, c_paper_gold)
	img.set_pixel(11, 14, c_paper_gold)
	img.set_pixel(16, 12, c_paper_gold)
	img.set_pixel(14, 15, c_paper_gold)
	img.set_pixel(9, 13, c_paper_ink)
	img.set_pixel(10, 13, c_paper_ink)
	img.set_pixel(12, 14, c_paper_ink)
	img.set_pixel(13, 15, c_paper_ink)
	img.set_pixel(15, 13, c_paper_ink)

	# 5. Antique Leather Book (right side, x=20..25, y=11..15)
	for x: int in range(20, 26):
		for y: int in range(11, 16):
			img.set_pixel(x, y, c_book_cover)
	img.set_pixel(25, 12, c_book_pages)
	img.set_pixel(25, 13, c_book_pages)
	img.set_pixel(25, 14, c_book_pages)
	# Gold bookmark ribbon
	img.set_pixel(22, 11, c_paper_gold)
	img.set_pixel(22, 12, c_paper_gold)
	img.set_pixel(22, 16, c_paper_gold)

	# 6. Hot Tea Mug (x=4..7, y=8..12)
	for x: int in range(4, 8):
		for y: int in range(9, 13):
			img.set_pixel(x, y, c_mug_clay)
	img.set_pixel(5, 9, c_mug_tea)
	img.set_pixel(6, 9, c_mug_tea)
	# Mug handle
	img.set_pixel(8, 10, c_mug_clay)
	img.set_pixel(8, 11, c_mug_clay)

	img.save_png("res://assets/objects/furniture/star_desk.png")



func _generate_telescope() -> void:
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Color palette
	var c_wood_dark: Color = Color.hex(0x382818ff)
	var c_wood_mid: Color = Color.hex(0x5c4228ff)
	var c_wood_light: Color = Color.hex(0x826038ff)
	var c_brass_dark: Color = Color.hex(0x604618ff)
	var c_brass_mid: Color = Color.hex(0xa47c28ff)
	var c_brass_light: Color = Color.hex(0xe0b240ff)
	var c_brass_shine: Color = Color.hex(0xf8d878ff)
	var c_tube_dark: Color = Color.hex(0x283848ff)
	var c_tube_mid: Color = Color.hex(0x405870ff)
	var c_tube_light: Color = Color.hex(0x608098ff)
	var c_lens_cyan: Color = Color.hex(0x78d0e8ff)
	var c_lens_bright: Color = Color.hex(0xd0f4fcff)
	var c_shadow: Color = Color.hex(0x181c2460)

	# 1. Ground Shadow (ellipse)
	for x: int in range(8, 24):
		for y: int in range(26, 31):
			var dx: float = (float(x) - 15.5) / 7.0
			var dy: float = (float(y) - 28.0) / 2.0
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, c_shadow)

	# 2. Tripod Legs (Wooden legs)
	# Center stand
	for y: int in range(16, 22):
		img.set_pixel(15, y, c_wood_dark)
		img.set_pixel(16, y, c_wood_mid)

	# Left leg
	for i: int in range(8):
		var y: int = 21 + i
		var x: int = 15 - int(float(i) * 0.7)
		img.set_pixel(x, y, c_wood_mid)
		img.set_pixel(x + 1, y, c_wood_light)
		img.set_pixel(x - 1, y, c_wood_dark)

	# Right leg
	for i: int in range(8):
		var y: int = 21 + i
		var x: int = 16 + int(float(i) * 0.7)
		img.set_pixel(x, y, c_wood_mid)
		img.set_pixel(x + 1, y, c_wood_dark)
		img.set_pixel(x - 1, y, c_wood_light)

	# Front middle leg
	for y: int in range(21, 29):
		img.set_pixel(15, y, c_wood_dark)
		img.set_pixel(16, y, c_wood_light)

	# 3. Brass Mount & Azimuth Gear Box
	for x: int in range(13, 19):
		for y: int in range(14, 18):
			img.set_pixel(x, y, c_brass_mid)
	img.set_pixel(14, 14, c_brass_shine)
	img.set_pixel(15, 14, c_brass_light)
	img.set_pixel(16, 14, c_brass_light)
	img.set_pixel(13, 17, c_brass_dark)
	img.set_pixel(14, 17, c_brass_dark)
	img.set_pixel(15, 17, c_brass_dark)
	img.set_pixel(16, 17, c_brass_dark)
	img.set_pixel(17, 17, c_brass_dark)
	img.set_pixel(18, 17, c_brass_dark)

	# 4. Telescope Optical Tube (angled upwards toward upper right ~30 deg)
	# Tube body from (6, 18) to (24, 7)
	for i: int in range(20):
		var t: float = float(i) / 19.0
		var cx: float = lerp(6.0, 25.0, t)
		var cy: float = lerp(17.0, 6.0, t)
		var nx: float = -0.45
		var ny: float = -0.8
		for w: int in range(-2, 3):
			var px: int = int(round(cx + nx * float(w)))
			var py: int = int(round(cy + ny * float(w)))
			if px >= 0 and px < 32 and py >= 0 and py < 32:
				if w == -2:
					img.set_pixel(px, py, c_tube_light)
				elif w == -1:
					img.set_pixel(px, py, c_tube_mid)
				elif w == 0:
					img.set_pixel(px, py, c_brass_mid if (i > 8 and i < 13) else c_tube_mid)
				elif w == 1:
					img.set_pixel(px, py, c_brass_dark if (i > 8 and i < 13) else c_tube_dark)
				else:
					img.set_pixel(px, py, c_tube_dark)

	# Brass decorative rings on tube
	img.set_pixel(12, 13, c_brass_shine)
	img.set_pixel(13, 12, c_brass_light)
	img.set_pixel(18, 10, c_brass_shine)
	img.set_pixel(19, 9, c_brass_light)

	# Eyepiece (bottom left)
	img.set_pixel(5, 18, c_brass_light)
	img.set_pixel(4, 19, c_brass_dark)
	img.set_pixel(4, 20, c_brass_mid)

	# Objective Lens Dew Shield & Glass (top right)
	img.set_pixel(24, 5, c_brass_shine)
	img.set_pixel(25, 5, c_brass_light)
	img.set_pixel(26, 6, c_brass_mid)
	img.set_pixel(26, 7, c_lens_cyan)
	img.set_pixel(25, 6, c_lens_bright)
	img.set_pixel(26, 8, c_brass_dark)

	img.save_png("res://assets/objects/telescope/telescope.png")


func _generate_bench() -> void:
	var img: Image = Image.create(32, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var c_wood_dark: Color = Color.hex(0x422a18ff)
	var c_wood_mid: Color = Color.hex(0x6e4828ff)
	var c_wood_light: Color = Color.hex(0x9a683aff)
	var c_wood_high: Color = Color.hex(0xc0884cff)
	var c_iron_dark: Color = Color.hex(0x22242aff)
	var c_iron_mid: Color = Color.hex(0x3a3e48ff)
	var c_shadow: Color = Color.hex(0x181c2460)

	# Shadow
	for x: int in range(3, 29):
		for y: int in range(17, 23):
			var dx: float = (float(x) - 15.5) / 12.0
			var dy: float = (float(y) - 19.5) / 2.0
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, c_shadow)

	# Cast iron legs
	# Left leg
	for y: int in range(11, 20):
		img.set_pixel(6, y, c_iron_mid)
		img.set_pixel(7, y, c_iron_dark)
	# Right leg
	for y: int in range(11, 20):
		img.set_pixel(24, y, c_iron_mid)
		img.set_pixel(25, y, c_iron_dark)

	# Backrest slats (slat 1: y=4..6, slat 2: y=8..10)
	for x: int in range(4, 28):
		img.set_pixel(x, 4, c_wood_high)
		img.set_pixel(x, 5, c_wood_light)
		img.set_pixel(x, 6, c_wood_dark)

		img.set_pixel(x, 8, c_wood_high)
		img.set_pixel(x, 9, c_wood_light)
		img.set_pixel(x, 10, c_wood_dark)

	# Seat slats (y=12..16)
	for x: int in range(3, 29):
		img.set_pixel(x, 12, c_wood_high)
		img.set_pixel(x, 13, c_wood_light)
		img.set_pixel(x, 14, c_wood_mid)
		img.set_pixel(x, 15, c_wood_dark)

	# Armrests
	for y: int in range(7, 13):
		img.set_pixel(4, y, c_iron_mid)
		img.set_pixel(5, y, c_iron_dark)
		img.set_pixel(26, y, c_iron_mid)
		img.set_pixel(27, y, c_iron_dark)

	img.save_png("res://assets/objects/furniture/bench_cozy.png")


func _generate_lamp_post() -> void:
	var img: Image = Image.create(16, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var c_wood_dark: Color = Color.hex(0x382818ff)
	var c_wood_mid: Color = Color.hex(0x5c4228ff)
	var c_wood_light: Color = Color.hex(0x826038ff)
	var c_iron_dark: Color = Color.hex(0x22242aff)
	var c_iron_mid: Color = Color.hex(0x424652ff)
	var c_glow_yellow: Color = Color.hex(0xffec78ff)
	var c_glow_orange: Color = Color.hex(0xf09c28ff)
	var c_glass: Color = Color.hex(0xfff6c8d0)
	var c_shadow: Color = Color.hex(0x181c2460)

	# Shadow at base
	for x: int in range(5, 12):
		for y: int in range(28, 32):
			img.set_pixel(x, y, c_shadow)

	# Wooden Post (x=7,8, y=10..30)
	for y: int in range(10, 30):
		img.set_pixel(7, y, c_wood_mid)
		img.set_pixel(8, y, c_wood_light)
		img.set_pixel(6, y, c_wood_dark)

	# Post base stone / brackets
	for x: int in range(5, 11):
		img.set_pixel(x, 29, c_wood_dark)
		img.set_pixel(x, 28, c_wood_mid)

	# Iron Arm / Bracket pointing right (x=8..13, y=7..10)
	for x: int in range(7, 13):
		img.set_pixel(x, 8, c_iron_dark)
		img.set_pixel(x, 7, c_iron_mid)
	img.set_pixel(12, 9, c_iron_dark)

	# Hanging Lantern (pos: x=10..14, y=10..18)
	# Lantern Top Cap
	for x: int in range(10, 15):
		img.set_pixel(x, 10, c_iron_dark)
	img.set_pixel(12, 9, c_iron_mid)

	# Glass & Flame
	for y: int in range(11, 16):
		img.set_pixel(10, y, c_iron_dark)
		img.set_pixel(14, y, c_iron_dark)
		img.set_pixel(11, y, c_glass)
		img.set_pixel(12, y, c_glow_yellow)
		img.set_pixel(13, y, c_glow_orange)

	# Lantern Bottom Base
	for x: int in range(10, 15):
		img.set_pixel(x, 16, c_iron_dark)

	img.save_png("res://assets/objects/furniture/lamp_post.png")


func _generate_fences() -> void:
	# 1. Fence Wood Section (32x16)
	var img_fence: Image = Image.create(32, 16, false, Image.FORMAT_RGBA8)
	img_fence.fill(Color(0, 0, 0, 0))

	var c_wood_dark: Color = Color.hex(0x382818ff)
	var c_wood_mid: Color = Color.hex(0x5c4228ff)
	var c_wood_light: Color = Color.hex(0x88643cff)
	var c_wood_high: Color = Color.hex(0xb48854ff)
	var c_shadow: Color = Color.hex(0x181c2450)

	# Horizontal rails (y=6..8 and y=11..13)
	for x: int in range(0, 32):
		img_fence.set_pixel(x, 6, c_wood_high)
		img_fence.set_pixel(x, 7, c_wood_light)
		img_fence.set_pixel(x, 8, c_wood_dark)

		img_fence.set_pixel(x, 11, c_wood_high)
		img_fence.set_pixel(x, 12, c_wood_light)
		img_fence.set_pixel(x, 13, c_wood_dark)

	# Vertical pickets / posts at x=2, x=10, x=18, x=26
	var post_xs: Array[int] = [2, 10, 18, 26]
	for px: int in post_xs:
		# Picket tip
		img_fence.set_pixel(px + 1, 1, c_wood_high)
		img_fence.set_pixel(px, 2, c_wood_light)
		img_fence.set_pixel(px + 1, 2, c_wood_high)
		img_fence.set_pixel(px + 2, 2, c_wood_dark)

		# Picket body
		for y: int in range(3, 16):
			img_fence.set_pixel(px, y, c_wood_light)
			img_fence.set_pixel(px + 1, y, c_wood_mid)
			img_fence.set_pixel(px + 2, y, c_wood_dark)

	img_fence.save_png("res://assets/environment/fences/fence_wood.png")

	# 2. Fence Post (16x16)
	var img_post: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img_post.fill(Color(0, 0, 0, 0))

	# Post shadow
	for x: int in range(4, 12):
		img_post.set_pixel(x, 14, c_shadow)
		img_post.set_pixel(x, 15, c_shadow)

	# Post tip
	img_post.set_pixel(8, 1, c_wood_high)
	img_post.set_pixel(7, 2, c_wood_light)
	img_post.set_pixel(8, 2, c_wood_high)
	img_post.set_pixel(9, 2, c_wood_dark)

	# Post body (x=6..9, y=3..14)
	for y: int in range(3, 15):
		img_post.set_pixel(6, y, c_wood_light)
		img_post.set_pixel(7, y, c_wood_mid)
		img_post.set_pixel(8, y, c_wood_mid)
		img_post.set_pixel(9, y, c_wood_dark)

	img_post.save_png("res://assets/environment/fences/fence_post.png")


func _generate_decorations() -> void:
	# 1. Flower Pot (16x16)
	var img_pot: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img_pot.fill(Color(0, 0, 0, 0))

	var c_clay_dark: Color = Color.hex(0x6c2c18ff)
	var c_clay_mid: Color = Color.hex(0x9c4424ff)
	var c_clay_light: Color = Color.hex(0xcc6436ff)
	var c_leaf_dark: Color = Color.hex(0x224424ff)
	var c_leaf_light: Color = Color.hex(0x4a8c48ff)
	var c_petal_blue: Color = Color.hex(0x6890e0ff)
	var c_petal_star: Color = Color.hex(0xf6e068ff)
	var c_shadow: Color = Color.hex(0x181c2450)

	# Shadow
	for x: int in range(4, 12):
		img_pot.set_pixel(x, 14, c_shadow)
		img_pot.set_pixel(x, 15, c_shadow)

	# Pot body (x=5..10, y=9..13)
	for y: int in range(9, 14):
		var inset: int = 1 if y > 11 else 0
		for x: int in range(5 + inset, 11 - inset):
			if x == 5 + inset:
				img_pot.set_pixel(x, y, c_clay_light)
			elif x == 10 - inset:
				img_pot.set_pixel(x, y, c_clay_dark)
			else:
				img_pot.set_pixel(x, y, c_clay_mid)

	# Pot rim (x=4..11, y=8)
	for x: int in range(4, 12):
		img_pot.set_pixel(x, 8, c_clay_light if x < 7 else (c_clay_mid if x < 10 else c_clay_dark))

	# Foliage & Star Flower (y=3..7)
	img_pot.set_pixel(7, 6, c_leaf_dark)
	img_pot.set_pixel(8, 6, c_leaf_light)
	img_pot.set_pixel(6, 5, c_leaf_light)
	img_pot.set_pixel(9, 5, c_leaf_dark)

	# Flower bloom
	img_pot.set_pixel(7, 4, c_petal_blue)
	img_pot.set_pixel(8, 4, c_petal_blue)
	img_pot.set_pixel(7, 3, c_petal_blue)
	img_pot.set_pixel(8, 3, c_petal_blue)
	img_pot.set_pixel(7, 4, c_petal_star)  # yellow center

	img_pot.save_png("res://assets/objects/decorations/flower_pot.png")

	# 2. Wooden Crate (16x16)
	var img_crate: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img_crate.fill(Color(0, 0, 0, 0))

	var c_wood_dark: Color = Color.hex(0x382818ff)
	var c_wood_mid: Color = Color.hex(0x5c4228ff)
	var c_wood_light: Color = Color.hex(0x88643cff)
	var c_wood_high: Color = Color.hex(0xb48854ff)

	# Shadow
	for x: int in range(2, 14):
		img_crate.set_pixel(x, 14, Color.hex(0x181c2450))
		img_crate.set_pixel(x, 15, Color.hex(0x181c2450))

	# Box fill
	for x: int in range(2, 14):
		for y: int in range(2, 14):
			img_crate.set_pixel(x, y, c_wood_mid)

	# Outer border
	for x: int in range(2, 14):
		img_crate.set_pixel(x, 2, c_wood_high)
		img_crate.set_pixel(x, 13, c_wood_dark)
	for y: int in range(2, 14):
		img_crate.set_pixel(2, y, c_wood_high)
		img_crate.set_pixel(13, y, c_wood_dark)

	# Diagonal cross brace
	for i: int in range(3, 13):
		img_crate.set_pixel(i, i, c_wood_light)
		img_crate.set_pixel(i, 15 - i, c_wood_dark)

	img_crate.save_png("res://assets/objects/decorations/wooden_crate.png")
