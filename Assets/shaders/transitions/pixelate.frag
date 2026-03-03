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
    vec2  uv   = texCoord;
    float p    = ubuf.progress;
    float ramp = (p < 0.5) ? p * 2.0 : (1.0 - p) * 2.0;
    float bsz  = max(1.0, ramp * 48.0);

    vec2 uv2 = (floor(uv * ubuf.resolution / bsz) * bsz + 0.5)
               * ubuf.invResolution;

    vec3 col = mix(
        texture(source1, uv2).rgb,
        texture(source2, uv2).rgb,
        p
    );
    fragColor = vec4(col, 1.0) * ubuf.qt_Opacity;
}
