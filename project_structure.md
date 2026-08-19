# Star Keeper — Cấu trúc dự án

## 1. Cây thư mục

```text
res://
├── project.godot
├── export_presets.cfg
├── README.md
├── project.md
├── project_structure.md
├── ASSET_CREDITS.md
├── icon.svg
├── assets/
│   ├── buildings/
│   │   └── observatory/
│   │       └── observatory_house.png
│   ├── characters/
│   │   └── player/
│   │       └── keeper_walk_*.png
│   ├── environment/
│   │   ├── fences/
│   │   │   ├── fence_wood.png
│   │   │   └── fence_post.png
│   │   ├── foliage/
│   │   │   ├── flower_patch_*.png
│   │   │   ├── grass_tuft_*.png
│   │   │   └── sign_front.png
│   │   ├── rocks/
│   │   │   └── rock_*.png
│   │   └── trees/
│   │       ├── tree_*.png
│   │       └── dead_tree.png
│   └── objects/
│       ├── decorations/
│       │   ├── flower_pot.png
│       │   └── wooden_crate.png
│       ├── furniture/
│       │   ├── bench_cozy.png
│       │   └── lamp_post.png
│       └── telescope/
│           └── telescope.png
├── resources/
│   ├── player/
│   │   └── keeper_sprite_frames.tres
│   └── shaders/
│       ├── water_pond.gdshader
│       └── wind_sway.gdshader
├── scenes/
│   ├── world/
│   │   └── world.tscn
│   ├── player/
│   │   └── player.tscn
│   ├── objects/
│   │   ├── bench.tscn
│   │   └── telescope.tscn
│   └── ui/
│       ├── hud.tscn
│       ├── observatory_view.tscn
│       └── journal_panel.tscn
├── scripts/
│   ├── world/
│   │   └── world.gd
│   ├── player/
│   │   └── player.gd
│   ├── objects/
│   │   ├── bench.gd
│   │   └── telescope.gd
│   ├── systems/
│   │   ├── celestial_event_manager.gd
│   │   ├── constellation_catalog.gd
│   │   ├── constellation_data.gd
│   │   ├── interactable.gd
│   │   ├── lantern_light.gd
│   │   ├── shooting_star_system.gd
│   │   ├── sound_manager.gd
│   │   └── time_manager.gd
│   └── ui/
│       ├── hud.gd
│       ├── journal_panel.gd
│       └── observatory_view.gd
└── tests/
    └── mvp_smoke_test.gd
```

Godot tạo file `.import` cạnh mỗi ảnh và file `.gd.uid` cạnh mỗi script. Các file này được commit để giữ metadata/UID ổn định. Thư mục `.godot/` là cache cục bộ và bị loại bởi `.gitignore`.

## 2. Quy ước tổ chức

- `scenes/` chỉ chứa scene có thể instantiate.
- `scripts/` chứa logic, chia theo cùng domain với scene.
- `scripts/systems/` chứa lớp nền không thuộc riêng một visual scene.
- `assets/third_party/` chứa asset ngoài kèm giấy phép ngay tại chỗ.
- `tests/` chứa script kiểm thử chạy trực tiếp bằng Godot CLI.
- Không có autoload; state của vertical slice thuộc World hiện tại.
- Scene gọi xuống child; child giao tiếp ngược lên bằng signal.
- Collision và visual là các node riêng để có thể thay artwork độc lập.
- Các node mà `world.gd` truy cập dùng unique name (`%Player`, `%HUD`, ...).

## 3. Main scene: World

File: `scenes/world/world.tscn`

Script: `scripts/world/world.gd`

```text
World (Node2D, StarKeeperWorld)
├── GroundVisuals
│   ├── GroundBase / MeadowPatches / DistantGrass
│   ├── HousePorchDeck / CobblestoneMainPath
│   ├── ObservatoryStarPlaza
│   ├── MoonlightPond (water shader + lily pads)
│   ├── WoodenPicketFence
│   └── PixelDetails
│       ├── FlowersLeftA ... FlowersRightB
│       └── GrassA ... GrassF
├── Boundaries
│   ├── Top / Bottom / Left / Right (StaticBody2D)
│   └── MoonlightPond (StaticBody2D)
├── WorldContent (y-sort)
│   ├── ObservatoryHouse (StaticBody2D)
│   ├── Tree* / Rock* / DeadTreeSouth (StaticBody2D)
│   ├── TelescopeSign / Bench / Telescope
│   ├── LeafParticles / Fireflies
│   ├── ObservatoryHouseLantern / HouseWindowLight / TelescopeLantern
│   └── Player
│       └── PlayerLantern
├── WorldEnvironment
├── EnvironmentTint (CanvasModulate)
├── TimeManager
├── CelestialEventManager
└── Interface (CanvasLayer)
    ├── HUD (instanced scene)
    ├── ObservatoryView (instanced scene)
    └── JournalPanel (instanced scene)
```

