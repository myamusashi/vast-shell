#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float edgeMode;              // 0=bottom, 1=top, 2=right, 3=left
    float drawerLength;
    float drawerDepth;
    float cornerRadius;
    float filletRadius;
    float attachedFilletRadius;
    float borderOverlap;
    float flushToStart;
    float flushToEnd;
    float startPadding;
    float freeSidePadding;
    vec2  resolution;
    vec4  fillColor;
};

float sdBox(vec2 p, vec2 bMin, vec2 bMax) {
    vec2 c = 0.5 * (bMin + bMax);
    vec2 h = 0.5 * (bMax - bMin);
    vec2 q = abs(p - c) - h;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

float sdFillet(vec2 p, float isFlush) {
    float overlap = min(drawerLength * 0.5, 4.0);
    if (isFlush > 0.5) {
        if (filletRadius <= 0.0)
            return sdBox(p, vec2(-borderOverlap, 0.0), vec2(overlap, drawerDepth + borderOverlap));
        float dBox  = sdBox(p, vec2(-borderOverlap, -filletRadius), vec2(max(filletRadius, overlap), drawerDepth + borderOverlap));
        float dHole = -(length(p - vec2(filletRadius, -filletRadius)) - filletRadius);
        return max(dBox, dHole);
    }

    if (attachedFilletRadius <= 0.0)
        return 1e6;

    float dBox  = sdBox(p, vec2(-attachedFilletRadius, drawerDepth - attachedFilletRadius), vec2(overlap, drawerDepth + borderOverlap));
    float dHole = -(length(p - vec2(-attachedFilletRadius, drawerDepth - attachedFilletRadius)) - attachedFilletRadius);
    return max(dBox, dHole);
}

void main() {
    if (drawerLength <= 0.0 || drawerDepth <= 0.0 || fillColor.a <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    vec2  px     = qt_TexCoord0 * resolution;
    int   mode   = int(edgeMode + 0.5);
    float along  = 0.0;
    float across = 0.0;

    if (mode == 0) {
        along  = px.x - startPadding;
        across = px.y - freeSidePadding;
    } else if (mode == 1) {
        along  = px.x - startPadding;
        across = (resolution.y - px.y) - freeSidePadding;
    } else if (mode == 2) {
        along  = px.y - startPadding;
        across = px.x - freeSidePadding;
    } else {
        along  = px.y - startPadding;
        across = (resolution.x - px.x) - freeSidePadding;
    }

    float rStart = (flushToStart > 0.5) ? 0.0 : cornerRadius;
    float rEnd   = (flushToEnd > 0.5)   ? 0.0 : cornerRadius;

    vec2  halfSize = vec2(drawerLength * 0.5, (drawerDepth + borderOverlap) * 0.5);
    vec2  q        = vec2(along, across) - halfSize;
    float r        = (q.y < 0.0) ? ((q.x < 0.0) ? rStart : rEnd) : 0.0;
    vec2  b        = abs(q) - halfSize + r;
    float dBody    = length(max(b, 0.0)) + min(max(b.x, b.y), 0.0) - r;

    float dStart = sdFillet(vec2(along, across), flushToStart);
    float dEnd   = sdFillet(vec2(drawerLength - along, across), flushToEnd);
    float d      = min(dBody, min(dStart, dEnd));

    float cov = smoothstep(0.75, -0.75, d);

    fragColor = fillColor * cov * qt_Opacity;
}
