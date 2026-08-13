#version 320 es
// Generated from the Niri source in osmargm1202/shaders.
// See niri-shaders-LICENSE for the retained MIT license and attribution.
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
            // Ported from gl-transitions/ripple.glsl (MIT, gre)

            vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                float p = niri_clamped_progress;
                vec2 uv = coords_geo.xy;
                float seed = niri_random_seed * 6.28318;

                float amplitude = 100.0;
                float speed = 50.0;

                vec2 dir = uv - vec2(0.5);
                float dist = length(dir);

                float intensity = (1.0 - p) * (1.0 - p);
                vec2 offset = dir * (sin(p * dist * amplitude - p * speed + seed) + 0.5) / 30.0;

                vec2 wuv = uv + offset * intensity;
                vec3 tc = niri_geo_to_tex * vec3(wuv, 1.0);
                vec4 color = texture2D(niri_tex, tc.st);

                float alpha = smoothstep(0.0, 0.3, p);
                return color * alpha;
            }

void main() {
  fragColor = open_color(vec3(v_texcoord, 1.0), vec3(surface_size, 1.0));
}
