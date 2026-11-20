# WAR: art style and sprite contract

The look chosen by the owner: **Chronicle** (proposal B of three; the approved pictures are `art/reference/war-battle.png` and `art/reference/war-figures.png`), with the fighting animated.

## The look

Slim, low-resolution soldiers with no outline, in muted wool, iron, leather and wood, lit from the upper left (each
part is lighter on its upper-left edge and darker on its lower-right). Textured earth: grass with grain at two sizes,
darker woods, furrowed fields, a dark stream. Nothing saturated. The two realms are told apart by their cloth and
shields: the Ashen March in slate blue-grey with pale shields, the Fennish Crown in faded madder with ochre shields.

## Scale

- One ground cell is an isometric diamond 16 x 8 pixels. A frame for a man or a rider is 16 x 20, the feet on its
  bottom row. A man is about 6 pixels wide and 16 high.
- Hard pixels only: fully opaque or fully transparent.

## The frames

For every kind (levy, spearmen, swordsmen, archers, riders) and each realm, seen from the front and from behind (the
left-facing ones are mirrored), eleven poses:

| Poses | What |
|---|---|
| walk 1-4 | walking |
| stand | standing |
| blow 1-4 | wind-up, strike (with a pale smear where the weapon swept), follow-through, recovery. Archers: nock, draw, loose, lower |
| struck 1-2 | knocked back with blood thrown off; staggering |

The fallen are four bodies per realm. There are three trees and seven seamless 32 x 32 ground textures (floor, woods,
hill, stream, ford, road, field).

## Files

- `lib/wpx.lua`: pixel helpers. `lib/figures.lua`: the figures as grids of letters and the styles that turn letters
  into pixels. `lib/fight.lua`: the blow and struck frames.
- `sheet.lua` writes the game's sheet `games/war/art.png` and its layout `games/war/art-atlas.js` (never edit that by
  hand), and `shots/sheet.png` to look at. Run it after any change to the art, then look at the shot:

  ```bash
  "/c/Program Files/Aseprite/Aseprite.exe" -b --script-param root="$(pwd -W)" --script art/war/sheet.lua
  ```

- `strike.lua` draws the blow and the hit as a sheet and as looping GIFs in `shots/`, to judge the animation by eye.

The game plays a blow as: wind-up while the man's next blow is a few ticks off and an enemy is in reach, then strike,
follow-through and recovery over the ticks after it lands; struck 1 and 2 over the ticks after he is hit
(`games/war/rules.js`, `poseOf`).
