vec3 palette( float t )
{
    vec3 a = vec3(0.338, -0.282, 0.498);
    vec3 b = vec3(0.468, 0.989, 0.053);
    vec3 c = vec3(0.448, 0.838, 1.052);
    vec3 d = vec3(2.088, 0.358, 3.234);

    return a + b * cos( 6.28318 * (c*t+d) ); // Weird number is 2*pi
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from -1 to 1), 
    vec2 uv = fragCoord/iResolution.xy * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y; // Multiply by the ratio so we don't get stretching
    
    vec2 uv0 = uv;
    vec3 finalColour = vec3(0.);

    // Calculate colour
    for (float i = 0.; i < 4.; i++)
    {
        uv = fract(uv * 1.35) - 0.5;
        
        vec3 col = palette(length(uv0)*0.5 + i*0.8 - iTime*0.2);

        float d = length(uv) * exp(-length(uv0)*1.4);
        d = sin(d*16. + iTime*1.2);
        d = abs(d);

        d = pow(0.04 / d, 0.85);
        col *= d;

        finalColour += col;
    }
    
    // Output to screen
    fragColor = vec4(finalColour,1.0);
}