### Trách nhiệm

`StarKeeperWorld` là coordinator:

- Nối signal khi `_ready()`.
- Chuyển trạng thái gameplay sang Observatory View.
- Kiểm tra khung giờ ban đêm trước khi mở kính thiên văn.
- Khóa/mở điều khiển Player và đồng bộ trạng thái ngồi ở Bench.
- Ẩn/hiện HUD.
- Nhận thời gian và áp màu lên `CanvasModulate`.
- Cập nhật lantern, fireflies và sự kiện thiên văn theo giờ.
- Cấp cùng một `ConstellationCatalog` cho Observatory View và Journal.
- Chuyển các sự kiện gameplay thành notification và âm thanh procedural.

World không tự tính thời gian, không đọc input di chuyển và không tạo sao. Mỗi việc đó thuộc về component chuyên trách.

## 4. Player scene

File: `scenes/player/player.tscn`

Script: `scripts/player/player.gd`

```text
Player (CharacterBody2D)
├── Visual
│   ├── Shadow (Polygon2D)
│   └── AnimatedSprite2D
├── CollisionShape2D
├── FootstepOrigin (Marker2D)
├── Camera2D
└── InteractionArea (Area2D)
    └── CollisionShape2D
```

### Trách nhiệm

- Đọc các action `move_*` trong `_physics_process()`.
- Dùng acceleration/deceleration để đưa velocity tới vận tốc mục tiêu, sau đó gọi `move_and_slide()`.
- Dùng quãng đường di chuyển thực tế để điều khiển nhịp bob/sway, co bóng và tạo step dust.
- Chọn `idle_*` hoặc `walk_*` theo hướng di chuyển trội và đồng bộ tốc độ animation với velocity.
- Phát `step_taken` tại `FootstepOrigin`; World chuyển signal này thành âm thanh bước chân mà không ghép audio vào movement logic.
- Theo dõi `Interactable` đi vào/rời `InteractionArea`.
- Chọn interactable gần nhất bằng khoảng cách bình phương.
- Gọi `interact(self)` khi nhận action `interact`.
- Phát `interaction_prompt_changed` khi mục tiêu hoặc nội dung prompt thay đổi.
- `set_sitting()` đặt Player vào SitMarker, giữ input tương tác nhưng khóa movement cho tới khi đứng dậy.

Player không tham chiếu HUD, Telescope hoặc Observatory View.

## 5. Interaction system và Telescope

### Lớp cơ sở

File: `scripts/systems/interactable.gd`

```text
Interactable (Area2D)
├── prompt_text: String
└── interact(player: Node2D)
```

Đây là contract tối thiểu cho mọi vật thể tương tác. Lớp con override `interact()` và nên phát signal thay vì tự điều phối World.

### Telescope

Files:

- `scenes/objects/telescope.tscn`
- `scripts/objects/telescope.gd`

```text
Telescope (Area2D, Interactable)
├── InteractionShape
├── Visual
│   └── Polygon2D placeholders
└── SolidBody (StaticBody2D)
    └── CollisionShape2D
```

`Telescope.interact()` chỉ phát `observatory_requested`. World nhận signal, kiểm tra `TimeManager.is_night_time()` rồi mới thực hiện chuyển trạng thái UI/gameplay.

### Bench

Files:

- `scenes/objects/bench.tscn`
- `scripts/objects/bench.gd`

Bench chứa visual/collision riêng và một `SitMarker`. `interact()` đổi prompt, phát `sitting_state_changed`; World gọi `Player.set_sitting()` và Player vẫn nhận `E` để đứng dậy.

## 6. TimeManager

File: `scripts/systems/time_manager.gd`

`TimeManager` là `Node` nằm trực tiếp trong World, không phải singleton.

### Dữ liệu export

