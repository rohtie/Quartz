#define TIME_CURVE iGlobalTime + iGlobalTime * iGlobalTime * 0.25
// #define TIME_CURVE 3. - (iGlobalTime + iGlobalTime * iGlobalTime * 0.5)

const float PI = acos(-1.);

struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float hardness;
};

Material defaultMaterial = Material(
    vec3(0.2, 0.2, 0.1),
    vec3(0.25, 0.5, 2.1),
    vec3(0.5, 0.25, 2.),
    1024.
);

Material whiteMaterial = Material(
    vec3(5.),
    vec3(5.0),
    vec3(0.3),
    1024.
);

Material blackMaterial = Material(
    vec3(0.0),
    vec3(2.),
    vec3(32.),
    100.
);

float smin(float a, float b, float k) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float rmin(float a, float b, float r) {
    vec2 u = max(vec2(r - a,r - b), vec2(0));
    return max(r, min (a, b)) - length(u);
}

float rminbevel(float a, float b, float r) {
    return min(min(a, b), (a - r + b)*sqrt(0.5));
}

float rmax(float a, float b, float r) {
    vec2 u = max(vec2(r + a,r + b), vec2(0));
    return min(-r, max (a, b)) + length(u);
}

float rmaxbevel(float a, float b, float r) {
    return max(max(a, b), (a + r + b)*sqrt(0.5));
}

