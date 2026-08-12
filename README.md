# Opening shaders for Niri and Hyprland

This repository is the maintained [`osmargm1202/shaders`](https://github.com/osmargm1202/shaders)
fork of [`liixini/shaders`](https://github.com/liixini/shaders). It preserves the
upstream Niri shader sources, their headers, and the upstream MIT license.

The collection works **directly with Niri**. Hyprland needs an adapter: Niri
`open.glsl` files expose `open_color()` and `niri_*` values, while
[HyprWindowShade](https://github.com/osmargm1202/HyprWindowShade) accepts GLSL
ES 3.20 fragment shaders with `main()`, `v_texcoord`, `tex`, and
`transition_*` uniforms. Do not copy a Niri shader directly into
HyprWindowShade; generate the adapted shader first.

This guide documents a reproducible Hyprland configuration for Arch Linux and
NixOS. It separates two independent effects:

- **HyprWindowShade** renders an opening-transition GLSL shader on a client.
- **HyprGlass** is optional Liquid Glass compositing for clients and layer
  surfaces such as Waybar, Rofi, and nwg-dock. It is not a GLSL shader loader.

## Scope and compatibility

- The pinned [HyprWindowShade fork](https://github.com/osmargm1202/HyprWindowShade/tree/5fcc906a7fed036afcf7e53e889a99c424b8b0fb)
  targets **Hyprland 0.56**. Plugins use Hyprland's internal ABI: rebuild the
  plugin after every Hyprland update rather than loading an old `.so`.
- The adapter ports every `*/open.glsl` file. HyprWindowShade supports opening
  transitions only; `close.glsl` remains available for Niri and is not a
  Hyprland effect.
- Test a new shader before assigning it to a daily-use application. A bad GLSL
  source can fail compilation; it must not be installed as an unvalidated
  system shader.

## Shader catalogue

Every directory contains Niri `open.glsl`, `close.glsl`, and a configuration
snippet. The available opening effects are:

`bounce`, `circle`, `colour-distance`, `crazy-parametric`, `crosshatch`,
`crosswarp`, `directional`, `directional-wipe`, `dissolve`, `fade`, `fadecolor`,
`flyeye`, `glass-warp`, `glitch`, `heat-melt`, `ink-splash`, `inkwell-drop`,
`morph`, `overexposure`, `perlin`, `pixelate`, `pixelfade-wave`, `plasma-flow`,
`polar-function`, `polka-dots-curtain`, `randomsquares`, `ripple`, `smoke`,
`snap`, `soft-warp-fade`, `static-fade`, `voronoi-shatter`, and `wave-warp`.

For Niri, follow the upstream [Niri animation configuration guide](https://github.com/niri-wm/niri/wiki/Configuration:-Animations).

## Hyprland on Arch Linux

### 1. Install the build and shader-validation tools

Install Hyprland and the build dependencies required by the pinned plugin. The
package names below are Arch package names; rebuild the plugin after upgrading
Hyprland.

```sh
sudo pacman -S --needed \
  base-devel git hyprland pkgconf glslang mesa libdrm libglvnd \
  cairo freetype2 libpng pixman wayland-protocols
```

### 2. Build the ABI-matched plugin

Clone the fork used by this setup at its known Hyprland 0.56 revision, then run
its documented build script:

```sh
git clone https://github.com/osmargm1202/HyprWindowShade.git \
  "$HOME/src/HyprWindowShade"
git -C "$HOME/src/HyprWindowShade" checkout \
  5fcc906a7fed036afcf7e53e889a99c424b8b0fb
cd "$HOME/src/HyprWindowShade"
./build.sh
```

The plugin README is the source of truth for its output path and runtime
requirements. Confirm that it loads before adding any rules:

```sh
hyprctl plugin load \
  "$HOME/.local/share/hyprland/plugins/HyprWindowShade.so"
hyprctl plugins list
```

For a persistent setup, load it once from the configuration that starts after
Hyprland:

```ini
exec-once = hyprctl plugin load /home/USERNAME/.local/share/hyprland/plugins/HyprWindowShade.so
```

Replace `USERNAME`; do not literally use that path. If Hyprland was upgraded,
rebuild first and only then reload the plugin.

### 3. Clone and pin this shader source

A clone gives a visible, editable source checkout. For reproducibility, record
the commit you selected instead of tracking an unspecified branch head.

```sh
git clone https://github.com/osmargm1202/shaders.git \
  "$HOME/.config/hypr/niri-opening-shaders"
git -C "$HOME/.config/hypr/niri-opening-shaders" rev-parse HEAD
```

### 4. Port and validate every opening shader

Create `~/.local/bin/port-hyprwindowshade-open-shaders`, make it executable,
and run it whenever this shader checkout changes. It stages and validates the
complete opening-shader set, then atomically switches a stable output symlink
to the new release. It intentionally ignores Niri `close.glsl`.

```sh
#!/usr/bin/env bash
set -euo pipefail

source_root="${1:-$HOME/.config/hypr/niri-opening-shaders}"
destination_link="${2:-$HOME/.config/hypr/hyprwindowshade-shaders/open}"

command -v glslangValidator >/dev/null || {
  printf '%s\n' 'glslangValidator is required' >&2
  exit 1
}
destination_parent="$(dirname "$destination_link")"
release_root="$destination_parent/.open-releases"
mkdir -p "$release_root"
staging="$(mktemp -d "$release_root/.release.XXXXXX")"
link_candidate=
trap 'rm -rf "$staging"; rm -f "${link_candidate:-}"' EXIT

# The stable path must be absent or a symlink. Do not replace a real directory:
# use a new output path instead when migrating an older manual setup.
if [[ -e "$destination_link" && ! -L "$destination_link" ]]; then
  printf 'refusing to replace non-symlink output: %s\n' "$destination_link" >&2
  exit 1
fi

for source in "$source_root"/*/open.glsl; do
  [ -r "$source" ] || continue
  name="$(basename "$(dirname "$source")")"
  destination="$staging/$name.glsl"
  {
    cat <<'GLSL'
// Generated from liixini/shaders. Keep the source license and attribution.
#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;
uniform float transition_progress;
uniform float transition_seed;
uniform vec2 surface_size;

#define niri_clamped_progress clamp(transition_progress, 0.0, 1.0)
#define niri_random_seed transition_seed
#define niri_geo_to_tex mat3(1.0)
#define niri_tex tex
#define texture2D texture
GLSL
    cat "$source"
    cat <<'GLSL'

void main() {
  fragColor = open_color(vec3(v_texcoord, 1.0), vec3(surface_size, 1.0));
}
GLSL
  } >"$destination"
  glslangValidator -S frag "$destination"
done

# Switch only after every source passed validation. Renaming a symlink within
# one directory is atomic, so running Hyprland always sees either the prior
# complete release or this complete release—never a partial shader set.
link_candidate="$(mktemp "$destination_parent/.open.link.XXXXXX")"
rm -f "$link_candidate"
ln -s "$staging" "$link_candidate"
mv -Tf "$link_candidate" "$destination_link"
link_candidate=
staging=
trap - EXIT
```

```sh
chmod +x ~/.local/bin/port-hyprwindowshade-open-shaders
~/.local/bin/port-hyprwindowshade-open-shaders
```

`glslangValidator` failing is intentional: fix or remove the failed port; the
stable output path continues to point at the previous release because the
staging directory is never activated. Do not point a Hyprland rule at a file
that did not validate.

### 5. Assign an opening shader to an application

Hyprland 0.55 and later use Lua configuration. Add a rule after the plugin is
loaded, substituting the real application class and shader name:

```lua
local shader_root = os.getenv("HOME") .. "/.config/hypr/hyprwindowshade-shaders/open"

hl.window_rule({
  match = { class = "^(kitty)$" },
  tag = "+shader_transition_open:" .. shader_root .. "/fade.glsl",
})
hl.window_rule({
  match = { class = "^(kitty)$" },
  tag = "+shader_transition_duration_ms:200",
})
```

Find the exact class before writing a rule:

```sh
hyprctl activewindow -j | jq -r '.class'
```

Rules are evaluated in order. Keep more-specific title rules after general
class rules. Restart the target application completely after `hyprctl reload`:
opening shaders run only when the plugin receives a new-window event.

HyprWindowShade also documents `.conf` rules, static shaders, layers, runtime
dispatchers, and its Lua helper functions in its
[README](https://github.com/osmargm1202/HyprWindowShade/tree/5fcc906a7fed036afcf7e53e889a99c424b8b0fb).

## NixOS: reproducible adapter

The companion [`osmargm1202/nixos`](https://github.com/osmargm1202/nixos)
configuration is the reference NixOS integration. It pins this repository,
ports every `open.glsl` at build time, and rejects invalid output with
`glslangValidator`.

### 1. Pin the three ABI-coupled inputs

Use explicit revisions in `flake.nix`; the example names are local to your
flake:

```nix
inputs = {
  hyprWindowShade = {
    url = "github:osmargm1202/HyprWindowShade/5fcc906a7fed036afcf7e53e889a99c424b8b0fb";
    flake = false;
  };
  niriShaders = {
    url = "github:osmargm1202/shaders/COMMIT";
    flake = false;
  };
  hyprglass = {
    url = "github:hyprnux/hyprglass/v0.7.0";
    flake = false;
  };
};
```

Replace `COMMIT` with a commit from this fork, run `nix flake lock --update-input
niriShaders`, and commit the resulting `flake.lock`. Do not leave the source
at an unpinned branch head.

### 2. Build the adapter against the selected Hyprland package

Copy or import the reference
[`hyprwindowshade.nix`](https://github.com/osmargm1202/nixos/blob/master/nixos/packages/hyprwindowshade.nix).
It wraps the Niri interface, calls `glslangValidator -S frag` for every output,
and installs the generated shaders under
`share/hyprwindowshade/shaders/open`.

Call it with the exact Hyprland package used by the profile:

```nix
hyprWindowShade = pkgs.callPackage ./hyprwindowshade.nix {
  hyprland = hyprlandPackage;
  src = inputs.hyprWindowShade;
  niriShaders = inputs.niriShaders;
};
```

Expose the plugin and generated output through stable system paths:

```nix
environment.etc."HyprWindowShade.so".source =
  "${hyprWindowShade}/lib/HyprWindowShade.so";
environment.etc."hyprwindowshade-shaders".source =
  "${hyprWindowShade}/share/hyprwindowshade/shaders";
```

Load `/etc/HyprWindowShade.so` at Hyprland startup, then point Lua rules at
`/etc/hyprwindowshade-shaders/open/<shader>.glsl`. The complete reference is
[`nixos/profiles/hyprland.nix`](https://github.com/osmargm1202/nixos/blob/master/nixos/profiles/hyprland.nix)
and its [application rules](https://github.com/osmargm1202/nixos/blob/master/dotfiles/config/profiles/hyprland/.config/hypr/lua/windows-workspaces.lua).

### 3. Build before switching

Run the appropriate target build for your flake and only switch after the
adapter validates. For the reference configuration, the targeted checks are:

```sh
nix build .#nixosConfigurations.HOST.config.system.build.toplevel
nixos-rebuild switch --flake .#HOST
```

Use your real `HOST`. The build is the validation boundary: a GLSL failure must
fail before deployment rather than produce a partial runtime shader set.

## Optional HyprGlass setup

[HyprGlass](https://github.com/hyprnux/hyprglass) provides a separate Liquid
Glass effect. It replaces ordinary Hyprland decoration blur for glassed
windows; it does not consume this repository's GLSL transitions.

Load HyprGlass before its Lua configuration, keep stock decoration blur off,
and opt into the layer namespaces that exist in your session:

```lua
if hl.plugin and hl.plugin.hyprglass then
  local hg = hl.plugin.hyprglass
  hg.config({
    enabled = true,
    manage_window_blur = true,
    default_theme = "dark",
    default_preset = "subtle",
    layers = { enabled = true },
  })
  hg.layer("waybar", { preset = "subtle", mask_threshold = 0.1 })
  hg.layer("rofi", { preset = "subtle", mask_threshold = 0.1 })
  hg.layer("nwg-dock-hyprland", { preset = "subtle", mask_threshold = 0.1 })
end

hl.config({
  decoration = {
    blur = { enabled = false },
  },
})
```

Use `hyprctl activewindow -j` to identify a client and add
`+hyprglass_enabled` or `+hyprglass_preset_subtle` tags through a window rule
when you want a per-client policy. See the
[HyprGlass configuration documentation](https://github.com/hyprnux/hyprglass/tree/v0.7.0)
for presets, per-window tags, and layer caveats.

## Troubleshooting

| Symptom | Check and repair |
| --- | --- |
| `hyprctl plugins list` does not show HyprWindowShade | Rebuild it against the installed Hyprland version, then load the current `.so` path. |
| A shader never appears | Confirm the client class with `hyprctl activewindow -j`, reload Hyprland, close every instance of the client, then reopen it. |
| GLSL validation fails | Do not deploy it. Re-run the adapter and inspect the validator output; Niri sources must be wrapped before HyprWindowShade can use them. |
| A HyprGlass layer is unchanged | Check the real layer namespace and its opacity mask. Layer rendering is version-sensitive. |
| A NixOS switch has a stale plugin | Build the plugin from the same `hyprlandPackage` as the active profile and switch only after the toplevel build succeeds. |

## Attribution, forks, and licenses

The MIT `LICENSE` in this repository is retained unchanged. Keep its copyright
notice and every source header when redistributing, modifying, or porting
shaders. This fork does not relicense upstream shader code, Hyprland plugins,
or HyprGlass.

| Project | Relationship and use in this setup | License | Repository |
| --- | --- | --- | --- |
| `osmargm1202/shaders` | This maintained fork; source input for the Hyprland adapter | [MIT](LICENSE) | [fork](https://github.com/osmargm1202/shaders) |
| `liixini/shaders` | Original Niri shader collection and source origin of this fork | [MIT](https://github.com/liixini/shaders/blob/main/LICENSE) | [upstream](https://github.com/liixini/shaders) |
| `liixini/skwd-wall` | Origin for sources marked `Ported from skwd-wall` in their headers | [MIT](https://github.com/liixini/skwd-wall/blob/main/LICENSE) | [upstream](https://github.com/liixini/skwd-wall) |
| `gl-transitions/gl-transitions` | Origin noted in shader headers, including `circle` and `ripple` | [MIT](https://github.com/gl-transitions/gl-transitions/blob/master/LICENSE) | [upstream](https://github.com/gl-transitions/gl-transitions) |
| `osmargm1202/HyprWindowShade` | Fork used by the documented Arch and NixOS integration | [MIT](https://github.com/osmargm1202/HyprWindowShade/blob/main/LICENSE) | [used fork](https://github.com/osmargm1202/HyprWindowShade) |
| `ManofJELLO/HyprWindowShade` | Original HyprWindowShade project | [MIT](https://github.com/ManofJELLO/HyprWindowShade/blob/main/LICENSE) | [upstream](https://github.com/ManofJELLO/HyprWindowShade) |
| `hyprnux/hyprglass` | Optional Liquid Glass companion; not redistributed here | [BSD-3-Clause](https://github.com/hyprnux/hyprglass/blob/main/LICENSE) | [upstream](https://github.com/hyprnux/hyprglass) |
| `hyprwm/Hyprland` | Compositor and plugin/window-rule API | [BSD-3-Clause](https://github.com/hyprwm/Hyprland/blob/main/LICENSE) | [upstream](https://github.com/hyprwm/Hyprland) |
| `YaLTeR/niri` | Original compositor and shader interface | [GPL-3.0](https://github.com/YaLTeR/niri/blob/main/LICENSE) | [upstream](https://github.com/YaLTeR/niri) |

Project names and links identify provenance; they do not imply endorsement by
any upstream author or project.
