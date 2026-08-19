# Star Keeper

A small pixel-art Godot 4.7 prototype about a keeper exploring an observatory and watching the night sky.

## Run

Open `project.godot` with Godot 4.7.x and run the main scene.

## Windows build

With the Godot 4.7.1 Windows export templates installed:

```powershell
godot --headless --import --path .
godot --headless --path . --export-release "Windows Desktop" build/windows/StarKeeper.exe
```

The preset embeds the project data into a single `StarKeeper.exe`. Build output is ignored by Git.

## Controls

- `WASD`: move
- `E`: interact with the telescope or bench
- `J`: open/close the constellation journal
- `Left mouse`: select and connect stars
- `Right mouse`: cancel the selected star
- `Escape`: close the observatory view or journal

## Current vertical slice

- Player movement, collision and camera
- Four-direction walk animations with acceleration and step feedback
- Reusable interaction system
- Night-gated telescope observatory overlay
- Six discoverable constellations and a scrollable journal
- Continuous multi-day clock, environment tint and celestial events
- Deterministic twinkling star field with shooting stars
- Dynamic lanterns, glow, wind/water shaders and procedural audio
- Bench sitting state and collidable moonlight pond
- Pixel-art assets with nearest-neighbor integer scaling

Third-party art and licensing details are listed in [CREDITS.md](CREDITS.md).

## Documentation

- [Project overview and technical specification](project.md)
- [Project structure and component responsibilities](project_structure.md)
