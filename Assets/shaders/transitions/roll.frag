#version 450

layout(location = 0) noperspective in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform FragBuf {
    mat4  qt_Matrix;     // offset  0
    float qt_Opacity;    // offset 64
    float progress;      // offset 68
    float smoothAmount;  // offset 72
    float aspect;        // offset 76
    vec2  resolution;    // offset 80
    vec2  invResolution; // offset 88
    float rollCos;       // offset 96
    float rollSin;       // offset 100
} ubuf;

layout(binding = 1) uniform sampler2D source1;
layout(binding = 2) uniform sampler2D source2;

void main() {
    vec2  uv  = texCoord;
    vec2  res = ubuf.resolution;
    float rx  = (1.0 - uv.x) * res.x;
    float ry  =        uv.y   * res.y;
    vec2  rot = vec2(
        rx * ubuf.rollCos - ry * ubuf.rollSin,
        rx * ubuf.rollSin + ry * ubuf.rollCos
    );

    bool inBounds = rot.x >= 0.0 && rot.x < res.x
                 && rot.y >= 0.0 && rot.y < res.y;

    vec3 col = inBounds
        ? texture(source1, vec2(1.0 - rot.x, rot.y) * ubuf.invResolution).rgb
        : texture(source2, uv).rgb;

    fragColor = vec4(col, 1.0) * ubuf.qt_Opacity;
}
