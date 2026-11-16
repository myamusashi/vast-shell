#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float pointCount;
    float lineWidth;
    float gridLines;
    vec2  resolution;
    vec4  lineColor;
    vec4  fillColor;
    vec4  gridColor;
    vec4  p0;
    vec4  p1;
    vec4  p2;
    vec4  p3;
    vec4  p4;
    vec4  p5;
    vec4  p6;
    vec4  p7;
};

float sampleAt(int idx) {
    int  v = idx >> 2;
    int  c = idx & 3;
    vec4 vecVal = (v == 0) ? p0 : (v == 1) ? p1 : (v == 2) ? p2 : (v == 3) ? p3 :
                  (v == 4) ? p4 : (v == 5) ? p5 : (v == 6) ? p6 : p7;
    return (c == 0) ? vecVal.x : (c == 1) ? vecVal.y : (c == 2) ? vecVal.z : vecVal.w;
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2  pa = p - a;
    vec2  ba = b - a;
    float h  = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
    return length(pa - ba * h);
}

vec2 pointAt(int idx, float stepX) {
    float x = float(idx) * stepX;
    float y = (1.0 - clamp(sampleAt(idx), 0.0, 1.0)) * resolution.y;
    return vec2(x, y);
}

void main() {
    if (resolution.x <= 0.0 || resolution.y <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    int   n     = clamp(int(pointCount + 0.5), 2, 32);
    vec2  px    = qt_TexCoord0 * resolution;
    float stepX = resolution.x / float(n - 1);
    int   i0    = clamp(int(floor(px.x / stepX)), 0, n - 2);

    vec2  a0    = pointAt(i0, stepX);
    vec2  a1    = pointAt(i0 + 1, stepX);
    float dMin  = sdSegment(px, a0, a1);

    if (i0 > 0)
        dMin = min(dMin, sdSegment(px, pointAt(i0 - 1, stepX), a0));
    if (i0 + 2 < n)
        dMin = min(dMin, sdSegment(px, a1, pointAt(i0 + 2, stepX)));

    float hw         = lineWidth * 0.5;
    float strokeCov  = smoothstep(hw + 0.75, max(hw - 0.75, 0.0), dMin);

    float segT       = clamp((px.x - a0.x) / max(stepX, 1e-5), 0.0, 1.0);
    float curveY     = mix(a0.y, a1.y, segT);
    float fillCov    = smoothstep(-0.75, 0.75, px.y - curveY);

    float gridCov = 0.0;
    if (gridLines > 0.0 && gridColor.a > 0.0) {
        float spacingY = resolution.y / gridLines;
        float modY     = mod(px.y, spacingY);
        float dGridY   = min(modY, spacingY - modY);
        if (px.y > 1.0 && px.y < resolution.y - 1.0)
            gridCov = smoothstep(0.75, 0.0, dGridY);
    }

    vec4 col = vec4(gridColor.rgb * gridColor.a, gridColor.a) * gridCov;

    float fa = fillColor.a * fillCov;
    vec4  fc = vec4(fillColor.rgb * fa, fa);
    col      = fc + col * (1.0 - fc.a);

    float sa = lineColor.a * strokeCov;
    vec4  sc = vec4(lineColor.rgb * sa, sa);
    col      = sc + col * (1.0 - sc.a);

    fragColor = col * qt_Opacity;
}
