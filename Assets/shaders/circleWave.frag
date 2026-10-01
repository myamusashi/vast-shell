#version 450

layout(location = 0) noperspective in vec2 texCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float progress;        
    float radius;          
    float strokeHalfWidth;
    vec2  resolution;
    vec4  activeColor;
    vec4  inactiveColor;
    float waveFrequency;   
    float waveAmplitude;   
    float wavePhase;       
    float trackGap;        
};

const float PI2    = 6.283185307179586;
const float FRINGE = 1.0;
const float FAR    = 1e9;

float coverage(float d, float hw) {
    return smoothstep(hw + FRINGE, max(hw - FRINGE, 0.0), d);
}

vec2 circlePoint(float rad, float t) {
    float a = t * PI2;
    return rad * vec2(sin(a), cos(a));
}

void main() {
    vec2 p = (texCoord - 0.5) * resolution;
    p.y = -p.y;

    float r = length(p);
    float t = fract(atan(p.x, p.y) / PI2);


    float ramp = clamp(min(progress / 0.1, (1.0 - progress) / 0.05), 0.0, 1.0);
    float amp  = waveAmplitude * ramp;

    float activeA = 0.0;
    if (progress > 0.0) {
        float ph    = t * PI2 * waveFrequency + wavePhase;
        float waveR = radius + amp * sin(ph);

        float slope = amp * waveFrequency * cos(ph) / max(r, 1.0);
        float dWave = abs(r - waveR) * inversesqrt(1.0 + slope * slope);

        float d = FAR;
        if (t <= progress) d = dWave;

        if (progress < 1.0) {
            float aStart = wavePhase;
            float aEnd   = progress * PI2 * waveFrequency + wavePhase;
            vec2 capStart = circlePoint(radius + amp * sin(aStart), 0.0);
            vec2 capEnd   = circlePoint(radius + amp * sin(aEnd), progress);
            d = min(d, min(length(p - capStart), length(p - capEnd)));
        }
        activeA = coverage(d, strokeHalfWidth);
    }

    float inactiveA = 0.0;
    if (progress <= 0.0) {
        inactiveA = coverage(abs(r - radius), strokeHalfWidth);
    } else if (progress < 1.0) {
        float g  = (trackGap + 2.0 * strokeHalfWidth) / (radius * PI2);
        float a0 = progress + g;
        float a1 = 1.0 - g;
        if (a1 > a0) {
            float d = FAR;
            if (t >= a0 && t <= a1) d = abs(r - radius);
            d = min(d, min(length(p - circlePoint(radius, a0)),
                           length(p - circlePoint(radius, a1))));
            inactiveA = coverage(d, strokeHalfWidth);
        }
    }

    float aA = activeColor.a   * activeA   * qt_Opacity;
    float iA = inactiveColor.a * inactiveA * qt_Opacity;

    fragColor = vec4(activeColor.rgb * aA, aA) + vec4(inactiveColor.rgb * iA, iA);
}
