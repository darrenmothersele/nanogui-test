#version 330 core
layout (location = 0) in vec3 a_position;
out vec2 surfacePosition;
uniform vec2 screenRatio;

void main() {
   surfacePosition = a_position.xy * screenRatio;
   gl_Position = vec4(a_position, 1);
}
