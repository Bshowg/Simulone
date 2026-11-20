# The page kit

`kit.js` is the phone screen every game here shares. It is page code, not simulation code: it knows nothing about any game, draws no game state by itself, and a game's page fills it in.

```js
import { createScreen, meter } from '../../kit/kit.js';

const ui = createScreen(document.body);
const [w, h] = ui.size();
ui.canvas.width = w; ui.canvas.height = h;
const game = createGame({ canvas: ui.canvas, onFrame: draw, ... });
ui.onResize = (w, h) => game.resize(w, h);

ui.bar([{ id: 'people', label: 'People', render: body => ui.html(body, peopleHtml()) }]);
function draw() { ui.when('spring day 2'); ui.numbers([{ label: 'grain', value: 380, warn: false }]); ui.refresh(); }
```

## The screen

| Part | What it is for | How to fill it |
|---|---|---|
| Top strip | The moment, a few key numbers, a control or two, one line of what is coming | `ui.when(html)`, `ui.numbers([{ label, value, warn }])`, `ui.control(label, onTap)`, `ui.sub(html)` |
| The map | The canvas fills everything in between | `ui.canvas`, `ui.size()`, `ui.onResize`; `ui.layer()` gives a second canvas over it that takes no touches, for a page's own drawing |
| Over the map | A button in the corner, notices that go away, a card, a question | `ui.corner(label, onTap)`, `ui.toast(html)`, `ui.card(html or null)` with `ui.onCard = event => …`, `ui.ask({ id, html, choices, onChoose, note })` |
| A sheet | Slides up when a bar button is picked; the map shrinks, it is never covered whole | `ui.bar([{ id, label, title, render(body), onOpen, onClose }])`, `ui.show(id)`, `ui.close()`, `ui.open` |
| The goal | One line above the bar | `ui.goal(html or null, onTap)` |
| The tray | The open sheet folded down to one strip (some words and a few buttons), with the clock, controls, goal and bar put away, so the map has the screen: for a tool in hand | `ui.tray({ html, buttons: [{ id, label, strong, disabled }], onTap(id) })`, `ui.tray(null)` to unfold |
| Exit | A button at the end of the top controls, only when the page was opened from a menu that set `globalThis.KIT_EXIT = { href, label }` before the game started. It calls `ui.onExit` (save there) and goes to `href` | `ui.onExit = () => save()` |
| Bottom bar | The game's sections | `ui.bar(...)`, `ui.hint(id or null)` to draw the eye to one button |
| Full screen | The rare moment that should stop play | `ui.full({ title, html, button, onClose })`, `ui.fullOpen` |

## Things to know

- **Nothing here runs a loop.** Call `ui.refresh()` from the game's frame callback; it calls the open sheet's `render` again.
- **Use `ui.html(node, text)` inside `render`.** It only touches the page when the text changed, so buttons keep their place under the player's finger between refreshes. Handle clicks with one `body.onclick` that looks at `event.target.closest('button')`.
- **The kit never pauses the game.** A page that wants time to stand still during a full-screen moment sets the game's speed itself.
- **`meter(v)`** returns a small progress bar as HTML for a value from 0 to 1.
- **Colours** are the `--k-*` tokens on `:root`, with a light and a dark set that follow the viewer's theme. Redefine them to restyle a game.
- **Edges.** The top strip, sheets and goal line keep a 16px side gutter that also clears a phone's system bars; the map runs edge to edge.
