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

            // Ported from skwd-wall crosshatch transition

            float crosshatch_rand(vec2 co) {
                return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
            }

            vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                float p = niri_clamped_progress;
                vec2 uv = coords_geo.xy;
                vec3 tc = niri_geo_to_tex * vec3(uv, 1.0);
                vec4 win = texture2D(niri_tex, tc.st);

                vec2 center = vec2(0.5);
                float threshold = 3.0;
                float fadeEdge = 0.1;
                float dist = distance(center, uv) / threshold;
                float r = p - min(crosshatch_rand(vec2(uv.y, 0.0)), crosshatch_rand(vec2(0.0, uv.x)));
                float reveal = mix(0.0, mix(step(dist, r), 1.0, smoothstep(1.0 - fadeEdge, 1.0, p)), smoothstep(0.0, fadeEdge, p));

                return win * reveal;
            }

void main() {
  fragColor = open_color(vec3(v_texcoord, 1.0), vec3(surface_size, 1.0));
}
