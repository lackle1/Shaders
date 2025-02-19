/*
    This was made as a video to go along with music that I had made, where I had no-drums and only-drums split
    into iChannel0 and iChannel1 respectively.
    Now it only uses iChannel0, but can still be used the original way.
    
    To properly use, uncomment the part in 'getFft'.
    Make sure the two sound files are the same length, or at least start at the same time. I don't know if finish time matters.
*/

// Position, bounds, line thickness.
float sdBoxFrame( vec3 p, vec3 b, float e ) {
    p = abs(p)-b;
    vec3 q = abs(p+e)-e;
    return min(min(
        length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
        length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
        length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

mat2 rot2D(float angle) {
    float s = sin(angle);
    float c = cos (angle);
    return mat2(c, -s, s, c);
}

vec3 palette( float t ) {
    vec3 a = vec3(0.338, -0.282, 0.498);
    vec3 b = vec3(0.468, 0.989, 0.053);
    vec3 c = vec3(0.448, 0.838, 1.052);
    vec3 d = vec3(2.088, 0.358, 3.234);

    return a + b * cos( 6.28318 * (c*t+d) ); // Weird number is 2*pi
}

float getFft(int tx, sampler2D channel) {
    // return max(
    //     texelFetch(iChannel0, ivec2(tx, 0), 0).r * .8, 
    //     texelFetch(iChannel1, ivec2(tx, 0), 0).r * 1.5);
    
    return texelFetch(iChannel0, ivec2(tx, 0), 0).x;
    
    float maxFft = 0.;
    for (int i = 0; i < 512; i++) {
        float fft = texelFetch(iChannel0, ivec2(i, 0), 0).x;
        maxFft = max(maxFft, fft);
    }
    
    return maxFft;
}

float map(vec3 p) {
    vec3 boxPos = vec3(0, -0.4, 1.);
    p -= boxPos;
    p.xz *= rot2D(iTime * .6);

    return sdBoxFrame(p, vec3(1), 0.1);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord * 2. - iResolution.xy) / iResolution.y;    // Simplified version
    
    // Initialisation
    vec3 ro = vec3(0, 4.2, -10);                                    // ray origin
    vec3 rd = normalize(vec3(uv * .4, 1));                         // ray direction
    rd.yz *= rot2D(0.4);
    float distTravelled = 0.;

    // Move camera forward with drums
    float camFft = getFft(4, iChannel1);
    vec3 dir = vec3(0, 0, 1);
    dir.yz *= rot2D(0.4);
    ro += dir * camFft * .8;

    vec3 col = vec3(0);

    // Ray-marching
    float normal = 0.;
    float closestDist = 1000.;
    int i;
    for (i = 0; i < 80; i++) {
        vec3 p = ro + rd * distTravelled;                           // position along the ray

        float d = map(p);                                           // current distance to the scene
        distTravelled += d;                                         // "march" the ray

        if (d < 0.01) normal += 0.05;
        if (d < closestDist) closestDist = d;

        if (d < .001 || distTravelled > 100.) break;
    }


    // Colouring of shape
    float distFft = getFft(int(closestDist * 40.), iChannel0);
    float distFactor = -100. + distTravelled * 0.8;
    col = palette(normal * 5. * (.5 + distFft));

    // Brightness of whole screen
    float brightness = 20. / (pow(distTravelled, 1.05));
    col *= brightness * (1.4 + distFft * .6);

    // Cube Glow
    if (closestDist >= 0.001) {
        float midFft = getFft(35, iChannel1);
        float glow = pow(.04 / closestDist, .3);
        col += glow * .6;
        col += glow * midFft * 2.8;
    }

    // Vignette, that also messes with colours
    float centerDist = length(uv);
    float factor = 1. - smoothstep(centerDist * 2., 0., 1.);
    col *= factor;
    col.r *= .4 + factor * getFft(200, iChannel0) * .8;
    col.g *= factor * .6;


    // Contrast
    col = ((col - 0.5) * 1.2) + 0.5;

    // Output to screen
    fragColor = vec4(col, 1.0);
}