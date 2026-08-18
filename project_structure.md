# Star Keeper — Cấu trúc dự án

## 1. Cây thư mục

```text
res://
├── project.godot
├── README.md
├── project.md
├── project_structure.md
├── CREDITS.md
├── icon.svg
├── assets/
│   └── third_party/
│       ├── cozy_asset_pack/
│       │   ├── LICENSE.txt
│       │   └── environment/
│       │       ├── observatory_house.png
│       │       ├── tree_*.png
│       │       ├── rock_*.png
│       │       ├── grass_tuft_*.png
│       │       ├── flower_patch_*.png
│       │       ├── dead_tree.png
│       │       └── sign_front.png
│       └── julia_character/
│           ├── LICENSE.txt
│           └── keeper_walk_*.png
├── resources/
│   └── player/
│       └── keeper_sprite_frames.tres
├── scenes/
│   ├── world/
│   │   └── world.tscn
│   ├── player/
│   │   └── player.tscn
│   ├── objects/
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
│   │   └── telescope.gd
│   ├── systems/
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
- Không có autoload; state của MVP thuộc World hiện tại.
- Scene gọi xuống child; child giao tiếp ngược lên bằng signal.
- Collision và visual là các node riêng để có thể thay artwork độc lập.
- Các node mà `world.gd` truy cập dùng unique name (`%Player`, `%HUD`, ...).

## 3. Main scene: World

File: `scenes/world/world.tscn`

Script: `scripts/world/world.gd`

```text
World (Node2D, StarKeeperWorld)
├── GroundVisuals
│   ├── Ground / DistantGrass
│   ├── MainPath / PathHighlight
│   ├── TopFence / BottomFence / LeftFence / RightFence
│   └── PixelDetails
│       ├── FlowersLeftA ... FlowersRightB
│       └── GrassA ... GrassF
├── Boundaries
│   ├── Top (StaticBody2D)
│   ├── Bottom (StaticBody2D)
│   ├── Left (StaticBody2D)
│   └── Right (StaticBody2D)
├── WorldContent (y-sort)
│   ├── ObservatoryHouse (StaticBody2D)
│   ├── Tree* / Rock* / DeadTreeSouth (StaticBody2D)
│   ├── TelescopeSign
│   ├── Telescope (instanced scene)
│   └── Player (instanced scene)
├── EnvironmentTint (CanvasModulate)
├── TimeManager
└── Interface (CanvasLayer)
    ├── HUD (instanced scene)
    └── ObservatoryView (instanced scene)
```

### Trách nhiệm

`StarKeeperWorld` là coordinator:

- Nối signal khi `_ready()`.
- Chuyển trạng thái gameplay sang Observatory View.
- Khóa/mở điều khiển Player.
- Ẩn/hiện HUD.
- Nhận thời gian và áp màu lên `CanvasModulate`.

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
- Phát `step_taken` tại `FootstepOrigin`, cho phép bổ sung âm thanh mà không ghép audio vào movement logic.
- Theo dõi `Interactable` đi vào/rời `InteractionArea`.
- Chọn interactable gần nhất bằng khoảng cách bình phương.
- Gọi `interact(self)` khi nhận action `interact`.
- Phát `interaction_prompt_changed` khi mục tiêu tương tác thay đổi.

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

`Telescope.interact()` chỉ phát `observatory_requested`. World nhận signal và thực hiện chuyển trạng thái UI/gameplay.

## 6. TimeManager

File: `scripts/systems/time_manager.gd`

`TimeManager` là `Node` nằm trực tiếp trong World, không phải singleton.

### Dữ liệu export

| Thuộc tính | Mặc định | Công dụng |
| --- | --- | --- |
| `day_duration_seconds` | `150.0` | Thời gian thực của một chu kỳ 24 giờ |
| `starting_hour` | `8.0` | Giờ bắt đầu |
| `environment_gradient` | Resource trong World | Ánh xạ giờ sang màu môi trường |

Mỗi frame, manager cập nhật `_current_hour`, sau đó phát:

```gdscript
time_changed(time_text: String, environment_color: Color)
```

HUD không tự tính giờ và World không tự sample Gradient.

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
└── InteractionPanel
    └── PromptLabel
```

HUD là view thụ động. Nó chỉ cung cấp `set_time_text()` và `set_interaction_prompt()`.

### Observatory View

Files:

- `scenes/ui/observatory_view.tscn`
- `scripts/ui/observatory_view.gd`

```text
ObservatoryView (Control)
├── NightBackground
├── SkyGlow
├── Stars
├── DistantMountain
├── NearMountain
└── CaptionPanel
    └── Margin
        └── Text
            ├── Message
            └── ReturnHint
```

`_build_stars()` dùng `RandomNumberGenerator` với seed cố định để tạo đúng cùng bố cục. Khi view ẩn, processing và unhandled input đều được tắt. `open_view()` bật lại chúng; `close_view()` tắt và phát signal `closed`.

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
```

## 9. Vai trò từng file code

| File | `class_name` | Trách nhiệm |
| --- | --- | --- |
| `scripts/world/world.gd` | `StarKeeperWorld` | Điều phối các component của main scene |
| `scripts/player/player.gd` | `Player` | Di chuyển, animation, collision và tìm interactable |
| `scripts/systems/interactable.gd` | `Interactable` | Contract cơ sở cho vật thể tương tác |
| `scripts/objects/telescope.gd` | `Telescope` | Chuyển tương tác Telescope thành signal |
| `scripts/systems/constellation_data.gd` | `ConstellationData` | Resource định nghĩa cấu trúc và kết nối chòm sao |
| `scripts/systems/constellation_catalog.gd` | `ConstellationCatalog` | Quản lý danh mục chòm sao và logic nối sao |
| `scripts/systems/lantern_light.gd` | `LanternLight` | Đèn lồng PointLight2D bật tắt theo giờ và lập lòe tự nhiên |
| `scripts/systems/shooting_star_system.gd` | `ShootingStarSystem` | Hệ thống sinh sao băng ngẫu nhiên và hiệu ứng vệt sáng mờ dần |
| `scripts/systems/sound_manager.gd` | `SoundManager` | Bộ tổng hợp âm thanh procedural (chuông ngũ âm, hợp âm khải hoàn, bước chân) |
| `scripts/systems/time_manager.gd` | `TimeManager` | Đồng hồ 24 giờ, màu môi trường và kiểm tra ban đêm |
| `scripts/ui/hud.gd` | `HUD` | Hiển thị thời gian, prompt, toast thông báo và gợi ý phím |
| `scripts/ui/journal_panel.gd` | `JournalPanel` | Sổ nhật ký ghi chép các chòm sao đã khám phá |
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

`tests/mvp_smoke_test.gd` instantiate World rồi mô phỏng input để kiểm tra toàn bộ luồng. Ở display driver headless, test bỏ qua screenshot vì dummy renderer không tạo texture; các assertion gameplay vẫn chạy đầy đủ.

Các file nên commit:

- `project.godot`
- `.tscn`, `.tres`, `.gd`
- `.gd.uid`
- Asset nguồn và `.import`
- License/credits
- Test và tài liệu

Các file không commit:

- `.godot/`
- Screenshot smoke test nằm trong `.godot/`
- Build/export tạm thời
