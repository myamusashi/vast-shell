#version 450

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) noperspective out vec2 texCoord;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
};

void main() {
    texCoord    = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * qt_Vertex;
}
