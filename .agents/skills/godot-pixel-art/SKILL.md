---
name: godot-pixel-art
description: >-
  Expert guidelines, architectural patterns, and workflow cheatsheets for developing
  2D Top-Down Pixel Art games in Godot Engine 4.7+. Covers pixel-perfect rendering,
  decoupled node architecture (Call Down, Signal Up), 2D dynamic lighting & glow,
  procedural audio, and automated headless testing.
---

# Godot 4 2D Pixel-Art Development Skill

This skill defines the technical standards, architectural patterns, and best practices for developing and maintaining the **Star Keeper** codebase in Godot 4.7+.

---

## 1. Pixel-Perfect Display & Rendering Guidelines

To prevent pixel distortion, blurriness, or camera jitter:
- **Viewport Dimensions:** Base resolution `640 × 360` (16:9), integer scaled to standard resolutions (e.g. `1280 × 720`, `1920 × 1080`).
- **Texture Filtering:** Default canvas texture filter MUST be `0` (`Nearest`).
- **Stretch Settings:**
  - `stretch/mode = "viewport"`
  - `stretch/aspect = "keep"`
  - `stretch/scale_mode = "integer"`
- **Snapping:** Enable `rendering/2d/snap/snap_2d_transforms_to_pixel = true`.
- **Camera2D:** Keep camera smoothing disabled or carefully clamped to integer pixel boundaries to avoid sub-pixel blurring.

---

## 2. Architecture & Scripting Principles

### 2.1. "Call Down, Signal Up"
- **Parent Nodes:** May directly call methods or modify properties on direct children.
- **Child Nodes:** MUST NEVER directly reference or modify sibling or parent nodes. Children emit signals when internal state changes or requests occur.
- **Scene Coordinator:** The root scene (e.g. `StarKeeperWorld`) coordinates connections between UI, Player, Systems, and Interactables.

### 2.2. Strict Static Typing in GDScript 2.0
Always declare explicit types for properties, function parameters, and return types:
```gdscript
class_name ExampleSystem
extends Node2D

signal status_changed(new_status: String)

@export var duration_seconds: float = 10.0
var _current_timer: float = 0.0


func start_timer(duration: float) -> void:
    _current_timer = duration
```

### 2.3. Node Access & Decoupling
- Prefer Scene Unique Names (`%NodeName`) for nodes accessed by the scene's coordinator script.
- Keep domain logic organized by category in `scripts/`:
  - `scripts/world/`: World coordinators & environment state.
  - `scripts/player/`: Character controller, animation synchronization, interaction detector.
  - `scripts/systems/`: Independent gameplay and data modules (time, catalog, audio, light).
  - `scripts/ui/`: Presentation-only UI layers (passive views receiving data via methods).

---

## 3. Lighting, Glow & Visual Aesthetics

### 3.1. 2D Dynamic Lighting (`PointLight2D`)
- Use `GradientTexture2D` with radial falloff (`fill = 1`) for soft, organic light rings.
- Modulate light intensity and color with natural wave oscillations (`sin()` multi-frequency) to create authentic lantern flicker.
- Group lighting nodes under `lantern_lights` so the coordinator can batch-update them based on `TimeManager`.

### 3.2. WorldEnvironment & HDR Bloom
- Configure `WorldEnvironment` with `glow_enabled = true`, `glow_bloom = 0.15`, `glow_hdr_threshold = 0.95`.
- Assign HDR color values (values > 1.0, e.g. `Color(1.7, 1.4, 0.5, 1.0)`) to glowing celestial objects (stars, discovery lines, fireflies) for neon bloom against the dark sky.

---

## 4. Procedural Audio Synthesis (`SoundManager`)

- When adding interactive sound cues, prefer generating procedural `AudioStreamWAV` buffers using mathematical waveforms (sine waves with exponential decay and harmonic overtones).
- Use musical intervals (such as the Pentatonic scale: `[261.63, 293.66, 329.63, 392.00, 440.00, ...]`) to make user interactions feel harmonious and pleasant.

---

## 5. Automated Headless Smoke Testing

Always verify game state integrity before commits:
1. Re-index global class cache if adding new `class_name` scripts:
   ```powershell
   godot --editor --headless --path . --quit
   ```
2. Execute automated smoke tests:
   ```powershell
   godot --headless --path . --script res://tests/mvp_smoke_test.gd
   ```
3. Test assertions should verify:
   - Node existence and configuration.
   - Input bindings and state machine transitions.
   - Signal connections and state restoration upon closing overlays.
