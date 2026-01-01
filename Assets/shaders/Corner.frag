#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float radius;
    vec4 bgColor;
    int corner; // 0=topLeft, 1=topRight, 2=bottomLeft, 3=bottomRight
};

void main() {
    vec2 pos = qt_TexCoord0 * radius;
    vec2 cornerPos;

    if (corner == 0) {
        // Top-left inner
        cornerPos = vec2(0.0, 0.0);
    } else if (corner == 1) {
        // Top-right inner
        cornerPos = vec2(radius, 0.0);
    } else if (corner == 2) {
        // Bottom-left inner
        cornerPos = vec2(0.0, radius);
    } else if (corner == 3) {
        // Bottom-right inner
        cornerPos = vec2(radius, radius);
    }

    float dist = distance(pos, cornerPos);

    // Anti-aliasing
    float edgeWidth = 1.0;
    float alpha = smoothstep(radius - edgeWidth, radius + edgeWidth, dist);

    fragColor = bgColor * qt_Opacity * alpha;
}
