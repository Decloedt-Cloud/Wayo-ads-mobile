#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

// Brand orange #F47A1F
const vec3 kOrange = vec3(0.95686, 0.47843, 0.12157);
const vec3 kDark = vec3(0.0392, 0.0392, 0.0392);

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
  for (int i = 0; i < 4; i++) {
    v += a * sin(p.x * 3.1 + uTime * 0.35) * sin(p.y * 2.7 - uTime * 0.28);
    p = rot * p * 2.02 + vec2(0.4, 0.1);
    a *= 0.5;
  }
  return v;
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / uSize;
  vec2 p = uv * 2.0 - 1.0;
  float r = length(p);

  vec2 flow = vec2(
    sin(uv.y * 6.283 + uTime * 0.6),
    cos(uv.x * 6.283 - uTime * 0.45)
  );
  float metal = fbm(uv * 3.2 + flow * 0.08) * 0.5 + 0.5;
  float vignette = smoothstep(1.15, 0.35, r);
  float sheen = pow(max(0.0, sin(dot(uv, vec2(12.0, 9.0)) + uTime * 1.1)), 8.0) * 0.35;

  vec3 base = mix(kDark, vec3(0.09, 0.09, 0.09), vignette * 0.6);
  vec3 accent = kOrange * (0.08 + metal * 0.12 + sheen);
  vec3 col = base + accent * (0.55 + 0.45 * (1.0 - r));

  fragColor = vec4(col, 1.0);
}
