#version 450

layout(location = 0) in  vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;     // offset  0  (64 B)
    float qt_Opacity;    // offset 64  (4 B)
    float w;             // offset 68  (4 B)
    float bl;            // offset 72  (4 B)
    float amp;           // offset 76  (4 B)
    vec4  activeColor;   // offset 80
    vec4  inactiveColor; // offset 96
    float aEnd;
    float iSt;
    float pos;
    float phase;
    float freq;
    float pow_;
    float floor_;
    float ramp;
    float rampIn;
    float tr;
    float strokeHalf;
};

float waveHeight(float px) {
    const float PI2 = 6.283185307;
    float t         = px / w;
    float raw       = (1.0 + sin(t * PI2 * freq + phase)) * 0.4;
    float shaped    = pow(raw, pow_);
    float available = pos;
    float total     = ramp + rampIn;
    float scale     = (total > available && total > 0.0) ? available / total : 1.0;
    float rampR     = ramp   * scale;
    float rampL     = rampIn * scale;
    float envR      = clamp((pos - t) / rampR, 0.0, 1.0);
    float smoothR   = envR * envR * (3.0 - 2.0 * envR);
    float envL      = clamp(t / rampL,          0.0, 1.0);
    float smoothL   = envL * envL * (3.0 - 2.0 * envL);
    float env       = smoothR * smoothL;
    float fl        = floor_ * (1.0 - smoothR * 0.5);
    return (fl + (1.0 - fl) * shaped) * env * amp * tr;
}

void main() {
    const float fringe = 1.0;
    float H  = bl * 2.0;
    float px = qt_TexCoord0.x * w;
    float py = qt_TexCoord0.y * H;

    if (px >= iSt && px <= w) {
        float d  = abs(py - bl);
        float a  = smoothstep(strokeHalf + fringe,
                              max(strokeHalf - fringe, 0.0), d);
        float fa = inactiveColor.a * a * 0.55 * qt_Opacity;
        fragColor = vec4(inactiveColor.rgb * fa, fa);
        return;
    }

    if (px < 0.0 || px > aEnd) { fragColor = vec4(0.0); return; }

    float wy       = waveHeight(px);
    float waveTopY = bl - wy;

    float fillA = 0.0;
    if (py >= waveTopY && py <= bl && wy > 0.001) {
        float t = (py - waveTopY) / (bl - waveTopY);
        fillA = mix(0.90, 0.68, t);
    }
    float aboveEdge = waveTopY - py;
    if (aboveEdge > 0.0 && aboveEdge < fringe)
        fillA = mix(fillA, 0.0, aboveEdge / fringe);

    float dTop  = abs(py - waveTopY);
    float topA  = smoothstep(strokeHalf + fringe,
                             max(strokeHalf - fringe, 0.0), dTop);

    float fillFinalA   = activeColor.a * fillA * qt_Opacity;
    float strokeFinalA = topA * qt_Opacity;

    vec4 fill   = vec4(activeColor.rgb * fillFinalA,   fillFinalA);
    vec4 stroke = vec4(activeColor.rgb * strokeFinalA, strokeFinalA);

    fragColor = stroke + fill * (1.0 - topA);
}
