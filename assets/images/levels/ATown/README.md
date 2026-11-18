# ATown external stage artwork

Place the stage PNG files in this folder. The level source is
`assets/levels/ATown/ATown.ellawy`; its image paths resolve here through
HaxeFlixel's image asset loader.

Expected image names referenced by the current ATown level:

- `sky.png`
- `sun.png`
- `clouds.png`
- `buildings.png`
- `sidewalk.png`
- `street.png`

These are ordinary PNG assets. Do not put Base64 image data in the Ellawy file
or in a new BIN archive. Mark the `street` layer as `isGround: true` to make
it the single physical ground surface.
