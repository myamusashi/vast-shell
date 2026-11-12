#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float progress;
    float bodySize;
    vec2  resolution;
    vec4  hillColor;
    vec4  bodyColor;
};

vec2 cubicBezier(vec2 p0, vec2 p1, vec2 p2, vec2 p3, float t) {
    float u = 1.0 - t;
    return (u * u * u) * p0
         + (3.0 * u * u * t) * p1
         + (3.0 * u * t * t) * p2
         + (t * t * t) * p3;
}

vec2 cubicBezierDeriv(vec2 p0, vec2 p1, vec2 p2, vec2 p3, float t) {
    float u = 1.0 - t;
    return (3.0 * u * u) * (p1 - p0)
         + (6.0 * u * t) * (p2 - p1)
         + (3.0 * t * t) * (p3 - p2);
}

void main() {
    vec2  p         = qt_TexCoord0 * resolution;
    float hillH     = resolution.y * 0.6;
    float hillBaseY = resolution.y - hillH;

    vec2 p0 = vec2(0.0,               hillBaseY + hillH * 0.3);
    vec2 p1 = vec2(resolution.x * 0.3, hillBaseY - hillH * 0.1);
    vec2 p2 = vec2(resolution.x * 0.7, hillBaseY - hillH * 0.1);
    vec2 p3 = vec2(resolution.x,       hillBaseY + hillH * 0.3);

    float t = clamp(p.x / max(resolution.x, 1.0), 0.0, 1.0);
    for (int i = 0; i < 5; i++) {
        vec2  pos = cubicBezier(p0, p1, p2, p3, t);
        vec2  drv = cubicBezierDeriv(p0, p1, p2, p3, t);
        t = clamp(t - (pos.x - p.x) / max(drv.x, 1e-4), 0.0, 1.0);
    }

    vec2  hillPt  = cubicBezier(p0, p1, p2, p3, t);
    vec2  hillDrv = cubicBezierDeriv(p0, p1, p2, p3, t);
    float dy      = hillDrv.y / max(hillDrv.x, 1e-4);
    float dHill   = (hillPt.y - p.y) * inversesqrt(1.0 + dy * dy);
    float hillCov = smoothstep(0.75, -0.75, dHill);

    vec2  bodyPos = cubicBezier(p0, p1, p2, p3, clamp(progress, 0.0, 1.0));
    float dBody   = length(p - bodyPos) - (bodySize * 0.5 + 1.0);
    float bodyCov = smoothstep(0.75, -0.75, dBody);

    vec4 hCol = hillColor * hillCov;
    vec4 bCol = bodyColor * bodyCov;

    fragColor = (bCol + hCol * (1.0 - bCol.a)) * qt_Opacity;
}
