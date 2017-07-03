#define saturate(x) clamp(x, 0, 1)

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
    20.
);

Material blackMaterial = Material(
    vec3(0.0),
    vec3(0.0),
    vec3(0.3),
    20.
);

Material alienMaterial = Material(
    vec3(1.0),
    vec3(1.0),
    vec3(0.3),
    21.
);

Material alienEyesMaterial = Material(
    vec3(1.0),
    vec3(1.0),
    vec3(0.3),
    20.
);

float smin(float a, float b, float k) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

// The "Round" variant uses a quarter-circle to join the two objects smoothly:
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

// Distance to line segment between <a> and <b>, used for fCapsule() version 2below
float fLineSegment(vec3 p, vec3 a, vec3 b) {
    vec3 ab = b - a;
    float t = saturate(dot(p - a, ab) / dot(ab, ab));
    return length((ab*t + a) - p);
}

// Capsule version 2: between two end points <a> and <b> with radius r 
float capsule(vec3 p, vec3 a, vec3 b, float r) {
    return fLineSegment(p, a, b) - r;
}

vec3 repeat(vec3 p, vec3 c) {
    return mod(p,c)-0.5*c;
}

vec2 solve(vec2 p, float upperLimbLength, float lowerLimbLength) {
    vec2 q = p * (0.5 + 0.5 * (upperLimbLength * upperLimbLength - lowerLimbLength * lowerLimbLength) / dot(p, p));

    float s = upperLimbLength * upperLimbLength / dot(q, q) - 1.0;

    if (s < 0.0) { 
        return vec2(-100.0);
    }
        
    return q + q.yx * vec2(-1.0, 1.0) * sqrt(s);
}

float line(vec2 a, vec2 b, vec2 p) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    
    return length(pa - ba * h) - 0.04;
}

float limb(vec3 p, vec2 target, float upperLimbLength, float lowerLimbLength) {    
    vec2 joint = solve(target, upperLimbLength, lowerLimbLength);
    vec3 joint3 = vec3(joint, 0.);
    vec3 target3 = vec3(target, 0.);

    return min(
        capsule(p, vec3(0.0), joint3, 0.1),
        capsule(p, joint3, target3, 0.1)
    );
}

float limb(vec3 p, vec2 target) {   
    return limb(p, target, 0.5, 0.5);
}

float legs(vec3 p) {
    float speed = 4.0;
    
    p.y += sin(iGlobalTime * speed) * 0.05;
    
    float leftLeg = limb(p - vec3(0., 0., 0.25),
        vec2(-0.1 + sin(iGlobalTime * speed) * 0.4, 
             -0.7 + cos(iGlobalTime * speed) * 0.25)
    );

    float rightLeg = limb(p - vec3(0., 0., -0.25),
        vec2(-0.1 + sin(2.75 + iGlobalTime * speed) * 0.4, 
             -0.7 + cos(2.75 + iGlobalTime * speed) * 0.25)
    );
    
    return min(leftLeg, rightLeg);
}

float arms(vec3 p) {   
    p.y = 1.0 - p.y;
    p.y -= 0.25;
    p.x -= 0.3;
    
    float speed = 4.0;
    p.y += sin(iGlobalTime * speed) * 0.025;
    
    vec2 target = vec2(0.0, 0.5);
    vec2 ellipse = vec2(-0.5, 0.2);
    vec2 limbSize = vec2(0.5, 0.4);
    
    float leftArm = limb(p - vec3(-0.3, -0.85, -0.7),
        vec2(target.x - sin(iGlobalTime * speed) * ellipse.x, 
             target.y - cos(iGlobalTime * speed) * ellipse.y),
        limbSize.x, limbSize.y
    );
    
    float rightArm = limb(p - vec3(-0.3, -0.85, 0.7),
        vec2(target.x - sin(2.75 + iGlobalTime * speed) * ellipse.x, 
             target.y - cos(2.75 + iGlobalTime * speed) * ellipse.y),
        limbSize.x, limbSize.y
    );
    
    return smin(min(leftArm, rightArm), length(p) -0.15, 0.3);
}

float alieneyes(vec3 p) {
    float r = 1.;

    p -= vec3(0.0, 1.5, 0.0);

    float s = 0.35;
    p /= s;

    p.z = abs(p.z);

    r = min(r, length(p - vec3(0.7, 0.25, 0.4)) + 0.05);

    r *= s;

    return r;
}

float alien(vec3 p) {
    float r = 1.;

    p -= vec3(0.0, 1.5, 0.0);

    float s = 0.35;
    p /= s;

    // Head
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

    // Legs
    vec3 v = p;
    v.x -= -0.5;
    v.y -= -7.;
    r = rmin(r, legs(v / 3.) * 3., 0.75);

    // arms
    r = rmin(r, arms(v / 3.) * 3., 0.75);

    vec3 w = p;
    w = repeat(w, vec3(0.1));
    // r = length(w) - 0.0000001;

    r = rmin(r, max(r, length(w) - 0.025), 0.05);

    r *= s;
    // r =

    return r;
}

