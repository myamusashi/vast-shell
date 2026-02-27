#version 440

// Compile with:
//   qsb --glsl "450" --hlsl 50 --msl 12 -o transition.frag.qsb transition.frag
//
// Transitions:
//   0 – Fade              Classic alpha cross-dissolve
//   1 – Wipe Down         Top-to-bottom wipe with soft feathered edge
//   2 – Circle Expand     Circle grows from screen centre (soft edge)
//   3 – Dissolve          Random noise per-pixel dissolve
//   4 – Split Horizontal  Two halves split open from centre row
//   5 – Slide Up          Old image slides upward, new revealed below
//   6 – Pixelate          Pixelation blur peaks at mid-transition
//   7 – Diagonal Wipe     Band sweeps top-left → bottom-right
//   8 – Box Expand        Rectangle grows from screen centre (soft edge)
//   9 – Roll              Page-roll cylinder sweeps from right edge

layout(location = 0) in  vec2 texCoord;
layout(location = 0) out vec4 fragColor;

// ── Uniform Buffer Object ────────────────────────────────────────────────────
// qt_Matrix / qt_Opacity MUST be first two members – Qt 6 requirement.
// All custom uniforms follow in the SAME std140 block.
layout(std140, binding = 0) uniform FragBuf {
    mat4  qt_Matrix;         // (filled by Qt, unused in fragment)
    float qt_Opacity;        // global opacity from ShaderEffect

    float progress;          // 0.0 → 1.0
    int   transitionType;    // 0 – 9
    float smoothAmount;      // soft-edge width  (0.0 – 0.15)
    float aspect;            // height / width
    vec2  resolution;        // viewport size in pixels
} ubuf;

// ── Texture Samplers ─────────────────────────────────────────────────────────
// Binding indices start at 1 (binding 0 is taken by the UBO above).
layout(binding = 1) uniform sampler2D source1;   // "from" wallpaper
layout(binding = 2) uniform sampler2D source2;   // "to"   wallpaper

// ── Constants ────────────────────────────────────────────────────────────────
#define M_PI    3.141592654
#define _TWOPI  6.283185307

// ── Helper: line-segment ray intersection ────────────────────────────────────
// Returns t ≥ 0 along direction d from origin o that hits segment p1→p2,
// or −1000.0 if there is no valid intersection.
float raySegment(vec2 o, vec2 d, vec2 p1, vec2 p2) {
    vec2  v1 = o  - p1;
    vec2  v2 = p2 - p1;
    vec2  v3 = vec2(-d.y, d.x);
    float dt = dot(v2, v3);
    if (abs(dt) < 1e-6) return -1000.0;
    float t1 = (v2.x * v1.y - v2.y * v1.x) / dt;
    float t2 = dot(v1, v3) / dt;
    if (t1 >= 0.0 && t2 >= 0.0 && t2 <= 1.0) return t1;
    return -1000.0;
}

