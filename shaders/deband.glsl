// GLSL debanding shader, use as: source-shader=path/to/deband.glsl
// (Loosely based on flash3kyuu_deband, but expanded to multiple iterations)

//------------ Configuration section ------------
// The threshold of difference below which a pixel is considered to be part of
// a gradient. Higher = more debanding, but setting it too high diminishes image
// details.
#define THRESHOLD 64

// The range (in source pixels) at which to sample for neighbours. Higher values
// will find more gradients, but lower values will deband more aggressively.
#define RANGE 8

// The number of debanding iterations to perform. Each iteration samples from
// random positions, so increasing the number of iterations is likely to
// increase the debanding quality. Conversely, it slows the shader down.
// (Each iteration will use a multiple of the configured RANGE, and a
// successively lower THRESHOLD - so setting it much higher has little effect)
#define ITERATIONS 4

// (Optional) Add some extra noise to the image. This significantly helps cover
// up remaining banding and blocking artifacts, at comparatively little visual
// quality. Higher = more grain. Setting it to 0 disables the effect.
//#define GRAIN 48
#define GRAIN 32

// Note: If performance is too slow, try eg. RANGE=16 ITERATIONS=2. In general,
// an increase in the number of ITERATIONS should roughly correspond to a
// decrease in RANGE and perhaps an increase in THRESHOLD.
//------------ End of configuration ------------

// Wide usage friendly PRNG, shamelessly stolen from a GLSL tricks forum post
float mod289(float x)  { return x - floor(x / 289.0) * 289.0; }
float permute(float x) { return mod289((34.0*x + 1.0) * x); }
float rand(float x)    { return fract(x / 41.0); }

// Helper: Calculate a stochastic approximation of the avg color around a pixel
vec4 average(sampler2D tex, vec2 pos, float range, inout float h)
{
    // Compute a random rangle and distance
    float dist = rand(h) * range;     h = permute(h);
    float dir  = rand(h) * 6.2831853; h = permute(h);

    vec2 pt = dist / image_size;
    vec2 o = vec2(cos(dir), sin(dir));

    // Sample at quarter-turn intervals around the source pixel
    vec4 ref[4];
    ref[0] = texture(tex, pos + pt * vec2( o.x,  o.y));
    ref[1] = texture(tex, pos + pt * vec2(-o.y,  o.x));
    ref[2] = texture(tex, pos + pt * vec2(-o.x, -o.y));
    ref[3] = texture(tex, pos + pt * vec2( o.y, -o.x));

    // Return the (normalized) average
    return cmul*(ref[0] + ref[1] + ref[2] + ref[3])/4.0;
}

vec4 sample(sampler2D tex, vec2 pos, vec2 tex_size)
{
    float h;
    // Initialize the PRNG by hashing the position + a random uniform
    vec3 m = vec3(pos, random) + vec3(1.0);
    h = permute(permute(permute(m.x)+m.y)+m.z);

    // Sample the source pixel
    vec4 col = cmul*texture(tex, pos);

    for (int i = 1; i <= ITERATIONS; i++) {
        // Use the average instead if the difference is below the threshold
        vec4 avg = average(tex, pos, i*RANGE, h);
        vec4 diff = abs(col - avg);
        col = mix(avg, col, greaterThan(diff, vec4(THRESHOLD/(i*16384.0))));
    }

    // Add some random noise to the output
    vec3 noise;
    noise.x = rand(h); h = permute(h);
    noise.y = rand(h); h = permute(h);
    noise.z = rand(h); h = permute(h);
    col.rgb += (GRAIN/8192.0) * (noise - vec3(0.5));

    return col;
}

// vim: set ft=glsl:
