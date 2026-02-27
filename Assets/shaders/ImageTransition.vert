#version 440

layout(location = 0) in  vec4 qt_Vertex;
layout(location = 1) in  vec2 qt_MultiTexCoord0;

layout(location = 0) out vec2 texCoord;

layout(std140, binding = 0) uniform FragBuf {
    mat4  qt_Matrix;       
    float qt_Opacity;      
    float progress;        
    int   transitionType;  
    float smoothAmount;    
    float aspect;          
    vec2  resolution;      
} ubuf;

void main() {
    texCoord    = qt_MultiTexCoord0;
    gl_Position = ubuf.qt_Matrix * qt_Vertex;
}
