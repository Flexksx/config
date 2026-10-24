#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 sourcePixels;
    float level;
};

layout(binding = 1) uniform sampler2D source;

vec4 catmullRom(float t) {
    float t2 = t * t;
    float t3 = t2 * t;
    return vec4(-0.5 * t3 + t2 - 0.5 * t, 1.5 * t3 - 2.5 * t2 + 1.0, -1.5 * t3 + 2.0 * t2 + 0.5 * t, 0.5 * t3 - 0.5 * t2);
}

void main() {
    vec2 levelPixels = max(sourcePixels / exp2(level), vec2(1.0));
    vec2 position = qt_TexCoord0 * levelPixels - 0.5;
    vec2 base = floor(position);
    vec2 fraction = position - base;
    vec4 across = catmullRom(fraction.x);
    vec4 down = catmullRom(fraction.y);
    vec4 color = vec4(0.0);
    for (int row = 0; row < 4; ++row) {
        for (int column = 0; column < 4; ++column) {
            vec2 texel = (base + vec2(column - 1, row - 1) + 0.5) / levelPixels;
            color += textureLod(source, texel, level) * across[column] * down[row];
        }
    }
    color = clamp(color, 0.0, 1.0);
    fragColor = vec4(min(color.rgb, vec3(color.a)), color.a) * qt_Opacity;
}
