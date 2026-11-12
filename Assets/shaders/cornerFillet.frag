#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float corner;
    float radius;
    vec2  resolution;
    vec4  fillColor;
};

void main() {
    if (radius <= 0.0 || fillColor.a <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 p = qt_TexCoord0 * resolution;
    int  c = int(corner + 0.5);
    if (c == 1 || c == 2) p.x = resolution.x - p.x;
    if (c == 2 || c == 3) p.y = resolution.y - p.y;

    float d   = length(p - vec2(radius)) - radius;
    float cov = smoothstep(-0.75, 0.75, d);

    fragColor = fillColor * cov * qt_Opacity;
}
