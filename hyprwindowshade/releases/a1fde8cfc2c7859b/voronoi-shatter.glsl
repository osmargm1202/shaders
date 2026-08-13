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

            // Ported from skwd-wall voronoi-shatter transition

            vec2 vs_hash2(vec2 p) {
                return fract(sin(vec2(dot(p, vec2(127.1, 311.7)),
                                       dot(p, vec2(269.5, 183.3)))) * 43758.5453);
            }

            vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                float p = niri_clamped_progress;
                vec2 uv = coords_geo.xy;
                vec3 tc = niri_geo_to_tex * vec3(uv, 1.0);
                vec4 win = texture2D(niri_tex, tc.st);

                float scale = 14.0;
                vec2 q = uv * scale;
                vec2 g = floor(q);
                vec2 f = fract(q);
                float min_d = 100.0;
                vec2 cell = g;
                for (int y = -1; y <= 1; y++) {
                    for (int x = -1; x <= 1; x++) {
                        vec2 nb = vec2(float(x), float(y));
                        vec2 r = nb + vs_hash2(g + nb) - f;
                        float d = dot(r, r);
                        if (d < min_d) { min_d = d; cell = g + nb; }
                    }
                }
                float seed = vs_hash2(cell).x;
                float shard_p = smoothstep(seed * 0.5, seed * 0.5 + 0.5, p);
                float reveal = smoothstep(0.0, 0.5, shard_p);

                return win * reveal;
            }

void main() {
  fragColor = open_color(vec3(v_texcoord, 1.0), vec3(surface_size, 1.0));
}
