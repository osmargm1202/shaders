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

            // Ported from gl-transitions/circleopen.glsl (MIT, gre)

            vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                float p = niri_clamped_progress;
                vec2 uv = coords_geo.xy;
                float seed = niri_random_seed;

                float smoothness = 0.3;
                float SQRT_2 = 1.414213562;

                vec2 center = vec2(0.5 + (seed - 0.5) * 0.15, 0.5 + (seed * 0.7 - 0.35) * 0.15);

                float dist = SQRT_2 * distance(center, uv);
                float m = smoothstep(-smoothness, 0.0, dist - p * (1.0 + smoothness));
                float reveal = 1.0 - m;

                vec3 tc = niri_geo_to_tex * vec3(uv, 1.0);
                vec4 color = texture2D(niri_tex, tc.st);

                return color * reveal;
            }

void main() {
  fragColor = open_color(vec3(v_texcoord, 1.0), vec3(surface_size, 1.0));
}
