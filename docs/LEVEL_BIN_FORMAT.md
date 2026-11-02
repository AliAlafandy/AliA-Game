# AliA-Game Level.bin format

Each stage can contain `assets/levels/<StageName>/Level.bin`. The file is read by `data.backend.LevelBin` when `PlayState` starts.

The BIN root must be an object with these fields:

- `name`: stage name (string)
- `player`: object with `x` and `y` spawn coordinates (integers)
- `backgrounds`: array of objects with `image`, `x`, `y`, `scrollX`, and `scrollY`
- `flashes`: array of collectible objects with `x`, `y`, and `value`

Background image paths are relative to the game's image assets and omit the `.png` extension. Parallax values are thousandths: 1000 means normal camera movement, 350 means 0.35x movement, and 0 means fixed to the screen.

Example data to encode as BIN:

```text
{
  name: "ATown",
  player: { x: 160, y: 420 },
  backgrounds: [
    { image: "levels/ATown/background", x: 0, y: 0, scrollX: 350, scrollY: 350 }
  ],
  flashes: [
    { x: 420, y: 380, value: 1 },
    { x: 520, y: 380, value: 5 }
  ]
}
```

The example is a human-readable representation of the object; save it using the project's `bin.BIN` writer, not as plain text with a `.bin` extension. The editor's existing tile-grid BIN is a separate format and is not a PlayState stage file.

If `Level.bin` is missing or invalid, PlayState keeps its generated fallback background and default player spawn.
