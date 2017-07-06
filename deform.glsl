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
    vec3(1.0),
    vec3(1.0),
    vec3(0.3),
    1.
);

Material blackMaterial = Material(
    vec3(0.0),
    vec3(0.0),
    vec3(0.3),
    20.
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

vec3 triPlanar(sampler2D tex, vec3 normal, vec3 p) {
    vec3 cX = texture(tex, p.yz).rgb;
    vec3 cY = texture(tex, p.xz).rgb;
    vec3 cZ = texture(tex, p.xy).rgb;

    vec3 blend = abs(normal);
    blend /= blend.x + blend.y + blend.z + 0.001;

    return blend.x * cX + blend.y * cY + blend.z * cZ;
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


float alieneyes(vec3 p) {
    float r = 1.;
    p.y -= 1.5;
    p.x -= 4.;
    p.z -= -2.2;

    // p.xz *= rotate(PI * 0.5);

    float s = 1.;
    p /= s;

    p.x += 3.;
    p.z = abs(p.z);

    p.x -= 2.;
    p.xz *= rotate(PI * 0.5 + mod(iGlobalTime * 0.025, 0.25) * PI);
    p.x += 2.;

    r = min(r, length(p - vec3(0.5, 0.25, 0.75)) + 0.095);
    // r = min(r, length(p - vec3(0.7, 0.25, 0.4)) - 0.05);
    // r = min(r, length(p) - 0.05);

    r *= s;

    return r;
}

float alien(vec3 p) {
    float r = 1.;

    p.y -= 1.5;
    p.xz *= rotate(PI * 0.5);

    float s = 1.;
    p /= s;

    r = min(r, length(p) - 1.);
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

float trippy(vec3 p) {
    float r = 1.;

    p.x -= 1.5;
    p.y -= 0.75;

    p.z += sin(p.y * 16. + iGlobalTime) * 0.25;
    p.y -= cos(p.z * 1. + iGlobalTime);

    p -= sin(p * 2.) * 0.55;
    p.x += sin(p.y) * 2.;

    r = mix(length(p) - 0.15, p.x, 1.25);

    r = r * 0.1;

    return r;
}

float Full(vec3 p) {
    float r = 1.;

    r = min(r, alien(p));

    return r;
}

float Half(vec3 p) {
    float r = 1.;

    float time = max(0.0, iGlobalTime - 0.15);

    p.x -= 4.;
    p.z -= -2.2;

    p.x += 4.;
    p.z = abs(p.z);

    p.x -= 2.;
    p.xz *= rotate(PI * 0.5 + min(time * 0.1, 0.35) * PI);
    p.x += 2.;

    r = min(r, max(-p.z, Full(p)));

    return r;
}

float HalfPortal(vec3 p) {
    float r = 1.;

    float time = max(0.0, iGlobalTime - 0.15);

    p.x -= 4.;
    p.z -= -2.2;

    p.x += 4.;
    p.z = abs(p.z);

    p.x -= 2.;
    p.xz *= rotate(PI * 0.5 + min(time * 0.1, 0.35) * PI);
    p.x += 2.;

    // r = min(r, max(-p.z, Full(p)));
    // r = min(r, max(p.z + 0.1 - iGlobalTime, max(-p.z, Full(p))));
    r = min(r, max(p.z + mix(0.9, 0.1, min(iGlobalTime * 0.5, 1.)), max(-p.z, Full(p))));

    // r = 1.;
    return r;
}

float map(vec3 p, int scene) {
    float r = 1.;

    switch(scene) {
        case 0:
            r = min(r, Half(p));
            r = rmin(r, alieneyes(p), 0.15);
            break;

        case 1:
            r = min(r, trippy(p));
            break;
    }

    return r;
}

bool isSameDistance(float distanceA, float distanceB, float eps) {
    return distanceA > distanceB - eps && distanceA < distanceB + eps;
}

bool isSameDistance(float distanceA, float distanceB) {
    return isSameDistance(distanceA, distanceB, 0.0001);
}

vec3 getNormal(vec3 p, int scene) {
    vec2 extraPolate = vec2(0.002, 0.0);

    return normalize(vec3(
        map(p + extraPolate.xyy, scene),
        map(p + extraPolate.yxy, scene),
        map(p + extraPolate.yyx, scene)
    ) - map(p, scene));
}

float intersect(vec3 camera, vec3 ray, int scene) {
    float maxDistance = 15.0;
    float distanceTreshold = 0.001;
    int maxIterations = 50;

    if (scene == 1) {
        maxDistance = 100.0;
        distanceTreshold = 0.0001;
        maxIterations = 500;
    }

    float distance = 0.0;

    float currentDistance = 1.0;

    for (int i = 0; i < maxIterations; i++) {
        if (currentDistance < distanceTreshold || distance > maxDistance) {
            break;
        }

        vec3 p = camera + ray * distance;

        currentDistance = map(p, scene);

        distance += currentDistance;
    }

    if (distance > maxDistance) {
        return -1.0;
    }

    return distance;
}

vec3 stripeTextureRaw(vec3 p, in int scene) {
    float math = p.x * 5.;

    if (scene == 1) {
        math = p.x * 1. - p.y * 25.;
    }


    if (mod(math, 1.) > 0.5) {
        return vec3(0.);
    }

    return vec3(1.);
}

const int textureSamples = 10;
vec3 stripeTexture(in vec3 p, in int scene) {
    vec3 ddx_p = p + dFdx(p);
    vec3 ddy_p = p + dFdy(p);

    int sx = 1 + int( clamp( 4.0*length(p), 0.0, float(textureSamples-1) ) );
    int sy = 1 + int( clamp( 4.0*length(p), 0.0, float(textureSamples-1) ) );

    vec3 no = vec3(0.0);

    for ( int j=0; j<textureSamples; j++ ) {
        for ( int i=0; i<textureSamples; i++ ) {
            if ( j<sy && i<sx ) {
                vec2 st = vec2( float(i), float(j) ) / vec2( float(sx),float(sy) );
                no += stripeTextureRaw( p + st.x*(ddx_p-p) + st.y*(ddy_p-p), scene);
            }
        }
    }

    return no / float(sx*sy);
}

void render(inout vec3 col, in float distance, in vec3 camera, in vec3 ray, int scene) {
    vec3 light = normalize(vec3(-0.25, 2., 1.25));

    if (distance > 0.0) {
        col = vec3(0.0);

        vec3 p = camera + ray * distance;

        vec3 normal = getNormal(p, scene);

        Material material = whiteMaterial;

        vec3 stripe = stripeTexture(p, scene);

        if (isSameDistance(map(p, scene), alieneyes(p), 0.4)) {
            stripe = 1. - stripe;
        }
        // stripe = vec3(1.);

        col += material.ambient * stripe;
        col += material.diffuse * stripe * max(dot(normal, light), 0.0);

        vec3 halfVector = normalize(light + normal);
        col += material.specular * stripe *  pow(max(dot(normal, halfVector), 0.0), material.hardness);

        float att = clamp(1.0 - length(light - p) / mix(15.0, 5., min(iGlobalTime * 0.25, 1.)), 0.0, 1.0); att *= att;
        col *= att;

        col *= vec3(smoothstep(0.25, 0.75, map(p + light, scene))) + 0.5;
    }
}


void mainImage (out vec4 o, in vec2 p) {
    p /= iResolution.xy;
    p = 2.0 * p - 1.0;
    p.x *= iResolution.x / iResolution.y;

    vec3 camera = mix(vec3(2.5, -2., 10.5), vec3(0.0, 0.5, 3.5), min(iGlobalTime * 0.25, 1.));
    vec3 ray = normalize(vec3(p, -1.0));

    float b = 1.25 + sin(iGlobalTime) * 0.1;
    // b = 1.5;

    ray.zy *= rotate(b);
    camera.zy *= rotate(b);

    float a = 3.14 + sin(iGlobalTime * 0.1);
    // a = mix(3.14 + 7., 3.14, min(iGlobalTime * 0.25, 1.));
    a = 3.14;
    ray.xz *= rotate(a);
    camera.xz *= rotate(a);

    int scene = 0;

    if (iGlobalTime > 5.) {
        scene = 1;
    }

    float distance = intersect(camera, ray, scene);

    vec3 col = vec3(1.);

    vec3 q = camera + ray * distance;
    if (isSameDistance(map(q, 1) * 0.5, HalfPortal(q), 0.35)) {
        scene = 1;
        distance = intersect(camera, ray, scene);
    }

    render(col, distance, camera, ray, scene);

    o.rgb = col;
}
