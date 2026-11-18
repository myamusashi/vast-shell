#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float dockLength;
    float dockDepth;
    float panelLength;
    float panelDepth;
    float cornerRadius;
    float filletRadius;
    float stepFilletRadius;
    float borderOverlap;
    vec2  resolution;
    vec4  fillColor;
};

float sdBox(vec2 p, vec2 bMin, vec2 bMax) {
    vec2 c = 0.5 * (bMin + bMax);
    vec2 h = 0.5 * (bMax - bMin);
    vec2 q = abs(p - c) - h;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

// Symmetric around x = 0 (half-width w), with independent top and bottom corner radii.
float sdRoundedBoxHalf(vec2 p, float halfW, float yMin, float yMax, float rTop, float rBottom) {
    vec2  c        = vec2(0.0, 0.5 * (yMin + yMax));
    vec2  halfSize = vec2(halfW, 0.5 * (yMax - yMin));
    vec2  q        = p - c;
    float r        = (q.y < 0.0) ? rTop : rBottom;
    vec2  b        = abs(q) - halfSize + r;
    return length(max(b, 0.0)) + min(max(b.x, b.y), 0.0) - r;
}

float sdConcaveFillet(vec2 p, vec2 boxMin, vec2 boxMax, vec2 holeCenter, float r) {
    if (r <= 0.0)
        return 1e6;
    float dBox  = sdBox(p, boxMin, boxMax);
    float dHole = -(length(p - holeCenter) - r);
    return max(dBox, dHole);
}

void main() {
    if ((dockDepth <= 0.0 || dockLength <= 0.0) && (panelDepth <= 0.0 || panelLength <= 0.0)) {
        fragColor = vec4(0.0);
        return;
    }
    if (fillColor.a <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    vec2  px       = qt_TexCoord0 * resolution;
    vec2  p        = vec2(abs(px.x - resolution.x * 0.5), px.y);
    bool  hasDock  = dockDepth > 0.0 && dockLength > 0.0;
    bool  hasPanel = panelDepth > 0.0 && panelLength > 0.0;
    float dockTop  = resolution.y - (hasDock ? dockDepth : 0.0);
    float d        = 1e6;

    if (hasDock) {
        float dockHalfW = dockLength * 0.5;
        float dockMaxR  = min(cornerRadius, min(dockHalfW, dockDepth * 0.5));
        float rDockTop  = dockMaxR;
        if (hasPanel && panelLength >= dockLength)
            rDockTop = 0.0;
        else if (hasPanel)
            rDockTop = min(dockMaxR, (dockLength - panelLength) * 0.5);

        float dDock = sdRoundedBoxHalf(p, dockHalfW, dockTop, resolution.y + borderOverlap, rDockTop, 0.0);
        d           = min(d, dDock);
    }

    if (hasPanel) {
        float panelHalfW   = panelLength * 0.5;
        float panelTop     = dockTop - panelDepth;
        float panelBottom  = hasDock ? (dockTop + min(dockDepth, 2.0)) : (resolution.y + borderOverlap);
        float panelMaxR    = min(cornerRadius, min(panelHalfW, panelDepth * 0.5));
        float rPanelBottom = 0.0;
        if (hasDock && panelLength > dockLength)
            rPanelBottom = min(panelMaxR, (panelLength - dockLength) * 0.5);

        float dPanel = sdRoundedBoxHalf(p, panelHalfW, panelTop, panelBottom, panelMaxR, rPanelBottom);
        d            = min(d, dPanel);
    }

    // Outer bottom fillets against ScreenBorder
    float baseHalfW = hasDock ? (dockLength * 0.5) : (panelLength * 0.5);
    float baseDepth = hasDock ? dockDepth : panelDepth;
    float rBase     = min(filletRadius, baseDepth * 0.5);
    float overlap   = min(baseHalfW, 4.0);
    float dBaseFil  = sdConcaveFillet(
        p,
        vec2(baseHalfW - overlap, resolution.y - rBase),
        vec2(baseHalfW + rBase, resolution.y + borderOverlap),
        vec2(baseHalfW + rBase, resolution.y - rBase),
        rBase
    );
    d = min(d, dBaseFil);

    // Step fillets where dock and panel meet
    if (hasDock && hasPanel) {
        float dockHalfW  = dockLength * 0.5;
        float panelHalfW = panelLength * 0.5;
        float diffHalf   = abs(dockHalfW - panelHalfW);
        float rStep      = min(stepFilletRadius, min(diffHalf, min(dockDepth, panelDepth) * 0.5));

        if (rStep > 0.0) {
            if (dockHalfW > panelHalfW) {
                float stepOverlap = min(panelHalfW, 4.0);
                float dStep = sdConcaveFillet(
                    p,
                    vec2(panelHalfW - stepOverlap, dockTop - rStep),
                    vec2(panelHalfW + rStep, dockTop + min(dockDepth, 4.0)),
                    vec2(panelHalfW + rStep, dockTop - rStep),
                    rStep
                );
                d = min(d, dStep);
            } else {
                float stepOverlap = min(dockHalfW, 4.0);
                float dStep = sdConcaveFillet(
                    p,
                    vec2(dockHalfW - stepOverlap, dockTop - min(panelDepth, 4.0)),
                    vec2(dockHalfW + rStep, dockTop + rStep),
                    vec2(dockHalfW + rStep, dockTop + rStep),
                    rStep
                );
                d = min(d, dStep);
            }
        }
    }

    float cov = smoothstep(0.75, -0.75, d);
    fragColor = fillColor * cov * qt_Opacity;
}
