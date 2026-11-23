# SB-059 fix runtime evidence (not for main)

Pictures for the review of the SB-059 fix pull request only; delete the branch after the review.

- `01`-`07`: Godot 4.5.1 (GL Compatibility, GPU, Linux), the real main scene in a window, driven by `capture.gd`
  (village paused at 10:04; touches go through `Input.parse_input_event` in window pixels, as a browser delivers them).
  Logical size 390 x 844 (`01`-`05`, Czech), 320 x 640 (`06`, English), 1280 x 720 (`07`, English).
  - `01` card at its top; `02` after ten one-finger swipes up over the text (end of the card); `03` swiped back down:
    Neznámé and Zdroje on screen together; the village above the card is the same in `01`-`03` (camera not moved).
  - `04` another homestead's card (key/select) opens at its top.
  - `05` overview after two taps on the speed button: x40, the top line says `(pozastaveno)`.
  - `06` 320 px: speed button x10 top right, card header with 44 x 44 px CS and x buttons, the bar unchanged.
  - `07` desktop: header, x1/x10/x40 and the bar as before; no cycling button.
- `web_*`: the Web export from this PR's Pages build (`web-export` artifact), served locally, headless Chromium
  (SwiftShader) driven by `web_drive.mjs`. Phone: 390 x 844, DPR 3, `isMobile`, `hasTouch`, real CDP touch events
  (`Input.dispatchTouchEvent`); pictures scaled to 50 %. Desktop: 1280 x 800, mouse wheel.
  - phone `p1`-`p3`: a one-finger drag over the card text scrolls it, nine drags reach the sources; the village strip
    above the card differs from `p1` in 0.008 % of pixels (control: a drag over the village changes 23.6 %).
  - phone `p4` back a little, `p5` key 1: the ploughman's card opens at its top, `p6`-`p8` three taps on the speed button:
    x10, x40, x1 (button and top line).
  - desktop `d1` card, `d2` after 40 wheel notches (deltaY 300) over the card: the card is at its end, the village is not
    zoomed (0.15 % of pixels differ, a few-pixel shift; control: one notch over the village changes 20 %). `d3` next card at
    its top, `d4` the top line in Czech: `(pozastaveno)`.
  - consoles: no error except the local server's missing `favicon.svg` (404).
