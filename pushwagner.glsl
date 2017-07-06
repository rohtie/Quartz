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

Material redMaterial = Material(
    vec3(2., 0.25, 0.05),
    vec3(1., 1.5, 0.),
    vec3(1., 0.5, 0.),
    5.
);

Material stripeMaterial = Material(
    vec3(1.),
    vec3(0.15),
    vec3(0.15),
    -2.
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

vec3 pMod3(inout vec3 p, vec3 size) {
    vec3 c = floor((p + size*0.5)/size);
    p = mod(p + size*0.5, size) - size*0.5;
    return c;
}

mat2 rotate(float a) {
    return mat2(-sin(a), cos(a),
               cos(a), sin(a));
}

float circleRepeat(inout vec2 p, float repetitions) {
    float angle = 2*PI/repetitions;
    float a = atan(p.y, p.x) + angle/2.;
    float r = length(p);
    float c = floor(a/angle);
    a = mod(a,angle) - angle/2.;
    p = vec2(cos(a), sin(a))*r;
    // For an odd number of repetitions, fix cell index of the cell in -x direction
    // (cell index would be e.g. -5 and 5 in the two halves of the cell):
    if (abs(c) >= (repetitions/2)) c = abs(c);
    return c;
}

float box(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float vmax(vec3 v) {
    return max(max(v.x, v.y), v.z);
}

float standingPerson(vec3 p) {
    float r = 1.;

    p.y -= 0.05;
    p.xz *= rotate(PI);

    r = min(r, length(p - vec3(0., 0., 0.)) - 0.0125);
    r = rmin(r, length(p - vec3(-0.0025, -0.03, 0.)) - 0.005, 0.03);
    r = rmin(r, length(p - vec3(0.0025, 0.025, 0.)) - 0.0075, 0.01);

    p.z = abs(p.z);
    r = rmin(r, length(p - vec3(-0.0025, 0.03, 0.0075)) - 0.002, 0.0015);

    r = rmin(r, capsule(p, vec3(0., 0.0, 0.015), vec3(0., -0.03, 0.0175), 0.0015), 0.005);
    r = rmin(r, capsule(p, vec3(0., -0.03, 0.0075), vec3(0., -0.075, 0.0075), 0.002), 0.01);

    return r;
}

float audience(vec3 p) {
    float r = 1.;

    p.z = abs(p.z);
    p.z -= sin(p.x) * 0.9;
    p.z -= sin(p.y) * 0.25;

    p.y -= 0.035;

    vec3 w = repeat(p, vec3(0.05, 0.2, 0.05));
    r = min(r, standingPerson(w - vec3(0., 0.001, 0.001)));
    r = max(r, -(p.z - 1.5));

    return r;
}

float rooms(vec3 p) {
    float r = 1.;

    p.z = abs(p.z);
    p.z -= sin(p.x) * 0.9;
    p.z -= sin(p.y) * 0.25;

    r = -(p.z - 1.5);

    float boxies = 1.;
    vec3 q = repeat(p, vec3(0.2, 0.2, 0.2));
    boxies = min(boxies, box(q, vec3(0.1, 0.0025, 0.1)));
    boxies = rmin(boxies, box(q, vec3(0.0025, 0.1, 0.0025)), 0.01);
    boxies = rmin(boxies, box(q - vec3(0., 0.065, 0.), vec3(0.1, 0.0005, 0.0005)), 0.0035);
    r = max(r, boxies);

    return r * 0.875;
}

vec2 solve(vec2 p, float upperLimbLength, float lowerLimbLength) {
    vec2 q = p * (0.5 + 0.5 * (upperLimbLength * upperLimbLength - lowerLimbLength * lowerLimbLength) / dot(p, p));

    float s = upperLimbLength * upperLimbLength / dot(q, q) - 1.0;

    if (s < 0.0) {
        return vec2(-100.0);
    }

    return q + q.yx * vec2(-1.0, 1.0) * sqrt(s);
}

float limb(vec3 p, vec2 target, float upperLimbLength, float lowerLimbLength) {
    vec2 joint = solve(target, upperLimbLength, lowerLimbLength);
    vec3 joint3 = vec3(joint, 0.);
    vec3 target3 = vec3(target, 0.);

    return min(
        capsule(p, vec3(0.0), joint3, 0.0025),
        capsule(p, joint3, target3, 0.0025)
    );
}

float limb(vec3 p, vec2 target) {
    return limb(p, target, 0.5, 0.5);
}

float legs(vec3 p) {
    float time = iGlobalTime;

    float speed = 4.0;
    float limbDifference = 2.75;

    float size = 0.04;

    vec2 target = vec2(-0.1, -0.7) * size;
    vec2 ellipse = vec2(0.4, 0.25) * size;
    vec2 limbSize = vec2(0.5, 0.5) * size;

    // p.y += sin(time * speed) * 0.05;

    float leftLeg = limb(p - vec3(0., 0., 0.0075),
        vec2(target.x + sin(time * speed) * ellipse.x,
             target.y + cos(time * speed) * ellipse.y),
        limbSize.x, limbSize.y
    );

    float rightLeg = limb(p - vec3(0., 0., -0.0075),
        vec2(target.x + sin(limbDifference + time * speed) * ellipse.x,
             target.y + cos(limbDifference + time * speed) * ellipse.y),
        limbSize.x, limbSize.y
    );

    return min(leftLeg, rightLeg);
}

float arms(vec3 p) {
    float time = iGlobalTime;

    float speed = 4.0;
    float limbDifference = 2.75;

    float size = 0.04;

    p.y *= -1.;

    // p.y += sin(time * speed) * 0.025;

    vec2 target = vec2(0.0, 0.5) * size;
    vec2 ellipse = vec2(-0.5, 0.2) * size;
    vec2 limbSize = vec2(0.5, 0.4) * size;

    float leftArm = limb(p - vec3(-0.0, -0.0, -0.015),
        vec2(target.x - sin(time * speed) * ellipse.x,
             target.y - cos(time * speed) * ellipse.y),
        limbSize.x, limbSize.y
    );

    float rightArm = limb(p - vec3(-0.0, -0.0, 0.015),
        vec2(target.x - sin(limbDifference + time * speed) * ellipse.x,
             target.y - cos(limbDifference + time * speed) * ellipse.y),
        limbSize.x, limbSize.y
    );

    return min(leftArm, rightArm);
}

float walkingPerson(vec3 p) {
    float r = 1.;

    p.x -= 0.65;

    p.xz *= rotate(0.);

    // r = min(r, box(p, vec3(0.035)));
    // r = min(r, length(p - vec3(0., 0.025, 0.025)) - 0.025);
    r = min(r, length(p - vec3(0., 0., 0.)) - 0.0125);
    r = rmin(r, length(p - vec3(-0.0025, -0.03, 0.)) - 0.005, 0.03);
    r = rmin(r, length(p - vec3(0.0025, 0.025, 0.)) - 0.0075, 0.01);

    r = rmin(r, arms(p - vec3(0., 0., 0.)), 0.0035);
    r = rmin(r, legs(p - vec3(0., -0.03, 0.)), 0.0075);

    p.z = abs(p.z);
    r = rmin(r, length(p - vec3(-0.0025, 0.03, 0.0075)) - 0.002, 0.0015);

    return r;
}

float spiral(vec3 p) {
    float r = 1.;

    p.x -= 2.;
    p.y -= 1.;

    p *= clamp(abs(p.y * 0.15) + 0.6, 0.7, 2.);
    p.xz *= rotate(1.7 - iGlobalTime * 0.05);

    float spiralSpace = 4.;

    float c = circleRepeat(p.xz, 50.);

    p.y -= c * 0.006 * spiralSpace;

    float rep = 0.15 * spiralSpace;
    p.y = mod(p.y, rep);
    p.y -= rep * 0.5;

    r = min(r, walkingPerson(p));

    r *= 0.95;

    return r;
}

float map(vec3 p) {
    float r = 1.;


    r = min(r, rooms(p));
    r = min(r, audience(p));
    r = min(r, spiral(p));

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

    if (isSameDistance(distance, audience(p))) {
        return stripeMaterial;
    }
    else if (isSameDistance(distance, spiral(p))) {
        return redMaterial;
    }
    else {
        return whiteMaterial;
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
    const int maxIterations = 75;

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

vec3 stripeTextureRaw(vec3 p) {
    if (mod(p.y * 150 + 0.1, 1.) > 0.5) {
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

vec3 light = normalize(vec3(0.5, 3., 2.25));

void mainImage (out vec4 o, in vec2 p) {
    p /= iResolution.xy;
    p = 2.0 * p - 1.0;
    p.x *= iResolution.x / iResolution.y;

    vec3 camera = vec3(0.5, -0.25 + iGlobalTime * 0.05, 5.1 - iGlobalTime * 0.025);
    // camera = vec3(1.75, 0.4, 2.2);
    vec3 ray = normalize(vec3(p, -1.0));

    float b = 1.25 + sin(iGlobalTime * 0.25) * 0.5;
    b = 1.5;

    ray.zy *= rotate(b);
    camera.zy *= rotate(b);

    float a = 3.14 + sin(iGlobalTime * 0.1);
    a = 3.14;
    ray.xz *= rotate(a);
    camera.xz *= rotate(a);

    float distance = intersect(camera, ray);

    vec3 col = vec3(0.);

    if (distance > 0.0) {
        col = vec3(0.0);

        vec3 p = camera + ray * distance;

        vec3 normal = getNormal(p);

        Material material = getMaterial(p);

        vec3 stripe = vec3(1.);

        if (material == whiteMaterial) {
            stripe = stripeTexture(p);
        }

        col += material.ambient * stripe;
        col += material.diffuse * stripe * max(dot(normal, light), 0.0);

        vec3 halfVector = normalize(light + normal);
        col += material.specular * stripe *  pow(max(dot(normal, halfVector), 0.0), material.hardness);

        float att = clamp(1.0 - length(light - p) / 7.5, 0.0, 1.0); att *= att;
        col *= att;

        col *= vec3(smoothstep(0.25, 0.75, map(p + light))) + 0.5;
    }

    o.rgb = col;
}
