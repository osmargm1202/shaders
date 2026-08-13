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

            // Ported from skwd-wall perlin transition

            float perlin_random(vec2 co) {
                float a = 12.9898;
                float b = 78.233;
                float c = 43758.5453;
                float dt = dot(co.xy, vec2(a, b));
                float sn = mod(dt, 3.14);
                return fract(sin(sn) * c);
            }

            float perlin_noise(in vec2 st) {
                vec2 i = floor(st);
                vec2 f = fract(st);
                float a = perlin_random(i);
                float b = perlin_random(i + vec2(1.0, 0.0));
                float c = perlin_random(i + vec2(0.0, 1.0));
                float d = perlin_random(i + vec2(1.0, 1.0));
                vec2 u = f * f * (3.0 - 2.0 * f);
                return mix(a, b, u.x) +
                    (c - a) * u.y * (1.0 - u.x) +
                    (d - b) * u.x * u.y;
            }

            vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                float pr = niri_clamped_progress;
                vec2 uv = coords_geo.xy;
                vec3 tc = niri_geo_to_tex * vec3(uv, 1.0);
                vec4 win = texture2D(niri_tex, tc.st);

                float scale = 4.0;
                float smoothness = 0.01;
                float n = perlin_noise(uv * scale);
                float p = mix(-smoothness, 1.0 + smoothness, pr);
                float lower = p - smoothness;
                float higher = p + smoothness;
                float q = smoothstep(lower, higher, n);
                float reveal = 1.0 - q;

                return win * reveal;
            }

void main() {
  fragColor = open_color(vec3(v_texcoord, 1.0), vec3(surface_size, 1.0));
}