float capsule (vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

vec3 repeat(vec3 p, vec3 c) {
    return mod(p,c)-0.5*c;
}

mat2 rotate(float a) {
    return mat2(-sin(a), cos(a),
               cos(a), sin(a));
}

float alien(vec3 p) {
    p.y -= 1.5;
    p.xz *= rotate(PI * 0.5);

    float s = 1.;
    p /= s;

    float r = length(p) - 1.;
    r = rmin(r, length(p - vec3(0.75, -0.5, 0.0)) - 0.5, 0.5);

    vec3 q = p;
    q.z = abs(q.z);
    r = rmaxbevel(r, -(length(q - vec3(0.75, -0.7, 0.75)) - 0.5), 0.4);
    r = rmax(r, -(length(q - vec3(0., 0., 1.)) - 0.1), 1.);
    r = rmax(r, -(length(q - vec3(0.75, 0.15, 0.5)) - 0.05), 0.4);
    r = rmaxbevel(r, -(length(q - vec3(1.5, -0.4, 0.25)) - 0.25), 0.25);
    r = rmin(r, length(q - vec3(-0.5, 0.8, 0.9)) - 0.25, 0.25);


    // body
    r = rmin(r, length(q - vec3(-0.5, -1.5, 0.5)) - 0.5, 0.85);
    r = rmin(r, length(q - vec3(-0.5, -2.9, 0.2)) - 1.25, 1.);
    r = rmin(r, capsule(q, vec3(-0.5, -4., 0.4), vec3(-0., -5.9, 0.2), 0.75), 0.25);
    r = rmin(r, length(q - vec3(-0.5, -6.5, 0.5)) - 1., 0.85);
    r = rmin(r, length(q - vec3(-0.5, -1.7, 1.5)) - 0.5, 0.85);

    // arms
    vec3 v = p;
    v.z = abs(v.z);
    r = rmin(r, capsule(v, vec3(-0.5, -1.8, 2.), vec3(0.6, -4., 1.9), 0.3), 0.25);
    r = rmin(r, capsule(v, vec3(0.6, -4., 1.9), vec3(0.6, -4.75, 0.), 0.3), 0.25);

    // Legs
    v.y += 4.5;
    r = rmin(r, capsule(v, vec3(-0.5, -1.8, 1.25), vec3(0.25, -3.5, 1.9), 0.4), 0.25);
    r = rmin(r, capsule(v, vec3(0.25, -3.5, 1.9), vec3(0.6, -2.75, 0.4), 0.4), 0.25);


    vec3 w = p;
    w = repeat(w, vec3(0.1));

    r = rmin(r, max(r, length(w) - 0.025), 0.05);

    r *= s;

    return r;
}

float Full(vec3 p) {
    return alien(p);
}

void split(inout vec3 p, bool isOther) {
    float time = max(0.0, max(0.15, mod(TIME_CURVE, 1.)) - 0.15);

    p.z = abs(p.z);

    p.x -= 2.;
    p.xz *= rotate(PI * 0.5 + min(time * 0.75, 0.35) * PI);
    p.x += 2.;
}

float Half(vec3 p, bool isOther) {
    split(p, isOther);
    return max(-p.z, Full(p));
}

float HalfPortal(vec3 p, bool isOther) {
    split(p, isOther);
    return max(p.z + 0.45 - max(0.1, mod(TIME_CURVE, 1.)), max(-p.z, Full(p)));
}

float bg(vec3 p, bool isOther) {
    if (isOther) {
        p.x -= -5.;
    }

    return p.x;
}

float map(vec3 p, bool isOther) {
    float r = bg(p, isOther);

    if (!isOther) {
        return min(r, Half(p, isOther));
    }

    p.xz *= rotate(PI * 0.5);
    p.z += 1.95;
    p.x -= 3.75;
    p.y -= 0.75;

    return min(r, Full(p));
}

bool isSameDistance(float distanceA, float distanceB, float eps) {
    return distanceA > distanceB - eps && distanceA < distanceB + eps;
}

bool isSameDistance(float distanceA, float distanceB) {
    return isSameDistance(distanceA, distanceB, 0.0001);
}

vec3 getNormal(vec3 p, bool isOther) {
    vec2 extraPolate = vec2(0.002, 0.0);

    return normalize(vec3(
        map(p + extraPolate.xyy, isOther),
        map(p + extraPolate.yxy, isOther),
        map(p + extraPolate.yyx, isOther)
    ) - map(p, isOther));
}

float intersect(in vec3 camera, in vec3 ray, in bool isOther) {
    float maxDistance = 15.0;
    float distanceTreshold = 0.001;
    int maxIterations = 50;


    float distance = 0.0;
    float currentDistance = 1.0;

    for (int i = 0; i < maxIterations; i++) {
        if (currentDistance < distanceTreshold || distance > maxDistance) {
            break;
        }

        vec3 p = camera + ray * distance;

        currentDistance = map(p, isOther);

        distance += currentDistance;
    }

    if (distance > maxDistance) {
        return -1.0;
    }

    return distance;
}

void render(inout vec3 col, in float distance, in vec3 camera, in vec3 ray, bool isWhite, bool isOther) {
    vec3 light = normalize(vec3(500., -2000., -750.));

    if (distance > 0.0) {
        col = vec3(0.0);

        vec3 p = camera + ray * distance;

        vec3 normal = getNormal(p, isOther);

        Material material = blackMaterial;
        if (isOther) {
            if (!isWhite) {
                material = whiteMaterial;
            }
        }
        else {
            if (isWhite) {
                material = whiteMaterial;
            }
        }

        vec3 stripe = vec3(1.);

        col += material.ambient * stripe;
        col += material.diffuse * stripe * max(dot(normal, light), 0.0);

        vec3 halfVector = normalize(light + normal);
        col += material.specular * stripe *  pow(max(dot(normal, halfVector), 0.0), material.hardness);

        float att = clamp(1.0 - length(light - p) / 9., 0.0, 1.0); att *= att;
        col *= att;

        col *= vec3(smoothstep(0.25, 0.75, map(p + light, isOther))) + 0.5;

        if (isSameDistance(map(p, isOther), bg(p, isOther), 0.1)) {
            col = vec3(1.);
            if (isOther) {
                if (!isWhite) {
                    col = vec3(0.);
                }
            }
            else  {
                if (isWhite) {
                    col = vec3(0.);
                }
            }
        }
    }
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

float zen(vec2 p) {
    float r = 1.;

    p /= 0.075;

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

    p.x += sin(p.y * 10.) * 0.01;
    p.y += sin(p.x * 10.) * 0.01;
    float ring = capusle(p, vec2(0.0, -0.1), vec2(0.0, 0.1), 0.34);
    r = min(r, max(-ring, ring - 0.045));

    return r;
}

void mainImage (out vec4 o, in vec2 p) {
    p /= iResolution.xy;
    vec2 qe = p;

    p = 2.0 * p - 1.0;
    p.x *= iResolution.x / iResolution.y;

    bool isOther = false;
    bool isWhite = false;
    isWhite = mod(TIME_CURVE, 2.) > 1.;

    vec3 camera = mix(vec3(0., -2.5, 10.5), vec3(2., 0., 3.), mod(TIME_CURVE, 1.));
    vec3 ray = normalize(vec3(p, -1.0));

    float b = 1.35;
    float a = 3.14;

    ray.zy *= rotate(b);
    camera.zy *= rotate(b);
    ray.xz *= rotate(a);
    camera.xz *= rotate(a);

    float distance = intersect(camera, ray, false);


    vec3 q = camera + ray * distance;
    if (isSameDistance(map(q, false) * 0.5, HalfPortal(q, false), 0.35)) {
        distance = intersect(camera, ray, true);
        isOther = true;
    }

    vec3 col = vec3(0.);

    render(col, distance, camera, ray, isWhite, isOther);

    o.rgb = col;
    qe -= 0.5;
    qe.x *= iResolution.x / iResolution.y;
    float re = zen(qe - vec2(0.75, -0.375));
    re = smoothstep(0.0, 0.0125, re);
    o.rgb = o.rgb*re + (1. - re) * vec3(.85, 0.15, 0.);
}
