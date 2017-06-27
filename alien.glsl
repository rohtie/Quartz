struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

Material defaultMaterial = Material(
    vec3(0.2, 0.2, 0.1),
    vec3(0.25, 0.5, 2.1),
    vec3(0.5, 0.25, 2.)
);

Material whiteMaterial = Material(
    vec3(1.0),
    vec3(1.0),
    vec3(1.0)
);

Material blackMaterial = Material(
    vec3(0.0),
    vec3(0.0),
    vec3(0.0)
);

float smin(float a, float b, float k) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
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

float ground(vec3 p) {
    // p.y += sin(p.x + iGlobalTime) * 0.25;
    // p.y += cos(p.z + iGlobalTime * 3.) * 0.15;
    // p.y += mod(p.x * 25., 1.) * 0.1;

    float result = p.y;

    return result;
}

float alien(vec3 p) {
    float result = 1.;
    result = min(result, length(p - vec3(0.0, 1.0, 0.0)) - 0.5);
    return result;
}

float map(vec3 p) {
    float result = 1.;
    result = min(result, ground(p));
    result = smin(result, alien(p), 0.5);

    return result;
}

bool isSameDistance(float distanceA, float distanceB, float eps) {
    return distanceA > distanceB - eps && distanceA < distanceB + eps;
}

bool isSameDistance(float distanceA, float distanceB) {
    return isSameDistance(distanceA, distanceB, 0.0001);
}

Material getMaterial(vec3 p) {
    float distance = map(p);

    // if (isSameDistance(distance, hat(p))) {
    //     return defaultMaterial;
    // }
    // else {
        return defaultMaterial;
    // }
}

vec3 getNormal(vec3 p) {
    vec2 extraPolate = vec2(0.002, 0.0);

    return normalize(vec3(
        map(p + extraPolate.xyy),
        map(p + extraPolate.yxy),
        map(p + extraPolate.yyx)
    ) - map(p));
}

float intersect (vec3 rayOrigin, vec3 rayDirection) {
    const float maxDistance = 10.0;
    const float distanceTreshold = 0.001;
    const int maxIterations = 50;

    float distance = 0.0;

    float currentDistance = 1.0;

    for (int i = 0; i < maxIterations; i++) {
        if (currentDistance < distanceTreshold || distance > maxDistance) {
            break;
        }

        vec3 p = rayOrigin + rayDirection * distance;

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

void mainImage (out vec4 o, in vec2 p) {
    p /= iResolution.xy;
    p = 2.0 * p - 1.0;
    p.x *= iResolution.x / iResolution.y;

    vec3 cameraPosition = vec3(0.0, 0.5, 3.0);
    vec3 rayDirection = normalize(vec3(p, -1.0));

    float b = 1.25 + sin(iGlobalTime) * 0.1;
    rayDirection.zy *= rotate(b);
    cameraPosition.zy *= rotate(b);

    float a = 3.14 + sin(iGlobalTime * 0.1);
    rayDirection.xz *= rotate(a);
    cameraPosition.xz *= rotate(a);

    float distance = intersect(cameraPosition, rayDirection);

    vec3 col = vec3(0.05, 0.05, 0.15);

    if (distance > 0.0) {
        col = vec3(0.0);

        vec3 p = cameraPosition + rayDirection * distance;
        vec3 normal = getNormal(p);

        Material material = getMaterial(p);

        if (mod(p.x * 25., 1.) > 0.5) {
            material = blackMaterial;
        }
        else {
            material = whiteMaterial;
        }

        col += material.ambient;
        col += material.diffuse * max(dot(normal, light), 0.0);

        vec3 halfVector = normalize(light + normal);
        col += material.specular * pow(max(dot(normal, halfVector), 0.0), 1024.0);

        float att = clamp(1.0 - length(light - p) / 5.0, 0.0, 1.0); att *= att;
        col *= att;

        col *= vec3(smoothstep(0.25, 0.75, map(p + light))) + 0.5;
    }

    o.rgb = col;
}
