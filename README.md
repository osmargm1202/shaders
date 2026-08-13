# Opening shaders for Niri and Hyprland

[`osmargm1202/shaders`](https://github.com/osmargm1202/shaders) is the maintained fork of [`liixini/shaders`](https://github.com/liixini/shaders). It preserves the original Niri sources, source headers, and MIT license, and publishes a validated HyprWindowShade opening-transition catalogue alongside them.

## Choose the right collection

| Compositor | Use directly | Do not use |
| --- | --- | --- |
| [Niri](https://github.com/YaLTeR/niri) | `<effect>/open.glsl` and `<effect>/close.glsl` | `hyprwindowshade/open/` |
| [Hyprland](https://github.com/hyprwm/Hyprland) with [HyprWindowShade](https://github.com/osmargm1202/HyprWindowShade) | `hyprwindowshade/open/<effect>.glsl` | the raw Niri `open.glsl` files |

Niri shaders expose `open_color()` and `niri_*` values. HyprWindowShade loads GLSL ES 3.20 fragment shaders with `main()`, `v_texcoord`, `tex`, and `transition_*` uniforms. The committed `hyprwindowshade/open/` files bridge those interfaces and have passed `glslangValidator`; Hyprland users do **not** need to adapt them themselves.

HyprWindowShade implements opening transitions only. Niri `close.glsl` files remain Niri-only; Hyprland has no supported close-transition equivalent.

## Hyprland: use the ready-to-load catalogue

1. Install or build an ABI-compatible HyprWindowShade plugin. The maintained fork is required today: its commit [`716b7e8`](https://github.com/osmargm1202/HyprWindowShade/commit/716b7e8d1e38b5dc0dda43f0e4580cf464d2ae2b) adds the tagged open-transition support that this catalogue uses. It targets **Hyprland 0.56**. Rebuild the plugin after a Hyprland update; plugins use Hyprland internal APIs and a `.so` cannot be universal across versions.
2. Clone or pin this repository. No generator or shader compiler is required by an ordinary user:

   ```sh
   git clone https://github.com/osmargm1202/shaders.git "$HOME/.config/hypr/shaders"
   ```

3. Load the plugin before loading a rule. The exact plugin path is defined by the plugin build:

   ```ini
   exec-once = hyprctl plugin load /home/USERNAME/.local/share/hyprland/plugins/HyprWindowShade.so
   ```

4. Point an opening rule at a committed artifact. On Hyprland 0.55 and newer with Lua configuration:

   ```lua
   local shader_root = os.getenv("HOME") .. "/.config/hypr/shaders/hyprwindowshade/open"

   hl.window_rule({
     match = { class = "^(kitty)$" },
     tag = "+shader_transition_open:" .. shader_root .. "/fade.glsl",
   })
   hl.window_rule({
     match = { class = "^(kitty)$" },
     tag = "+shader_transition_duration_ms:200",
   })
   ```

   For a `.conf` configuration:

   ```ini
   windowrule = match:class kitty, tag +shader_transition_open:/home/USERNAME/.config/hypr/shaders/hyprwindowshade/open/fade.glsl, tag +shader_transition_duration_ms:200
   ```

   Replace `USERNAME` and `kitty`; obtain the real client class with:

   ```sh
   hyprctl activewindow -j | jq -r '.class'
   ```

   Reload Hyprland and completely reopen the target application. An opening shader runs only for a new-window event.

The transition tags are specific to this HyprWindowShade fork. [HyprGlass](https://github.com/hyprnux/hyprglass) is unrelated: it provides liquid-glass compositing and does not load this repository's GLSL files.

## NixOS

Pin both the plugin implementation and this collection. The plugin must be built against the exact `hyprlandPackage` selected by your NixOS profile; the shader collection itself is a data input.

```nix
inputs = {
  hyprWindowShade = {
    url = "github:osmargm1202/HyprWindowShade/5fcc906a7fed036afcf7e53e889a99c424b8b0fb";
    flake = false;
  };
  shaders = {
    url = "github:osmargm1202/shaders/COMMIT";
    flake = false;
  };
};
```

Replace `COMMIT`, update and commit `flake.lock`, then package the plugin with the selected Hyprland package and `inputs.shaders`. The reference implementation in [`osmargm1202/nixos`](https://github.com/osmargm1202/nixos) installs:

```text
/etc/HyprWindowShade.so
/etc/hyprwindowshade-shaders/open/<effect>.glsl
```

Load `/etc/HyprWindowShade.so` at Hyprland startup and point your Lua rules to `/etc/hyprwindowshade-shaders/open/<effect>.glsl`. A NixOS build validates the committed GLSL catalogue before deployment; switch only after the target toplevel build succeeds.

## Catalogue

Every root effect directory retains its upstream Niri `open.glsl`, `close.glsl`, and configuration snippet. Every valid opening source is also published under `hyprwindowshade/open/` with the same effect name and a `.glsl` extension.

`glass-warp/open.glsl` is intentionally **not** published for HyprWindowShade. The retained Niri source lacks its closing brace, so its generated GLSL fails validation. It stays available for Niri exactly as supplied upstream. It will join the Hyprland catalogue only after the source is repaired and validates.

## Maintaining the generated catalogue

`hyprwindowshade/open/` is a committed release artifact, not a per-user setup step. Contributors regenerate it after changing a Niri source or the adapter:

```sh
nix shell nixpkgs#glslang -c ./tools/build-hyprwindowshade-open-shaders
```

The generator writes every output to a staging directory, validates each with `glslangValidator -S frag`, and replaces the catalogue only if every candidate passes. Review and commit the generated changes with the source change. It deliberately excludes the invalid `glass-warp` source described above.

## Attribution and licenses

The repository retains the upstream [MIT license](LICENSE), source headers, and provenance. Keep them when redistributing or modifying these shaders.

| Project | Relationship |
| --- | --- |
| [`liixini/shaders`](https://github.com/liixini/shaders) | Original Niri shader collection |
| [`osmargm1202/shaders`](https://github.com/osmargm1202/shaders) | Maintained source and validated HyprWindowShade catalogue |
| [`osmargm1202/HyprWindowShade`](https://github.com/osmargm1202/HyprWindowShade) | Required plugin fork for tagged opening transitions on Hyprland 0.56 |
| [`ManofJELLO/HyprWindowShade`](https://github.com/ManofJELLO/HyprWindowShade) | Upstream plugin project |
| [`hyprnux/hyprglass`](https://github.com/hyprnux/hyprglass) | Optional, separate liquid-glass compositor plugin |

Project names identify provenance and do not imply endorsement by upstream authors.
