#version 460 core
#include <flutter/runtime_effect.glsl>
// Copyright 2026, Rebar Ahmad. Licensed under the package's MIT License.
//
// One axis of a SEPARABLE gaussian, used twice (horizontal then vertical) via
// ImageFilter.compose to build a full, clean 2-D gaussian in O(σ) work per pass
// instead of the O(σ²) a single-pass disk needs (a disk either streaks with too
// few taps or turns to noise with importance sampling — this avoids both).
//
// The blur radius follows a gradient (strong at one edge, easing to sharp at the
// other). The bound texture is the whole backdrop (screen), so the gradient is
// normalised over the widget's own device-pixel rectangle passed from Dart.

uniform vec2 uSize;          // 0,1  bound-texture size, device px (engine)
uniform float uMaxSigma;     // 2    sigma at the strong edge, device px
uniform float uFalloff;      // 3    gradient gamma
uniform float uDirection;    // 4    strong edge: 0 top,1 bottom,2 left,3 right
uniform float uAxis;         // 5    blur axis: 0 = X (horizontal), 1 = Y (vertical)
uniform vec2 uRegionOriginPx;// 6,7  region top-left, device px
uniform vec2 uRegionSizePx;  // 8,9  region size, device px
uniform sampler2D uTexture;  //      input (backdrop for pass 1, pass-1 out for pass 2)

out vec4 fragColor;

// Half-kernel taps per side. Taps are placed with a stride that covers ±3σ, and
// the sampler's bilinear filtering smooths between them — enough for a clean
// gaussian at the gentle sigmas we use.
const int kHalf = 48;

void main() {
  // Gradient sigma from the fragment's position within the region.
  vec2 rn = clamp(
      (FlutterFragCoord().xy - uRegionOriginPx) / uRegionSizePx, 0.0, 1.0);
  float g;
  if (uDirection < 0.5)      g = rn.y;        // strong TOP
  else if (uDirection < 1.5) g = 1.0 - rn.y;  // strong BOTTOM
  else if (uDirection < 2.5) g = rn.x;        // strong LEFT
  else                       g = 1.0 - rn.x;  // strong RIGHT
  float sigma = uMaxSigma * pow(1.0 - g, uFalloff);

  // Screen-normalised sampling UV (GLES captures the backdrop y-flipped).
  vec2 uv = FlutterFragCoord().xy / uSize;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif

  if (sigma < 0.5) {
    fragColor = texture(uTexture, uv);
    return;
  }

  // 1px step in uv along the blur axis.
  vec2 axis = (uAxis < 0.5) ? vec2(1.0 / uSize.x, 0.0) : vec2(0.0, 1.0 / uSize.y);
  float stride = max(1.0, 3.0 * sigma / float(kHalf)); // device px between taps
  float inv2s2 = 1.0 / (2.0 * sigma * sigma);

  vec4 acc = texture(uTexture, uv); // centre tap, weight 1
  float wsum = 1.0;
  for (int i = 1; i <= kHalf; i++) {
    float d = float(i) * stride;      // device px offset
    float w = exp(-d * d * inv2s2);
    vec2 off = axis * d;              // uv offset
    vec2 sp = uv + off;
    vec2 sm = uv - off;
    // Discard out-of-bounds taps (clamping would smear the edge pixel).
    float ip = step(0.0, sp.x) * step(sp.x, 1.0) * step(0.0, sp.y) * step(sp.y, 1.0);
    float im = step(0.0, sm.x) * step(sm.x, 1.0) * step(0.0, sm.y) * step(sm.y, 1.0);
    acc += texture(uTexture, clamp(sp, 0.0, 1.0)) * (w * ip);
    acc += texture(uTexture, clamp(sm, 0.0, 1.0)) * (w * im);
    wsum += w * ip + w * im;
  }

  fragColor = acc / wsum;
}