// ── Main ──────────────────────────────────────────────────────────────────────
void main() {
    vec2  uv   = texCoord;                          // (0,0) TL → (1,1) BR
    vec2  uv2;
    float p    = clamp(ubuf.progress,     0.0, 1.0);
    float sa   = ubuf.smoothAmount;
    float asp  = ubuf.aspect;
    vec2  res  = max(ubuf.resolution, vec2(1.0));

    vec3 col1 = texture(source1, uv).rgb;
    vec3 col2 = texture(source2, uv).rgb;
    vec3 col;

    // ── 0: Fade ───────────────────────────────────────────────────────────────
    if (ubuf.transitionType == 0) {
        col = mix(col1, col2, p);
    }

    // ── 1: Wipe Down (soft feathered edge) ───────────────────────────────────
    // A horizontal band advances downward. Above the band = old image,
    // below = new image, inside = soft blend.
    else if (ubuf.transitionType == 1) {
        float edge = 1.0 - p;
        if      (uv.y <= edge)      col = col1;
        else if (uv.y >= edge + sa) col = col2;
        else                        col = mix(col1, col2, (uv.y - edge) / sa);
    }

    // ── 2: Circle Expand (soft edge) ─────────────────────────────────────────
    // A circle centred at (0.5, 0.5) expands from radius 0 to cover the frame.
    else if (ubuf.transitionType == 2) {
        // max radius needed to cover all 4 corners
        float maxR = sqrt(0.25 / (asp * asp) + 0.25);
        float rad  = maxR * p;
        vec2  d    = vec2((uv.x - 0.5) / asp, uv.y - 0.5);
        float r    = length(d);
        if      (r >= rad + sa) col = col1;
        else if (r >= rad)      col = mix(col2, col1, (r - rad) / sa);
        else                    col = col2;
    }

    // ── 3: Dissolve ───────────────────────────────────────────────────────────
    // Each pixel gets a pseudo-random threshold; it switches to the new image
    // once progress exceeds its threshold — giving a random scatter dissolve.
    else if (ubuf.transitionType == 3) {
        float noise = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
        col = (p > noise) ? col2 : col1;
    }

    // ── 4: Split Horizontal (open from centre) ────────────────────────────────
    // The frame splits along the horizontal centre line; the top half slides up
    // and the bottom half slides down, revealing the new image.
    else if (ubuf.transitionType == 4) {
        float halfOff = 0.5 * p;
        if (uv.y < 0.5 - halfOff || uv.y >= 0.5 + halfOff) col = col1;
        else                                                  col = col2;
    }

    // ── 5: Slide Up ───────────────────────────────────────────────────────────
    // The old image physically slides upward; the new image is revealed below.
    else if (ubuf.transitionType == 5) {
        if (uv.y >= 1.0 - p) {
            col = col2;
        } else {
            uv2 = vec2(uv.x, uv.y + p);
            col = texture(source1, uv2).rgb;
        }
    }

    // ── 6: Pixelate ───────────────────────────────────────────────────────────
    // Block size ramps up to a peak at p=0.5, then back down. The blended
    // pixelated textures cross-fade simultaneously.
    else if (ubuf.transitionType == 6) {
        float ramp = (p < 0.5) ? p * 2.0 : (1.0 - p) * 2.0;
        float bsz  = max(1.0, ramp * 60.0);
        uv2.x = (floor(uv.x * res.x / bsz) * bsz + 0.5) / res.x;
        uv2.y = (floor(uv.y * res.y / bsz) * bsz + 0.5) / res.y;
        col   = mix(texture(source1, uv2).rgb,
                    texture(source2, uv2).rgb, p);
    }

    // ── 7: Diagonal Wipe (top-left → bottom-right) ───────────────────────────
    // A diagonal band (45°) sweeps across the frame.
    else if (ubuf.transitionType == 7) {
        float diag = uv.x + uv.y;          // 0 (TL) → 2 (BR)
        float edge = p * 2.0;
        if      (diag < edge - sa) col = col2;
        else if (diag < edge)      col = mix(col1, col2, (diag - (edge - sa)) / sa);
        else                       col = col1;
    }

    // ── 8: Box Expand (soft edge) ─────────────────────────────────────────────
    // A rectangle centred at (0.5, 0.5) grows outward to fill the frame.
    else if (ubuf.transitionType == 8) {
        vec2  d2       = abs(uv - 0.5);
        float halfSize  = 0.5 * p;
        float halfSizeS = halfSize + sa;

        if      (d2.x <= halfSize  && d2.y <= halfSize) {
            col = col2;
        } else if (d2.x <= halfSizeS && d2.y <= halfSizeS) {
            float blend = max(
                (d2.x > halfSize ? d2.x - halfSize : 0.0),
                (d2.y > halfSize ? d2.y - halfSize : 0.0)
            ) / sa;
            col = mix(col2, col1, clamp(blend, 0.0, 1.0));
        } else {
            col = col1;
        }
    }

    // ── 9: Roll (page-roll from right edge) ───────────────────────────────────
    // The old image appears to curl around a vertical cylinder that sweeps
    // left to right, peeling back to reveal the new image beneath.
    else if (ubuf.transitionType == 9) {
        float theta = (M_PI / 2.0) * p;
        float c1    = cos(theta);
        float s1    = sin(theta);

        // Rotate pixels around the right edge (1-uv.x is distance from right)
        float rx = (1.0 - uv.x) * res.x;
        float ry =        uv.y   * res.y;
        uv2.x = rx * c1 - ry * s1;
        uv2.y = rx * s1 + ry * c1;

        if (uv2.x >= 0.0 && uv2.x < res.x &&
            uv2.y >= 0.0 && uv2.y < res.y) {
            uv2 /= res;
            uv2.x = 1.0 - uv2.x;          // mirror back to original orientation
            col   = texture(source1, uv2).rgb;
        } else {
            col = col2;
        }
    }

    // ── Fallback ──────────────────────────────────────────────────────────────
    else {
        col = mix(col1, col2, p);
    }

    fragColor = vec4(col * ubuf.qt_Opacity, ubuf.qt_Opacity);
}