| Thuộc tính | Mặc định | Công dụng |
| --- | --- | --- |
| `day_duration_seconds` | `150.0` | Thời gian thực của một chu kỳ 24 giờ |
| `starting_hour` | `8.0` | Giờ bắt đầu |
| `starting_day` | `1` | Ngày bắt đầu |
| `night_start_hour` | `19.0` | Bắt đầu cho phép dùng Telescope |
| `night_end_hour` | `5.0` | Kết thúc khung giờ quan sát |
| `environment_gradient` | Resource trong World | Ánh xạ giờ sang màu môi trường |

Mỗi frame, manager cập nhật `_current_hour`, sau đó phát:

```gdscript
time_changed(time_text: String, environment_color: Color)
day_changed(day_number: int, day_text: String)
```

HUD không tự tính giờ và World không tự sample Gradient. Khi `_current_hour` vượt 24:00, manager tăng `_current_day` rồi cập nhật `DayLabel` qua signal.

## 7. UI scenes

### HUD

Files:

- `scenes/ui/hud.tscn`
- `scripts/ui/hud.gd`

```text
HUD (Control)
├── TimePanel
│   └── Margin
│       └── Labels
│           ├── DayLabel
│           └── TimeLabel
├── InteractionPanel
│   └── PromptLabel
├── NotificationLabel
└── JournalHint
```

HUD là view thụ động. Nó nhận ngày/giờ, prompt và notification từ World; HUD không đọc gameplay state trực tiếp.

### Observatory View

Files:

- `scenes/ui/observatory_view.tscn`
- `scripts/ui/observatory_view.gd`

```text
ObservatoryView (Control)
├── NightBackground
├── SkyGlow
├── Stars
├── LinesContainer
├── DistantMountain
├── NearMountain
├── CaptionPanel
├── DiscoveryBanner
└── Runtime children
    ├── NebulaSoft* / Cloud* / StarDust
    ├── ShootingStars
    ├── SelectionRing / PreviewLine
    └── BrassFrame
```

`_build_stars()` dùng `RandomNumberGenerator` với seed cố định để tạo đúng cùng bố cục. Chuột được nhận ở `_gui_input()` của root `Control`; `Escape` được nhận ở `_unhandled_input()`. Cạnh hợp lệ được lưu trong `_drawn_edges`; khi đủ cạnh, catalog đánh dấu chòm sao đã khám phá và phát `constellation_discovered`.

### Journal Panel

```text
JournalPanel (Control)
├── Dimmer
└── Panel
    └── Content (VBoxContainer)
        ├── Title / Separator
        ├── EntriesScroll (ScrollContainer)
        │   └── EntriesContainer
        ├── ProgressLabel
        └── CloseHint
```

Journal dùng cùng `ConstellationCatalog` với Observatory View. Sáu entry được tạo lại khi mở; `ScrollContainer` giữ toàn bộ manh mối trong panel 400 × 300 mà không tràn khỏi viewport.

## 8. Luồng signal chính

### Prompt tương tác

```text
InteractionArea phát hiện Telescope
→ Player chọn mục tiêu gần nhất
→ Player.interaction_prompt_changed
→ World nối signal tới HUD.set_interaction_prompt
```

### Mở Observatory View

```text
Người chơi nhấn E
→ Player gọi Telescope.interact(player)
→ Telescope.observatory_requested
→ World kiểm tra thời gian từ 19:00 đến trước 05:00
→ World khóa Player
→ World ẩn HUD
→ World gọi ObservatoryView.open_view()
```

### Đóng Observatory View

```text
Người chơi nhấn Escape
→ ObservatoryView.close_view()
→ ObservatoryView.closed
→ World hiện HUD
→ World mở lại điều khiển Player
```

### Cập nhật thời gian

```text
TimeManager cập nhật giờ
→ time_changed(HH:MM, Color)
→ World cập nhật HUD
→ World cập nhật EnvironmentTint
→ World cập nhật Lanterns, Fireflies và CelestialEventManager
```

### Ngồi ghế

```text
Player gọi Bench.interact(player)
→ Bench đổi prompt và phát sitting_state_changed
→ World gọi Player.set_sitting(...)
→ Player khóa movement nhưng vẫn nhận E để đứng dậy
```

### Journal

```text
Người chơi nhấn J
→ World khóa Player và ẩn HUD
→ JournalPanel đọc catalog, tạo 6 entry trong EntriesScroll
→ J hoặc Escape phát JournalPanel.closed
→ World khôi phục HUD và điều khiển Player
```

## 9. Vai trò từng file code

