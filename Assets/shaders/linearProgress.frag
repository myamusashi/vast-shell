#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float barStart;
    float barEnd;
    float cornerRadius;
    float waveAmplitude;
    float waveFrequency;
    float wavePhase;
    float trackHeight;
    vec2  resolution;
    vec4  indicatorColor;
};

void main() {
    float startX = max(0.0, barStart);
    float endX   = min(resolution.x, barEnd);
    float drawW  = endX - startX;
    if (drawW <= 0.0 || trackHeight <= 0.0 || indicatorColor.a <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    vec2  p       = qt_TexCoord0 * resolution;
    float centerY = resolution.y * 0.5;
    float halfH   = trackHeight * 0.5;
    float d       = 0.0;

    if (waveAmplitude <= 0.001) {
        vec2  halfSize = vec2(drawW * 0.5, halfH);
        float cr       = min(cornerRadius, min(halfSize.x, halfSize.y));
        vec2  q        = abs(p - vec2((startX + endX) * 0.5, centerY)) - halfSize + cr;
        d              = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - cr;
    } else {
        const float PI2 = 6.283185307179586;
        float k      = (PI2 * waveFrequency) / max(resolution.x, 1.0);
        float arg    = p.x * k + wavePhase;
        float wy     = centerY + waveAmplitude * sin(arg);
        float dy     = waveAmplitude * k * cos(arg);
        float dVert  = (abs(p.y - wy) - halfH) * inversesqrt(1.0 + dy * dy);
        float dHoriz = max(startX - p.x, p.x - endX);
        d            = max(dVert, dHoriz);
    }

    float cov = smoothstep(0.75, -0.75, d);
    fragColor = indicatorColor * cov * qt_Opacity;
}
