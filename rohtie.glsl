const float PI = acos(-1.);

float hash(float n) {
    return fract(sin(n)*43758.5453);
}

float noise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;

    return mix(mix(mix( hash(n+.0), hash(n+1.),f.x),
                   mix( hash(n+57.), hash(n+58.),f.x),f.y),
               mix(mix( hash(n+113.), hash(n+114.),f.x),
                   mix( hash(n+17.), hash(n+171.),f.x),f.y),f.z);
}

float circle(vec2 p, float radius) {
    return length(p) - radius;
}

float rightHalfCircle(vec2 p, float radius) {
    return max(-p.x, circle(p, radius));
}

float leftHalfCircle(vec2 p, float radius) {
    return max(p.x, circle(p, radius));
}

float upHalfCircle(vec2 p, float radius) {
    return max(-p.y, circle(p, radius));
}

float downHalfCircle(vec2 p, float radius) {
    return max(p.y, circle(p, radius));
}

float rect(vec2 p, vec2 dimensions) {
    dimensions *= .5;
    return max(abs(p.x) - dimensions.x, abs(p.y) - dimensions.y);
}

float r(vec2 p) {
    float result = 1.;

    result = min(result, circle(p - vec2(.27, .25), .124));
    result = min(result, rect(p, vec2(.25, .75)));

    return result;
}

float r2(vec2 p) {
    float result = 1.;

    // result = min(result, p.y - 0.115);
    result = min(result, rect(p - vec2(.0, .03), vec2(0.125, .525)));
    result = min(result, circle(p - vec2(0.175, .2), .075));


    return result;
}

float o(vec2 p) {
    float result = 1.;

    result = min(result, circle(p, .25));

    return result;
}

float q(vec2 p) {
    float result = 1.;

    result = min(result, circle(p, .25));
    result = min(result, leftHalfCircle(p - vec2(.25, -.3), .124));

    return result;
}

float h(vec2 p) {
    float result = 1.;

    result = min(result, rect(p - vec2(1.1, .025), vec2(.25, .8)));
    result = min(result, rightHalfCircle(p - vec2(1.3695 - .2525*.5, -.14), .249));
    result = min(result, rect(p - vec2(1.3675, -.34), vec2(.2475, .45)));

    return result;
}

float t(vec2 p) {
    float result = 1.;

    result = min(result, rect(p - vec2(0.27, .0), vec2(.25, .75)));
    result = min(result, upHalfCircle(p - vec2(0., .15), .124));

    return result;
}

float t2(vec2 p) {
    float result = 1.;

    result = min(result, rect(p - vec2(.0, .0), vec2(0.125, .75)));
    result = min(result, downHalfCircle(p - vec2(0.2, .375), .124));
    result = min(result, downHalfCircle(p - vec2(-0.2, .375), .124));

    return result;
}

float i(vec2 p) {
    float result = 1.;

    result = min(result, rect(p, vec2(.25, .5)));
    result = min(result, circle(p - vec2(.0, .25), .124));
    result = min(result, circle(p - vec2(.0, .55), .124));

    return result;
}

float e(vec2 p) {
    float result = 1.;

    result = min(result, upHalfCircle(p - vec2(.0, .0), .25));
    result = min(result, max(p.x - .025, downHalfCircle(p - vec2(.0, - .0175), .25)));

    return result;
}

float a(vec2 p) {
    float result = 1.;

    result = min(result, rightHalfCircle(p - vec2(.05, -.015), .25));
    result = min(result, leftHalfCircle(p - vec2(.0225, - .1385), .125));
    result = min(result, max(-p.y + .1, leftHalfCircle(p - vec2(.05, -.015), .25)));
    result = min(result, rect(p - vec2(0.2375, -0.135), vec2(0.125, 0.25)));
    // result = min(result, leftHalfCircle(p - vec2(.0225, - .1385), .125));
    // result = min(result, leftHalfCircle(p - vec2(.275, -.3), .124));

    return result;
}

float m(vec2 p) {
    float result = 1.;

    result = min(result, rect(p - vec2(.0, -.075), vec2(.25, .6)));
    result = min(result, rightHalfCircle(p - vec2(.145, -.12), .25));
    result = min(result, rect(p - vec2(.2725, -.25), vec2(.246, .25)));
    result = min(result, rightHalfCircle(p - vec2(.415, -.22), .25));
    result = min(result, rect(p - vec2(.542, -.35), vec2(.246, .25)));

    return result;
}

float y(vec2 p) {
    float result = 1.;

    result = min(result, leftHalfCircle(p - vec2(.115, .025), .25));
    result = min(result, rect(p - vec2(-.006, .15), vec2(.246, .25)));

    result = min(result, leftHalfCircle(p - vec2(.395, -.01), .25));
    result = min(result, rightHalfCircle(p - vec2(.145, -.242), .25));
    result = min(result, rect(p - vec2(.03, -.368), vec2(.246, .25)));

    return result;
}


float z(vec2 p) {
    float result = 1.;

    result = min(result, max(-p.x, downHalfCircle(p - vec2(.0, .18), .25)));
    result = min(result, max(p.x, upHalfCircle(p - vec2(.0, -.18), .25)));
    result = min(result, rect(p - vec2(-0., 0.19), vec2(0.5, 0.01)));
    result = min(result, rect(p - vec2(0., -0.19), vec2(0.5, 0.01)));

    return result;
}

