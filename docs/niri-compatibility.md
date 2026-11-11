# Niri compatibility and Hyprland plugin replacements

Impasto's Niri port does not load Hyprland plugins. Niri is a separate compositor with its own configuration and IPC; a Hyprland plugin cannot be reused by changing its config syntax.

## Replacements

| Original feature | Niri-side approach | Status |
|---|---|---|
| Hyprland workspace/window IPC | Niri event stream and `niri msg action` | Native; used by `NiriService` |
| Hyprland overview geometry | Niri workspace/window IPC; list actual workspaces and windows | Adapted without inventing global window rectangles |
| hypr-dynamic-cursors: shake-to-find | No equivalent Niri plugin/API identified | Not ported; keep the setting unavailable rather than fake it |
| hyprglass: refractive window glass | Niri's native background blur plus translucent client surfaces; Quickshell can keep its own glass effects | Partial visual substitute; refraction/chromatic distortion has no direct equivalent |
| Hyprland animations | Niri's native `animations {}` configuration | Native; presets must be translated to Niri KDL values |
| Hyprland gestures | Niri's native `gestures {}` configuration | Native |
| Hyprland window rules | Niri's native `window-rule {}` configuration | Native |
| Hyprland monitor profiles | [Kanshi](https://gitlab.com/emersion/kanshi) for automatic profiles; [nirimon](https://github.com/stepbrobd/nirimon) or [nirilayout](https://github.com/YaLTeR/nirilayout) for interactive/profile workflows | External tools; do not write a user's KDL blindly |
| Hyprland scratchpads | [niri-scratchpad-rs](https://github.com/argosnothing/niri-scratchpad-rs) or [niri-scratchpad](https://github.com/YaLTeR/niri-scratchpad) | External tools; verify package availability before installing |
| Alternate layouts (master/stack) | [miri](https://github.com/YaLTeR/miri) | Optional Niri extension; Niri's native model remains scrolling columns |

The curated [awesome-niri list](https://github.com/niri-wm/awesome-niri) tracks additional community tools. These are independent projects, not bundled or silently installed by Impasto. NiriMod is an optional AUR dependency and is launched on demand from the settings pages.

## Important limitations

- Niri IPC reports window identity, workspace membership, focus and layout metadata, but not Hyprland-style global rectangles for every window. The shell must not recreate drag/drop or pixel-perfect thumbnails from guessed geometry. The capture overlay therefore offers region and screen selection only; native Niri window screenshots exist but are not yet wired into Impasto's capture destinations.
- Niri does not expose configured keybinds through IPC. Bindings live in KDL. The shell does not parse or rewrite that file; its settings pages launch the optional NiriMod editor for binding inspection and editing.
- Niri 26.04's event stream has no dedicated output-change event. The monitor service refreshes output state from Quickshell screen hotplug/geometry signals and workspace topology changes, with a debounced read of `niri msg --json outputs`. Niri automatically handles the internal laptop output on lid close/open. Output changes made through compositor IPC are temporary; persistent profiles belong in Niri KDL or a profile manager such as Kanshi. The shell's monitor page reads output state and launches NiriMod for interactive KDL editing.
- Refraction and shake-to-find are not claimed as supported. Native blur and ordinary cursor themes are not equivalent to those effects.
