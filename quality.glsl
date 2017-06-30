const float PI = acos(-1.);

float hash(float n) {
    return fract(sin(n)*43758.5453);
}

float smin(float a, float b, float k) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float capusle(vec2 p, vec2 a, vec2 b, float r, float pointiness) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp( dot(pa, ba) / dot(ba, ba), 0.0, 1.0 );
    return length( pa - ba*h ) - (r + pa.x * pointiness);
}

float capusle(vec2 p, vec2 a, vec2 b, float r) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp( dot(pa, ba) / dot(ba, ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float kai(vec2 p) {
    float r = 1.;

    r = smin(r, capusle(p, vec2(-0.04, 0.21), vec2(0.15, 0.275), 0.0, 0.05), 0.05);
    r = smin(r, capusle(p, vec2(0.19, 0.25), vec2(0.14, 0.075), 0.02), 0.05);
    r = smin(r, capusle(p, vec2(0.14, 0.075), vec2(0., 0.03), 0.02), 0.05);
    r = smin(r, capusle(p, vec2(0., 0.01), vec2(0., -0.275), 0.02), 0.05);
    r = smin(r, capusle(p, vec2(0.02, -0.275), vec2(0.2, -0.13), 0.025, -0.125), 0.05);

    r = smin(r, capusle(p, vec2(0.375, 0.35), vec2(0.25, 0.075), 0.02, 0.15), 0.05);
    r = smin(r, capusle(p, vec2(0.3, 0.12), vec2(0.55, 0.175), 0.0, 0.075), 0.05);
    r = smin(r, capusle(p, vec2(0.415, 0.12), vec2(0.38, -0.15), 0.02, 0.2), 0.05);
    r = smin(r, capusle(p, vec2(0.39, -0.15), vec2(0.175, -0.3), 0.025, 0.125), 0.05);
    r = smin(r, capusle(p, vec2(0.265, -0.025), vec2(0.375, -0.15), 0.02, -0.15), 0.05);
    r = smin(r, capusle(p, vec2(0.365, -0.15), vec2(0.525, -0.315), 0.0, 0.25), 0.05);

    return r;
}

float zen(vec2 p) {
    float r = 1.;

    r = smin(r, capusle(p, vec2(-0.125, 0.38), vec2(-0.09, 0.33), 0.03, -0.3), 0.05);
    r = smin(r, capusle(p, vec2(0.11, 0.42), vec2(0.04, 0.33), 0.03, 0.3), 0.05);
    
    r = smin(r, capusle(p, vec2(-0.17, 0.26), vec2(0.15, 0.285), 0.01, 0.05), 0.05);
    r = smin(r, capusle(p, vec2(-0.18, 0.14), vec2(0.125, 0.17), 0.01, 0.05), 0.05);
    r = smin(r, capusle(p, vec2(-0.24, 0.015), vec2(0.2, 0.05), 0.01, 0.05), 0.05);
    r = smin(r, capusle(p, vec2(-0.35, -0.15), vec2(0.35, -0.11), 0.01, 0.05), 0.05);
    r = smin(r, capusle(p, vec2(-0.15, -0.01), vec2(-0.1, -0.115), 0.02, 0.05), 0.05);
    r = smin(r, capusle(p, vec2(0.105, -0.01), vec2(0.1, -0.115), 0.02, 0.05), 0.05);
    r = smin(r, capusle(p, vec2(-0.02, 0.26), vec2(-0.02, -0.115), 0.02, 0.05), 0.05);

    r = smin(r, capusle(p, vec2(-0.175, -0.225), vec2(0.15, -0.23), 0.01, 0.05), 0.05);    
    r = smin(r, capusle(p, vec2(-0.14, -0.4), vec2(0.15, -0.38), 0.01, 0.05), 0.05);
    
    r = smin(r, capusle(p, vec2(-0.175, -0.225), vec2(-0.14, -0.4), 0.02, 0.05), 0.05);
    r = smin(r, capusle(p, vec2(0.15, -0.23), vec2(0.1, -0.38), 0.02, 0.05), 0.05);

    return r;
}

float kaizen(vec2 p) {
    float r = 1.;

    p /= 0.075;

    // IDEA: Different symbol for each scene
    // r = min(r, kai(p - vec2(-0.25, 0.035)));

    // Zen looks best though...
    r = min(r, zen(p - vec2(0.0, 0.0)));
    
    float ring = capusle(p, vec2(0.0, -0.1), vec2(0.0, 0.1), 0.34); 
    r = min(r, max(-ring, ring - 0.045));

    return r;
}

void mainImage(out vec4 o, in vec2 p) {
    p /= iResolution.xy;
    vec2 q = p;

    p -= 0.5;
    p.x *= iResolution.x / iResolution.y; 

    float r = kaizen(p - vec2(0.75, -0.375));
    r = smoothstep(0.0, 0.0125, r);

    // Very slight abberation with yellow/blue instead of normal red/blue
    // that everyone overuses
    vec2 rb = texture(iChannel0, q).rb;
    float g = texture(iChannel0, q + dot(p.x, p.y) * 0.005).g;    
    o.rgb = vec3(rb, g);
    
    // Quality seal
    o.rgb = o.rgb*r + (1. - r) * vec3(.85, 0.15, 0.);
}
