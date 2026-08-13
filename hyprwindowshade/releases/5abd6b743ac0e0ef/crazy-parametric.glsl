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

            // Ported from skwd-wall crazy-parametric transition

            vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                float p = niri_clamped_progress;
                vec2 uv = coords_geo.xy;

                float a = 4.0;
                float b = 1.0;
                float amplitude = 120.0;
                float smoothness = 0.1;
                vec2 dir = uv - vec2(0.5);
                float dist = length(dir);
                float xx = (a - b) * cos(p) + b * cos(p * ((a / b) - 1.0));
                float yy = (a - b) * sin(p) - b * sin(p * ((a / b) - 1.0));
                vec2 offset = dir * vec2(sin(p * dist * amplitude * xx), sin(p * dist * amplitude * yy)) / smoothness;

                vec3 tc = niri_geo_to_tex * vec3(uv, 1.0);
                vec4 win = texture2D(niri_tex, tc.st);

                float reveal = smoothstep(0.2, 1.0, p);
                return win * reveal;
            }

void main() {
  fragColor = open_color(vec3(v_texcoord, 1.0), vec3(surface_size, 1.0));
}