float ground(vec3 p) {
    p.y += sin(p.x + iGlobalTime) * 0.25;
    p.y += cos(p.z + iGlobalTime * 3.) * 0.15;
    
    // Cool spikey thingies
    // p.y += mod(p.x * p.z, 1.) * 3.;

    float r = p.y;

    return r;
}

float map(vec3 p) {
    float r = 1.;

    // r = min(r, ground(p));
    r = rmin(r, alien(p), 0.25);
    r = rmin(r, alieneyes(p), 0.15);

    return r;
}

bool isSameDistance(float distanceA, float distanceB, float eps) {
    return distanceA > distanceB - eps && distanceA < distanceB + eps;
}

bool isSameDistance(float distanceA, float distanceB) {
    return isSameDistance(distanceA, distanceB, 0.0001);
}

Material getMaterial(vec3 p) {
    float distance = map(p);

    if (isSameDistance(distance, alieneyes(p), 0.1)) {
        return alienEyesMaterial;
    }
    else {
        return alienMaterial;
    }
}

vec3 getNormal(vec3 p) {
    vec2 extraPolate = vec2(0.002, 0.0);

    return normalize(vec3(
        map(p + extraPolate.xyy),
        map(p + extraPolate.yxy),
        map(p + extraPolate.yyx)
    ) - map(p));
}

float intersect (vec3 camera, vec3 ray) {
    const float maxDistance = 10.0;
    const float distanceTreshold = 0.001;
    const int maxIterations = 50;

    float distance = 0.0;

    float currentDistance = 1.0;

    for (int i = 0; i < maxIterations; i++) {
        if (currentDistance < distanceTreshold || distance > maxDistance) {
            break;
        }

        vec3 p = camera + ray * distance;

        currentDistance = map(p);

        distance += currentDistance;
    }

    if (distance > maxDistance) {
        return -1.0;
    }

    return distance;
}

mat2 rotate(float a) {
    return mat2(-sin(a), cos(a),
               cos(a), sin(a));
}

vec3 light = normalize(vec3(10.0, 20.0, 2.0));

vec3 stripeTextureRaw(vec3 p){
    if (mod(p.x * 15., 1.) > 0.5) {
        return vec3(0.);
    }
    
    return vec3(1.);
}

const int textureSamples = 10;
vec3 stripeTexture(in vec3 p) {
    vec3 ddx_p = p + dFdx(p);
    vec3 ddy_p = p + dFdy(p); 

    int sx = 1 + int( clamp( 4.0*length(p), 0.0, float(textureSamples-1) ) );
    int sy = 1 + int( clamp( 4.0*length(p), 0.0, float(textureSamples-1) ) );

    vec3 no = vec3(0.0);

    for ( int j=0; j<textureSamples; j++ ) {
        for ( int i=0; i<textureSamples; i++ ) {
            if ( j<sy && i<sx ) {
                vec2 st = vec2( float(i), float(j) ) / vec2( float(sx),float(sy) );
                no += stripeTextureRaw( p + st.x*(ddx_p-p) + st.y*(ddy_p-p));
            }
        }
    }

    return no / float(sx*sy);
}

void mainImage (out vec4 o, in vec2 p) {
    p /= iResolution.xy;
    p = 2.0 * p - 1.0;
    p.x *= iResolution.x / iResolution.y;

    vec3 camera = vec3(0.0, 0.5, 3.0);
    vec3 ray = normalize(vec3(p, -1.0));

    float b = 1.25 + sin(iGlobalTime) * 0.1;
    ray.zy *= rotate(b);
    camera.zy *= rotate(b);

    float a = 3.14 + iGlobalTime;
    ray.xz *= rotate(a);
    camera.xz *= rotate(a);

    float distance = intersect(camera, ray);

    vec3 col = vec3(0.);

    if (distance > 0.0) {
        col = vec3(0.0);

        vec3 p = camera + ray * distance;

        vec3 normal = getNormal(p);

        Material material = getMaterial(p);

        vec3 stripe = stripeTexture(p);

        if (material == alienEyesMaterial) {
            stripe = 1. - stripe;
        }

        // if (mod(iGlobalTime * 10., 2.) >= 1.)
        // stripe = 1. - stripe;

        col += material.ambient * stripe;
        col += material.diffuse * stripe * max(dot(normal, light), 0.0);

        vec3 halfVector = normalize(light + normal);
        col += material.specular * pow(max(dot(normal, halfVector), 0.0), material.hardness);

        float att = clamp(1.0 - length(light - p) / 5.0, 0.0, 1.0); att *= att;
        col *= att;

        col *= vec3(smoothstep(0.25, 0.75, map(p + light))) + 0.5;
    }

    o.rgb = col;
}
