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

    if (corner == 0) cornerPos = vec2(0.0, 0.0);
    else if (corner == 1) cornerPos = vec2(radius, 0.0);
    else if (corner == 2) cornerPos = vec2(0.0, radius);
    else if (corner == 3) cornerPos = vec2(radius, radius);

    float dist = distance(pos, cornerPos);

    // Adaptive edge width based on screen-space derivatives
    float edgeWidth = length(vec2(dFdx(dist), dFdy(dist))) * 1.5;

    float t = clamp((dist - radius + edgeWidth) / (2.0 * edgeWidth), 0.0, 1.0);
    float alpha = t * t * t * (t * (t * 6.0 - 15.0) + 10.0);

    fragColor = bgColor * qt_Opacity * alpha;
}
