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

            // Ported from skwd-wall inkwell-drop transition

            vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                float p = niri_clamped_progress;
                vec2 uv = coords_geo.xy;

                vec2 impact = vec2(0.35, 0.4);
                vec2 c = uv - impact;
                c.x *= size_geo.x / max(size_geo.y, 0.0001);
                float d = length(c);
                float front = p * 1.5;
                float ring1 = sin((d - front) * 80.0) * exp(-abs(d - front) * 6.0);
                float ring2 = sin((d - front + 0.08) * 80.0) * exp(-abs(d - front + 0.08) * 8.0) * 0.6;
                float ring3 = sin((d - front + 0.16) * 80.0) * exp(-abs(d - front + 0.16) * 10.0) * 0.4;
                float ripple = (ring1 + ring2 + ring3) * 0.05 * (1.0 - p * 0.5);
                vec2 dir = (d > 0.001) ? normalize(c) : vec2(0.0);
                vec2 distorted = clamp(uv + dir * ripple, vec2(0.0), vec2(1.0));

                vec3 tc = niri_geo_to_tex * vec3(distorted, 1.0);
                vec4 win = texture2D(niri_tex, tc.st);

                float reveal = smoothstep(0.05, -0.02, d - front);
                vec4 mixed = win * reveal;

                float in_bounds = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
                return mixed * in_bounds;
            }

void main() {
  fragColor = open_color(vec3(v_texcoord, 1.0), vec3(surface_size, 1.0));
}
