#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float progress;
    float startAngleDeg;
    float maxSweepDeg;
    float radius;
    float strokeWidth;
    vec2  resolution;
    vec4  trackColor;
    vec4  activeColor;
};

float arcSDF(vec2 p, float lenP, float deg, float r, float startDeg, float sweepDeg, float hw) {
    float sw = clamp(sweepDeg, 0.0, 360.0);
    if (sw <= 0.0 || r <= 0.0)
        return 1e6;

    if (sw >= 359.999)
        return abs(lenP - r) - hw;

    float rel = mod(deg - startDeg, 360.0);
    if (rel <= sw)
        return abs(lenP - r) - hw;

    float rad0 = radians(startDeg);
    float rad1 = radians(startDeg + sw);
    vec2  p0   = r * vec2(cos(rad0), sin(rad0));
    vec2  p1   = r * vec2(cos(rad1), sin(rad1));
    return min(length(p - p0), length(p - p1)) - hw;
}

void main() {
    vec2  p    = (qt_TexCoord0 - 0.5) * resolution;
    float lenP = length(p);
    float deg  = (lenP > 1e-4) ? degrees(atan(p.y, p.x)) : 0.0;
    float hw   = strokeWidth * 0.5;

    float dTrack  = arcSDF(p, lenP, deg, radius, startAngleDeg, maxSweepDeg, hw);
    float dActive = arcSDF(p, lenP, deg, radius, startAngleDeg, maxSweepDeg * clamp(progress, 0.0, 1.0), hw);

    float trackCov  = smoothstep(0.75, -0.75, dTrack);
    float activeCov = smoothstep(0.75, -0.75, dActive);

    vec4 tCol = trackColor  * trackCov;
    vec4 aCol = activeColor * activeCov;

    fragColor = (aCol + tCol * (1.0 - aCol.a)) * qt_Opacity;
}
