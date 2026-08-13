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

            // Ported from skwd-wall soft-warp-fade transition

            float swf_hash(vec2 p) {
                return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
            }

            float swf_noise(vec2 p) {
                vec2 i = floor(p);
                vec2 f = fract(p);
                f = f * f * (3.0 - 2.0 * f);
                return mix(mix(swf_hash(i), swf_hash(i + vec2(1.0, 0.0)), f.x),
                           mix(swf_hash(i + vec2(0.0, 1.0)), swf_hash(i + vec2(1.0, 1.0)), f.x), f.y);
            }

            vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                float p = niri_clamped_progress;
                vec2 uv = coords_geo.xy;

                float strength = sin(p * 3.14159) * 0.025;
                vec2 warp = vec2(
                    swf_noise(uv * 3.0 + vec2(0.0, p * 0.5)),
                    swf_noise(uv * 3.0 + vec2(p * 0.5, 0.0))
                ) - 0.5;
                vec2 warped = uv + warp * strength;

                vec3 tc = niri_geo_to_tex * vec3(warped, 1.0);
                vec4 win = texture2D(niri_tex, tc.st);

                float t = smoothstep(0.05, 0.95, p);
                t = t * t * (3.0 - 2.0 * t);
                return win * t;
            }

void main() {
  fragColor = open_color(vec3(v_texcoord, 1.0), vec3(surface_size, 1.0));
}
