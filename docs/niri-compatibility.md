# Niri integration and capabilities

Velatura is built around Niri's native compositor model. It reads live state from the Niri event stream, sends supported actions through `niri msg`, and leaves persistent compositor configuration in the user's KDL file.

## Native integration

| Area | Niri interface | Velatura behaviour |
|---|---|---|
| Workspaces and windows | Event stream and `niri msg` | Live workspace, focus and window state |
| Workspace navigation | `niri msg action` | Actions target real workspaces; the island does not invent persistent empty slots |
| Window layout | Scrolling columns and `layout {}` | Niri owns placement; the shell previews and links to the configuration editor |
| Animations | `animations {}` | Edited in the Niri KDL configuration |
| Gestures | `gestures {}` | Configured natively in Niri |
| Window rules | `window-rule {}` | Configured natively in Niri |
| Outputs | `niri msg outputs` and KDL | State is read live; persistent profiles can be managed with [Kanshi](https://gitlab.com/emersion/kanshi) |
| Colour picking | `niri msg pick-color` | Uses Niri's built-in screen colour picker |
| Idle and lock | Wayland idle protocols and session lock | Quickshell handles idle monitoring and the integrated lock surface |
| Alternate layouts | [miri](https://github.com/YaLTeR/miri) | Optional community extension; Niri's native model remains scrolling columns |
| Scratchpads | [niri-scratchpad-rs](https://github.com/argosnothing/niri-scratchpad-rs) or [niri-scratchpad](https://github.com/YaLTeR/niri-scratchpad) | Optional external tools; verify package availability before installing |

The curated [awesome-niri list](https://github.com/niri-wm/awesome-niri) tracks additional community tools. These are independent projects, not bundled or silently installed by Velatura. NiriMod is an optional AUR dependency and is launched on demand from the settings pages.

## Important limitations

- Niri IPC reports window identity, workspace membership, focus and layout metadata, but does not provide global pixel rectangles for every window. The shell does not guess window geometry for drag-and-drop or pixel-perfect thumbnails. The capture overlay therefore offers region and screen selection; native window capture is not yet wired into Velatura's capture destinations.
- Niri IPC does not expose configured keybindings as a complete editable list. Bindings live in KDL. The shell delegates inspection and editing to the optional NiriMod tool rather than rewriting the user's configuration itself.
- Niri's event stream does not provide a dedicated output-change event. The monitor service refreshes output state from Quickshell screen hotplug/geometry signals and workspace topology changes, with a debounced read of `niri msg --json outputs`. Niri handles the internal laptop output on lid close/open. Persistent output profiles belong in Niri KDL or a profile manager such as Kanshi.
- Niri provides native background blur on supported versions, but it does not expose a refractive glass or shake-to-find cursor effect. Velatura does not present controls that pretend those effects are available.
