#version 320 es
// Generated from the Niri source in osmargm1202/shaders.
// See ../niri-shaders-LICENSE for the retained MIT license and attribution.
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
            vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                float p = niri_clamped_progress;
                vec2 uv = coords_geo.xy;

                vec2 center = vec2(0.5, 0.5);
                float scale = mix(0.95, 1.0, p);
                vec2 scaled_uv = (uv - center) / scale + center;

                vec3 tex_coords = niri_geo_to_tex * vec3(scaled_uv, 1.0);
                vec4 color = texture2D(niri_tex, tex_coords.st);

                float alpha = smoothstep(0.0, 0.8, p);

                return color * alpha;
            }

void main() {
  fragColor = open_color(vec3(v_texcoord, 1.0), vec3(surface_size, 1.0));
}
