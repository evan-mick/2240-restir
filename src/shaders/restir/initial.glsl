#version 330

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 reservoirOut0;
layout(location = 2) out vec4 reservoirOut1;
layout(location = 3) out vec4 reservoirOut2;

in vec2 TexCoords;

#include /../common/uniforms.glsl
#include /../common/globals.glsl
#include /../common/intersection.glsl
#include /../common/sampling.glsl
#include /../common/envmap.glsl
#include /../common/anyhit.glsl
#include /../common/closest_hit.glsl
#include /../common/disney.glsl
#include /../common/lambert.glsl
#include /../common/restir.glsl
#include /../common/pathtrace.glsl

ReservoirSample GetNewSampleAtPixel(ivec2 pos) {
    // This code for getting a ray is just stolen from tile.glsl
    //    InitRNG(pos, frameNum);

    //vec2 coordsTile = (TexCoords / 2.0) + 1.0; //mix(tileOffset, tileOffset + invNumTiles, TexCoords);

    float r1 = 2.0 * rand();
    float r2 = 2.0 * rand();

    vec2 jitter;
    jitter.x = r1 < 1.0 ? sqrt(r1) - 1.0 : 1.0 - sqrt(2.0 - r1);
    jitter.y = r2 < 1.0 ? sqrt(r2) - 1.0 : 1.0 - sqrt(2.0 - r2);

    jitter /= (resolution * 0.5);
    vec2 d = (TexCoords * 2.0 - 1.0) + jitter;
    //vec2 d = TexCoords; //(coordsTile * 2.0 - 1.0) + jitter;

    float scale = tan(camera.fov * 0.5);
    d.y *= resolution.y / resolution.x * scale;
    d.x *= scale;
    vec3 rayDir = normalize(d.x * camera.right + d.y * camera.up + camera.forward);

    vec3 focalPoint = camera.focalDist * rayDir;
    float cam_r1 = rand() * TWO_PI;
    float cam_r2 = rand() * camera.aperture;
    vec3 randomAperturePos = (cos(cam_r1) * camera.right + sin(cam_r1) * camera.up) * sqrt(cam_r2);
    vec3 finalRayDir = normalize(focalPoint - randomAperturePos);

    Ray ray = Ray(camera.position + randomAperturePos, finalRayDir);

    //vec4 pixelColor = PathTraceFull(ray, true, ret);
    int index = int(rand() * float(numOfLights)) * 5;

    //// Fetch light Data
    vec3 position = texelFetch(lightsTex, ivec2(index + 0, 0), 0).xyz;
    vec3 emission = texelFetch(lightsTex, ivec2(index + 1, 0), 0).xyz;
    vec3 u = texelFetch(lightsTex, ivec2(index + 2, 0), 0).xyz; // u vector for rect
    vec3 v = texelFetch(lightsTex, ivec2(index + 3, 0), 0).xyz; // v vector for rect
    vec3 params = texelFetch(lightsTex, ivec2(index + 4, 0), 0).xyz;
    float radius = params.x;
    float area = params.y;
    float type = params.z; // 0->Rect, 1->Sphere, 2->Distant

    Light light = Light(position, emission, u, v, radius, area, type);
    State state;

    ReservoirSample ret;

    LightSampleRec lightSample;

    ScatterSampleRec scatterSample;

    bool hit = ClosestHit(ray, state, lightSample);
    vec3 scatterPos = state.fhp + state.normal * EPS;
    SampleOneLight(light, scatterPos, lightSample);

    GetMaterial(state, ray);
    // NO MIS RN, this is not accurate to their code, too bad!
    vec3 brdf = DisneySample(state, -ray.direction, state.ffnormal, lightSample.direction, scatterSample.pdf);

    //if (scatterSample.pdf > 0.0) {
    vec3 Ld = (brdf / lightSample.pdf) * lightSample.emission;

    //ret.radiance = Ld; //lightSample.pdf;
    //}
    //ret.direction = lightSample.direction;
    ret.index = index;
    ret.pdf = lightSample.pdf;

    #ifdef RESTIR_SAMPLE_INDEX_POSITION
    ret.fullDirection = lightSample.direction * lightSample.dist * 1.1;
    #endif

    float pHat = CalculatePHat(Ld);
    ret.weight = (pHat / lightSample.pdf) / 20; // lightSample.pdf;

    Ray shadowRay = Ray(scatterPos, lightSample.direction);
    bool inShadow = AnyHit(shadowRay, lightSample.dist - EPS);

    if (inShadow)
        ret.weight = 0;

    return ret;
}

void main(void)
{
    InitRNG(gl_FragCoord.xy, frameNum);
    // TODO: Generate sample function
    // Should shoot ray, generate light sample from place where hit, and return that
    // A simpler pathtrace function
    // Can use the same FBO as tile?
    //Reservoir prevRev = GetReservoirFromPosition(ivec2(gl_FragCoord.xy));
    Reservoir cur;
    cur.sumWeights = 0;
    cur.numberOfWeights = 0;

    ReservoirSample sam;
    for (int i = 0; i < 32; i++) {
        //cur.sam = sam;
        sam = GetNewSampleAtPixel(ivec2(gl_FragCoord.xy));
        cur = UpdateReservoir(cur, sam, sam.weight); //Luminance(sam.radiance) / sam.pdf); // need to divide radiance by p(x_i), but might be fine if uniformly distributed and thus the same, important for multisampling tho
    }
    cur.W = CalculateW(cur); // -nan right now

    // Temporal reuse
    Reservoir prevRev = GetReservoirFromPosition(ivec2(gl_FragCoord.xy));
    cur = CombineReservoirs(cur, prevRev);

    SaveReservoir(cur);
    reservoirOut0.z = cur.sam.weight; //texelFetch(reservoirs0, ivec2(gl_FragCoord.xy), 0);
    reservoirOut0.a = reservoirOut0.z / cur.sumWeights;
    //reservoirOut1 = vec4(1.0, 1.0, 1.0, 1.0);
    //reservoirOut2 = vec4(1.0, 1.0, 1.0, 1.0);
    //color = vec4(1.0);
}