| File | `class_name` | Trách nhiệm |
| --- | --- | --- |
| `scripts/world/world.gd` | `StarKeeperWorld` | Điều phối các component của main scene |
| `scripts/player/player.gd` | `Player` | Di chuyển, animation, collision và tìm interactable |
| `scripts/objects/bench.gd` | `Bench` | Vật thể tương tác Băng ghế cho phép ngồi nghỉ ngơi |
| `scripts/objects/telescope.gd` | `Telescope` | Chuyển tương tác Telescope thành signal |
| `scripts/systems/celestial_event_manager.gd` | `CelestialEventManager` | Quản lý sự kiện thiên văn ngẫu nhiên mỗi đêm (Đêm quang đãng / Mưa sao băng) |
| `scripts/systems/constellation_data.gd` | `ConstellationData` | Resource định nghĩa cấu trúc, bài thơ gợi ý và kết nối chòm sao |
| `scripts/systems/constellation_catalog.gd` | `ConstellationCatalog` | Quản lý 6 chòm sao cổ đại và logic nối sao |
| `scripts/systems/lantern_light.gd` | `LanternLight` | Đèn lồng PointLight2D bật tắt theo giờ và lập lòe tự nhiên |
| `scripts/systems/shooting_star_system.gd` | `ShootingStarSystem` | Hệ thống sinh sao băng ngẫu nhiên và hiệu ứng vệt sáng mờ dần |
| `scripts/systems/sound_manager.gd` | `SoundManager` | Bộ tổng hợp âm thanh procedural (chuông ngũ âm, hợp âm khải hoàn, bước chân) |
| `scripts/systems/time_manager.gd` | `TimeManager` | Đồng hồ 24 giờ, màu môi trường và kiểm tra ban đêm |
| `scripts/ui/hud.gd` | `HUD` | Hiển thị thời gian, prompt, toast thông báo và gợi ý phím |
| `scripts/ui/journal_panel.gd` | `JournalPanel` | Sổ nhật ký ghi chép 6 chòm sao kèm manh mối thơ ca |
| `scripts/ui/observatory_view.gd` | `ObservatoryView` | Overlay bầu trời, dải Ngân Hà, mây trôi, tạo sao, nối sao và hiệu ứng khám phá |
| `tests/mvp_smoke_test.gd` | — | Kiểm tra end-to-end bằng `SceneTree` |




## 10. Thêm một interactable mới

1. Tạo scene có root kế thừa `Interactable` hoặc `Area2D` gắn script kế thừa `Interactable`.
2. Đặt `collision_layer = 4`, tương ứng physics layer số 3 (`interactable`).
3. Thêm `CollisionShape2D` cho vùng phát hiện.
4. Override `interact(player)`.
5. Phát một signal mô tả ý định, ví dụ `journal_requested`.
6. Instance scene trong World.
7. Để World nối signal và điều phối UI/game state.

Không thêm tham chiếu trực tiếp từ interactable sang HUD hoặc đổi main scene bên trong interactable.

## 11. Thêm artwork mới

1. Xác nhận giấy phép và quyền redistribution.
2. Đặt asset tự tạo trong một thư mục con phù hợp của `assets/`.
3. Với asset ngoài, dùng `assets/third_party/<pack_name>/` và lưu license cạnh asset.
4. Giữ kích thước theo lưới pixel; ưu tiên scale nguyên.
5. Để project dùng nearest filter mặc định.
6. Thay node visual (`Sprite2D`, `AnimatedSprite2D`) mà không sửa collision nếu gameplay footprint không đổi.
7. Chạy import headless và smoke test trước khi commit.

## 12. Testing và version control

`tests/mvp_smoke_test.gd` instantiate World rồi mô phỏng keyboard và mouse input để kiểm tra toàn bộ luồng. Test thực sự click các star qua `_gui_input()`, khám phá The Beacon, kiểm tra Journal scroll/progress, trạng thái ngồi, collision hồ, ngày/đêm, lighting và graphics nodes. Ở display driver headless, test bỏ qua screenshot vì dummy renderer không tạo texture; các assertion gameplay vẫn chạy đầy đủ. Trước khi thoát, test giải phóng World để không để lại `ObjectDB` leak.

Các file nên commit:

- `project.godot`
- `export_presets.cfg`
- `.tscn`, `.tres`, `.gd`
- `.gd.uid`
- Asset nguồn và `.import`
- License/credits
- Test và tài liệu

Các file không commit:

- `.godot/`
- `build/`
- Screenshot smoke test nằm trong `.godot/`
- Build/export tạm thời
