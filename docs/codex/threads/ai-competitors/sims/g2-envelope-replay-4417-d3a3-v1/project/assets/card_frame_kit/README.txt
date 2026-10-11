PATCH NOTES — SYMMETRIC CONNECTED CARD FRAMES (REVISION 3)

Minimal pixel frame sprites on a 240x336 card. All frame PNGs are text-free.
Godot supplies the values, names, and department text. The left and right
compartments mirror each other; each row is one continuous piece with shared
diagonal dividers. The top corners each contain a score value and score type.
The footer corners are matching frame shapes for Renewability and Scope.

QUICK INSTALL
Draw assets/background.png (240x336) beneath card artwork.
Draw assets/card_frame_complete.png at (0,0), then the selected 24x24
renewability icon at (19,300), then the Godot labels. Set pixel textures to
nearest filtering and keep integer positions/scales.

ALTERNATE FRAME LAYERS
Instead of card_frame_complete, draw assets/card_frame.png plus:
  - assets/frames_overlay.png at (0,0), or
  - assets/top_connected_frame.png at (5, 7), 230x60
    and assets/bottom_connected_frame.png at (5, 291),
    230x42.
Do not double-layer complete and separate frames.

PROPOSED GODOT RECTANGLES, X/Y FROM TOP LEFT
  Primary score value    (10,12)   40x30
  Primary score type     (10,46)   40x16
  Name                   (70,18)  100x34
  Secondary score value (190,12)   40x30
  Secondary score type  (190,46)   40x16
  Renewability slot      (10,296)  42x32
    icon centered at     (19,300)  24x24
  Department             (70,300) 100x24
  Scope                 (188,296)  42x32

These are new coordinates required for both score pairs and exact symmetry.
The previous 156px Name field and rightward Department field cannot remain
at their old positions in this layout. The sample preview uses Tiny5 at 14px
for Name/Department, 24px for score values, 8px for score types, and 16px for
Scope. Long names or labels still need the game's own fit/abbreviation rule.

PREVIEWS
previews/blank_card.png shows the frame and background with no baked text.
previews/godot_text_example.png adds sample icon and text only for checking fit.

The included outer border, background, and renewable/finite icons are the
retained art from the earlier kit. The new band geometry is in
source/frame_geometry.svg. This is a standalone asset pack; no Godot project
was changed. layout_manifest.json contains machine-readable coordinates.
