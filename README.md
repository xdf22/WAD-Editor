# WAD-Editor
a bunch of wad/pk3 stuff i've made for SRB2 Lua

# Overview
- XWE/
  - CLI.lua: basic way to create wad files using commands
  - GUI.lua: incomplete UI based editor for wads and pk3s
  - API.lua: callback functions for GUI.lua depending on the file type
- doomgfx.lua: decoder for doom patches and textures (TODO: Flats)
- pk3.lua: incomplete pk3 reader/writer
- wad.lua: complete wad reader/writer

# Notes
- this is unfinished
- pk3 support is really basic currently, and compression probably wont be supported
- no caps lock or modifier key support in the gui editor
- doomgfx drawing is slow and fps expensive
- some parts of the code are really scary and could use improvements or more comments
