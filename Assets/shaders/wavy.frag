#version 450

layout(location = 0) in  vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float w;
    float cy;
    float activeW;
    vec4  activeColor;
    vec4  inactiveColor;
    float inactSt;
    float freq;
    float amp;
    float phase;
    float strokeHalf;
};

void main() {
    const float PI2    = 6.283185307;
    const float fringe = 1.0;

    float px = qt_TexCoord0.x * w;
    float py = qt_TexCoord0.y * (cy * 2.0);

    float waveY = cy + amp * sin((px / w) * PI2 * freq + phase);
    float dWave = abs(py - waveY);
    float waveA = smoothstep(strokeHalf + fringe,
                             max(strokeHalf - fringe, 0.0), dWave);
    waveA *= step(0.0, px) * step(px, activeW);

    float dFlat = abs(py - cy);
    float flatA = smoothstep(strokeHalf + fringe,
                             max(strokeHalf - fringe, 0.0), dFlat);
    flatA *= step(inactSt, px) * step(px, w);

    float aA = activeColor.a   * waveA * qt_Opacity;
    float iA = inactiveColor.a * flatA * qt_Opacity;

    fragColor = vec4(activeColor.rgb * aA, aA)
              + vec4(inactiveColor.rgb * iA, iA);
}
