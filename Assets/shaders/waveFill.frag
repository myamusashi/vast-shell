#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float fillPercentage;
    float amplitude;
    float wavelength;
    vec2  resolution;
    vec4  waveColor;
};

void main() {
    float pct = clamp(fillPercentage, 0.0, 100.0);
    if (pct <= 0.0 || waveColor.a <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    const float PI2 = 6.283185307179586;
    vec2  p        = qt_TexCoord0 * resolution;
    float fillH    = resolution.y * (pct / 100.0);
    float waveY    = resolution.y - fillH;
    float k        = PI2 / max(wavelength, 1.0);
    float surfaceY = waveY + amplitude * sin(p.x * k);
    float slope    = amplitude * k * cos(p.x * k);
    float d        = (surfaceY - p.y) * inversesqrt(1.0 + slope * slope);

    float cov = smoothstep(0.75, -0.75, d);
    fragColor = waveColor * cov * qt_Opacity;
}
