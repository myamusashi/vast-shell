#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float isHorizontal;
    vec2  resolution;
    vec4  fillColor;
};

float sdTriangle(vec2 p, vec2 p0, vec2 p1, vec2 p2) {
    vec2  e0  = p1 - p0;
    vec2  e1  = p2 - p1;
    vec2  e2  = p0 - p2;
    vec2  v0  = p  - p0;
    vec2  v1  = p  - p1;
    vec2  v2  = p  - p2;
    vec2  pq0 = v0 - e0 * clamp(dot(v0, e0) / max(dot(e0, e0), 1e-6), 0.0, 1.0);
    vec2  pq1 = v1 - e1 * clamp(dot(v1, e1) / max(dot(e1, e1), 1e-6), 0.0, 1.0);
    vec2  pq2 = v2 - e2 * clamp(dot(v2, e2) / max(dot(e2, e2), 1e-6), 0.0, 1.0);
    float s   = sign(e0.x * e2.y - e0.y * e2.x);
    vec2  d   = min(min(vec2(dot(pq0, pq0), s * (v0.x * e0.y - v0.y * e0.x)),
                        vec2(dot(pq1, pq1), s * (v1.x * e1.y - v1.y * e1.x))),
                        vec2(dot(pq2, pq2), s * (v2.x * e2.y - v2.y * e2.x)));
    return -sqrt(d.x) * sign(d.y);
}

void main() {
    vec2 p  = qt_TexCoord0 * resolution;
    vec2 p0 = vec2(0.0, 0.0);
    vec2 p1 = (isHorizontal > 0.5) ? vec2(resolution.x, 0.0) : vec2(0.0, resolution.y);
    vec2 p2 = (isHorizontal > 0.5) ? vec2(resolution.x * 0.5, resolution.y) : vec2(resolution.x, resolution.y * 0.5);

    float d   = sdTriangle(p, p0, p1, p2);
    float cov = smoothstep(0.75, -0.75, d);
    fragColor = fillColor * cov * qt_Opacity;
}
