// Artificial Dawn - Animated OLED burn-in protection shader
// 5 purple/blue spotlights blending smoothly, keeping every pixel changing
//
// Optimized for efficiency: const colors, no division in hot path, MAD-friendly

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Normalize to [-0.5, 0.5] range with aspect correction
    float invResY = 1.0 / iResolution.y;
    vec2 p = vec2((fragCoord.x - iResolution.x * 0.5) * invResY,
                  (fragCoord.y - iResolution.y * 0.5) * invResY);

    float t = iTime * 0.02;

    // Compile-time constants (compiler can optimize)
    const vec3 c1 = vec3(0.28, 0.06, 0.62);  // violet
    const vec3 c2 = vec3(0.04, 0.22, 0.65);  // rich blue
    const vec3 c3 = vec3(0.38, 0.12, 0.72);  // bright purple
    const vec3 c4 = vec3(0.06, 0.32, 0.58);  // cyan-blue
    const vec3 c5 = vec3(0.12, 0.04, 0.30);  // dark violet
    const float r = 2.5;  // falloff softness

    // Spotlight positions
    vec2 s1 = vec2(cos(t) * 0.85, sin(t) * 0.48);
    vec2 s2 = vec2(cos(t * 0.7 + 1.2) * 0.90, sin(t * 0.8 + 1.2) * 0.52);
    vec2 s3 = vec2(cos(t * 0.5 + 2.5) * 0.80, sin(t * 0.6 + 2.5) * 0.50);
    vec2 s4 = vec2(cos(t * 0.9 + 4.0) * 0.95, sin(t * 0.75 + 4.0) * 0.45);
    vec2 s5 = vec2(cos(t * 0.6 + 5.5) * 0.88, sin(t * 0.55 + 5.5) * 0.55);

    // Compute offsets
    vec2 d1 = p - s1, d2 = p - s2, d3 = p - s3, d4 = p - s4, d5 = p - s5;

    // Weights: 1/(1 + r*dist²) - dot() avoids sqrt
    float w1 = 1.0 / (1.0 + r * dot(d1, d1));
    float w2 = 1.0 / (1.0 + r * dot(d2, d2));
    float w3 = 1.0 / (1.0 + r * dot(d3, d3));
    float w4 = 1.0 / (1.0 + r * dot(d4, d4));
    float w5 = 1.0 / (1.0 + r * dot(d5, d5));

    // Normalize: multiply by reciprocal (faster than 5 divisions)
    float invSum = 1.0 / (w1 + w2 + w3 + w4 + w5);
    w1 *= invSum; w2 *= invSum; w3 *= invSum; w4 *= invSum; w5 *= invSum;

    // Blend colors (MAD-friendly: multiply-add chain)
    vec3 color = c1 * w1 + c2 * w2 + c3 * w3 + c4 * w4 + c5 * w5;

    // Brightness: 0.9 + 0.1*sin() = MAD form
    color *= 0.9 + 0.1 * sin(t * 0.5);

    fragColor = vec4(color, 1.0);
}
