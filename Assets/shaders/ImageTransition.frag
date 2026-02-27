#version 440

// Transitions:
//   0 – Fade              Classic
//   1 – Wipe Down         Top-to-bottom wipe
//   2 – Circle Expand     Circle grows from screen centre
//   3 – Dissolve          Random noise per-pixel dissolve
//   4 – Split Horizontal  Two halves split open from centre row
//   5 – Slide Up          Old image slides upward, new revealed below
//   6 – Pixelate          Pixelation blur peaks at mid-transition
//   7 – Diagonal Wipe     Band sweeps top-left → bottom-right
//   8 – Box Expand        Rectangle grows from screen centre (soft edge)
//   9 – Roll              Page-roll cylinder sweeps from right edge

layout(location = 0) noperspective in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform FragBuf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float progress;
    int   transitionType;
    float smoothAmount;
    float aspect;
    vec2  resolution;
} ubuf;

layout(binding = 1) uniform sampler2D source1;
layout(binding = 2) uniform sampler2D source2;

#define M_HALF_PI 1.5707963268

float hash21(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

void main() {
    vec2  uv = texCoord;
    float p  = clamp(ubuf.progress, 0.0, 1.0);
    float sa = ubuf.smoothAmount;
    vec3  col;

    // 0. Fade
    if (ubuf.transitionType == 0) {
        col = mix(texture(source1, uv).rgb,
                  texture(source2, uv).rgb, p);
    }

    // 1. Wipe Down
    else if (ubuf.transitionType == 1) {
        float edge = 1.0 - p;
        float t    = smoothstep(edge, edge + sa, uv.y);
        col = mix(texture(source1, uv).rgb,
                  texture(source2, uv).rgb, t);
    }

    // 2. Circle Expand
    else if (ubuf.transitionType == 2) {
        float asp  = ubuf.aspect;
        float maxR = sqrt(0.25 / (asp * asp) + 0.25);
        float r    = length(vec2((uv.x - 0.5) / asp, uv.y - 0.5));
        float rad  = maxR * p;
        float t    = smoothstep(rad + sa, rad, r);
        col = mix(texture(source1, uv).rgb,
                  texture(source2, uv).rgb, t);
    }

    // 3. Dissolve
    else if (ubuf.transitionType == 3) {
        float noise = hash21(uv);
        col = (p > noise)
            ? texture(source2, uv).rgb
            : texture(source1, uv).rgb;
    }

    // 4. Split Horizontal
    else if (ubuf.transitionType == 4) {
        float halfOff = 0.5 * p;
        col = (uv.y < 0.5 - halfOff || uv.y >= 0.5 + halfOff)
            ? texture(source1, uv).rgb
            : texture(source2, uv).rgb;
    }

    // 5. Slide Up
    else if (ubuf.transitionType == 5) {
        col = (uv.y >= 1.0 - p)
            ? texture(source2, uv).rgb
            : texture(source1, vec2(uv.x, uv.y + p)).rgb;
    }

    // 6. Pixelate
    else if (ubuf.transitionType == 6) {
        vec2  res  = max(ubuf.resolution, vec2(1.0));
        vec2  iRes = 1.0 / res;
        float ramp = (p < 0.5) ? p * 2.0 : (1.0 - p) * 2.0;
        float bsz  = max(1.0, ramp * 48.0);
        vec2  uv2  = (floor(uv * res / bsz) * bsz + 0.5) * iRes;
        col = mix(texture(source1, uv2).rgb,
                  texture(source2, uv2).rgb, p);
    }

    // 7. Diagonal Wipe
    else if (ubuf.transitionType == 7) {
        float diag = uv.x + uv.y;
        float edge = p * 2.0;
        float t    = smoothstep(edge - sa, edge, diag);
        col = mix(texture(source1, uv).rgb,
                  texture(source2, uv).rgb, t);
    }

    // 8. Box Expand
    else if (ubuf.transitionType == 8) {
        float maxD = max(abs(uv.x - 0.5), abs(uv.y - 0.5));
        float hs   = 0.5 * p;
        float t    = smoothstep(hs + sa, hs, maxD);
        col = mix(texture(source1, uv).rgb,
                  texture(source2, uv).rgb, t);
    }

    // 9. Roll
    else if (ubuf.transitionType == 9) {
        vec2  res  = max(ubuf.resolution, vec2(1.0));
        vec2  iRes = 1.0 / res;
        float theta = M_HALF_PI * p;
        float c1    = cos(theta);
        float s1    = sin(theta);
        float rx    = (1.0 - uv.x) * res.x;
        float ry    =        uv.y   * res.y;
        vec2  rot   = vec2(rx * c1 - ry * s1,
                           rx * s1 + ry * c1);
        col = (rot.x >= 0.0 && rot.x < res.x &&
               rot.y >= 0.0 && rot.y < res.y)
            ? texture(source1, vec2(1.0 - rot.x, rot.y) * iRes).rgb 
            : texture(source2, uv).rgb;
    }

    // fallback
    else {
        col = mix(texture(source1, uv).rgb,
                  texture(source2, uv).rgb, p);
    }

    fragColor = vec4(col * ubuf.qt_Opacity, ubuf.qt_Opacity);
}