float c(vec2 p) {
    float result = 1.;

    result = min(result, leftHalfCircle(p - vec2(.0, .0), .25));

    return result;
}

float l(vec2 p) {
    float result = 1.;

    result = min(result, rect(p - vec2(.0, .03), vec2(.25, .75)));

    return result;
}

float u(vec2 p) {
    float result = 1.;

    result = min(result, leftHalfCircle(p - vec2(.0, .0), .25));
    result = min(result, rightHalfCircle(p - vec2(.025, .0), .25));

    result = min(result, rect(p - vec2(-.13, .125), vec2(.246, .25)));
    result = min(result, rect(p - vec2(.155, .125), vec2(.246, .25)));

    return result;
}


float u2(vec2 p) {
    float result = 1.;

    // p /= 0.85;

    result = min(result, leftHalfCircle(p - vec2(-.0125, .0), .125));
    result = min(result, rightHalfCircle(p - vec2(.0125, .0), .125));

    result = min(result, rect(p - vec2(-.075, .125), vec2(.125, .2)));
    result = min(result, rect(p - vec2(.075, .125), vec2(.125, .2)));

    return result;
}

float b(vec2 p) {
    float result = 1.;

    result = min(result, rect(p - vec2(-.13, .125), vec2(.25, .75)));
    result = min(result, rightHalfCircle(p - vec2(.025, .0), .25));

    return result;
}

float rohtie(vec2 p) {
    p /= .415;

    float result = 1.;

    result = min(result, r(p - vec2(.125, .0)));
    result = min(result, o(p - vec2(.675, -.075)));
    result = min(result, h(p - vec2(.035, .0)));
    result = min(result, t(p - vec2(1.57, .0)));
    result = min(result, i(p - vec2(2.19, -.125)));
    result = min(result, e(p - vec2(2.65, -.075)));

    return result;
}

float quartz(vec2 p) {
    p /= .475;

    float result = 1.;

    // p.x *= -1.;
    // p.x += 1.65;

    p.y -= 0.05;
    p.x += 3.3;

    // result = min(result, p.y + 0.23);
    // result = min(result, -p.y + 0.04);
    // result = min(result, q(p - vec2(2.28, .0325)));
    result = min(result, q(p - vec2(2.29, .31)));
    result = min(result, u2(p - vec2(2.7, -.0925)));
    result = min(result, a(p - vec2(3.025, .045)));
    result = min(result, r2(p - vec2(3.415, .0175)));
    result = min(result, t2(p - vec2(3.815, -.345)));
    result = min(result, z(p - vec2(4.14125, -.4)));

    return result;
}

void mainImage( out vec4 o, in vec2 p ) {
    p /= iResolution.xy;

    vec2 r = p;

    p -= .5;
    p.x *= iResolution.x / iResolution.y;

    vec2 q = p;

    // o = vec4(smoothstep(0., 0.01, quartz(p - vec2(0., 0.))));
    // return;

    float result = 1.;

    if (iGlobalTime < 12.25) {
        p.x += sin(cos(p.y * 4.) * 5. + iGlobalTime) * .005;
        p.y += cos(sin(p.x * 4.) * 5. + iGlobalTime) * .0025;

        float focus = 0.;

        if (iGlobalTime <= 7.) {
            // result = rohtie(p - vec2(-.75 + .125, .0));
            result = rohtie(p - vec2(-.75 + .125, .0));
        }
        else {
            result = quartz(p);
            focus = 21.;
        }

        p.y += texture(iChannel0, vec2(mod(abs(r.x)  - 0.05, 0.1), 0.)).r * 0.05;
        result = min(result, abs(p.y));
        result = min(result, (1. - abs(q.y)) - sin(PI * 2.25 + iGlobalTime));

        result = smoothstep(
            0.,
            .01 + length(p - vec2(sin(PI * 1.75 + focus + iGlobalTime * .15), 0.)) * .5,
            result);

        o = (
            // ver1
            // vec4(0., abs(q.x) * .45, q.y * 1.55, 0.) +
            // result * vec4(1.) / noise(vec3(p.x, p.y, 0.)) * hash(p.y * p.x * 4000.)

            // ver2
            // vec4(0.) +
            // result

            // ver3
            // vec4(0.) +
            // result / hash(p.x * p.y * 5.0) * 5.5

            // ver4
            // vec4(0.) +
            // result / hash(p.x * .01)

            // ver5
            // vec4(0.) +
            // result * vec4(1.) / (length(p) * .05) * hash(p.x * 5.5)

            // ver6
            vec4(0.) + result / hash(p.x / p.y) * 0.75
            // - vec4(25.) * (1.0 - clamp(iGlobalTime * .75, 0., 1.))
        );
    }
    else if (iGlobalTime < 13.) {
        // Outlined text
        // result = max(-result, result - .005);
        result = quartz(p);

        // flipflop = smoothstep(0.3, 0.75, flipflop);


        float flipflop = mod(iGlobalTime * 50., 2.);
        result = smoothstep(.0, .01, result);

        if (flipflop <= 1.0) {
            result = 1.0 - result;
        }

        // float flipflop = sin(iGlobalTime * 50.);
        // result = smoothstep(.0 - flipflop * .01, .0, result);

        o = (
            result * vec4(1.)
        );
    }
}
