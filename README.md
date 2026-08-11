# Opening shaders for Niri and Hyprland

This is a maintained fork of [liixini/shaders](https://github.com/liixini/shaders),
a collection of GLSL opening and closing animations written for
[Niri](https://github.com/YaLTeR/niri). Thank you to
[liixini](https://github.com/liixini) and every contributor for publishing the
original collection.

The shader sources in this repository remain Niri shaders. They are not copied
directly into Hyprland: Niri's `open_color` / `close_color` interface and
`niri_*` uniforms are incompatible with HyprWindowShade's GLSL ES 3.20 fragment
interface. The companion NixOS configuration ports and validates every
**opening** shader at build time instead.

## Shader catalogue

Every directory below contains `open.glsl`, `close.glsl`, and its Niri
configuration snippet:

`bounce`, `circle`, `colour-distance`, `crazy-parametric`, `crosshatch`,
`crosswarp`, `directional`, `directional-wipe`, `dissolve`, `fade`, `fadecolor`,
`flyeye`, `glass-warp`, `glitch`, `heat-melt`, `ink-splash`, `inkwell-drop`,
`morph`, `overexposure`, `perlin`, `pixelate`, `pixelfade-wave`, `plasma-flow`,
`polar-function`, `polka-dots-curtain`, `randomsquares`, `ripple`, `smoke`,
`snap`, `soft-warp-fade`, `static-fade`, `voronoi-shatter`, and `wave-warp`.

For Niri, use the original configuration approach documented by the upstream
project: [Niri animation configuration](https://github.com/niri-wm/niri/wiki/Configuration:-Animations).

## NixOS + HyprWindowShade

The reproducible NixOS integration lives in
[`osmargm1202/nixos`](https://github.com/osmargm1202/nixos):

- [`nixos/packages/hyprwindowshade.nix`](https://github.com/osmargm1202/nixos/blob/master/nixos/packages/hyprwindowshade.nix)
  builds the ABI-matched HyprWindowShade plugin, wraps every `*/open.glsl` in
  the plugin's GLSL ES 3.20 interface, and runs `glslangValidator -S frag` for
  every generated shader.
- [`nixos/profiles/hyprland.nix`](https://github.com/osmargm1202/nixos/blob/master/nixos/profiles/hyprland.nix)
  exposes the validated outputs at
  `/etc/hyprwindowshade-shaders/open/<name>.glsl`.
- [`windows-workspaces.lua`](https://github.com/osmargm1202/nixos/blob/master/dotfiles/config/profiles/hyprland/.config/hypr/lua/windows-workspaces.lua)
  assigns opening shaders per application through
  `shader_transition_open` tags.

The adapter maps Niri's progress, random seed, texture, geometric transform,
and surface size to HyprWindowShade's `transition_progress`,
`transition_seed`, `tex`, identity texture coordinates, and `surface_size`.
HyprWindowShade presently supports opening transitions only; the Niri close
sources remain available for Niri and are not advertised as Hyprland effects.

### Recommendation

Use this repository as the immutable shader source and port it during the Nix
build. Do **not** install the Niri `.glsl` files directly as HyprWindowShade
shaders: they require a different GLSL entry point and uniforms. Pin a commit
in `flake.lock`, build the plugin against the same Hyprland release, and let
the build reject invalid ports before deployment.

To choose a shader for an application, point its Hyprland opening-transition
tag to the generated path:

```lua
hl.window_rule({
  match = { class = "^(kitty)$" },
  tag = "+shader_transition_open:/etc/hyprwindowshade-shaders/open/fade.glsl",
})
hl.window_rule({
  match = { class = "^(kitty)$" },
  tag = "+shader_transition_duration_ms:200",
})
```

After deploying the NixOS profile, **Super+Ctrl+G** opens the graphical shader
selector. It can preview any validated shader in a new Kitty window, assign one
to the currently focused application's exact class, or reset that class to its
declarative default. Assignments persist in
`$XDG_STATE_HOME/hypr/shader-overrides`; the generated Hyprland Lua rules load
them after the defaults, so a Nix rebuild does not erase an explicit choice.

Close every window of that application before reopening it: opening shaders run
only when HyprWindowShade receives the new-window lifecycle event.

## Attribution and licenses

| Project | Role | License | Thanks / source |
| --- | --- | --- | --- |
| [liixini/shaders](https://github.com/liixini/shaders) | Original Niri shader collection and all shader source in this fork | [MIT](LICENSE) | Thank you, [liixini](https://github.com/liixini), for creating and maintaining the collection. |
| [liixini/skwd-wall](https://github.com/liixini/skwd-wall) | Origin for the shaders marked `Ported from skwd-wall` | [MIT](https://github.com/liixini/skwd-wall/blob/main/LICENSE) | Thank you to [liixini](https://github.com/liixini) for those transition sources. |
| [gl-transitions/gl-transitions](https://github.com/gl-transitions/gl-transitions) | Origin for `circle` and `ripple`, as noted in their shader headers | [MIT](https://github.com/gl-transitions/gl-transitions/blob/master/LICENSE) | Thank you to [gre](https://github.com/gre) and the gl-transitions contributors. |
| [ManofJELLO/HyprWindowShade](https://github.com/ManofJELLO/HyprWindowShade) | Hyprland per-window shader plugin used by the NixOS adapter | [MIT](https://github.com/ManofJELLO/HyprWindowShade/blob/main/LICENSE) | Thank you to [ManofJELLO](https://github.com/ManofJELLO) for the plugin and shader interface. |
| [hyprnux/hyprglass](https://github.com/hyprnux/hyprglass) | Optional Liquid Glass companion for Hyprland; not redistributed here | [BSD-3-Clause](https://github.com/hyprnux/hyprglass/blob/main/LICENSE) | Thank you to [hyprnux](https://github.com/hyprnux) for HyprGlass. |
| [Hyprland](https://github.com/hyprwm/Hyprland) | Compositor and plugin API | [BSD-3-Clause](https://github.com/hyprwm/Hyprland/blob/main/LICENSE) | Thank you to the Hyprland contributors. |

This fork retains the upstream MIT `LICENSE`. The NixOS adapter is separate
configuration code; it does not change the license of the original shader
sources.
