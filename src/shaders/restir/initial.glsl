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

LightSampleRec GetNewSampleAtPixel(ivec2 pos) {
    // This code for getting a ray is just stolen from tile.glsl
    //    InitRNG(pos, frameNum);

    //vec2 coordsTile = (TexCoords / 2.0) + 1.0; //mix(tileOffset, tileOffset + invNumTiles, TexCoords);

    InitRNG(gl_FragCoord.xy, frameNum);

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

    LightSampleRec ret;
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

    bool hit = ClosestHit(ray, state, ret);
    vec3 scatterPos = state.fhp + state.normal * EPS;
    SampleOneLight(light, scatterPos, ret);

    return ret;
}

void main(void)
{
    // TODO: Generate sample function
    // Should shoot ray, generate light sample from place where hit, and return that
    // A simpler pathtrace function
    // Can use the same FBO as tile?
    Reservoir cur;
    for (int i = 0; i < 4; i++) {
        LightSampleRec sam = GetNewSampleAtPixel(ivec2(gl_FragCoord.xy));
        cur = UpdateReservoir(cur, sam);
    }

    // Temporal reuse
    Reservoir prevRev = GetReservoirFromPosition(ivec2(gl_FragCoord.xy));
    cur = CombineReservoirs(cur, prevRev);

    SaveReservoir(cur);
    //reservoirOut0 = vec4(ivec2(gl_FragCoord.xy), TexCoords.xy); //texelFetch(reservoirs0, ivec2(gl_FragCoord.xy), 0);
    //reservoirOut0 = vec4(gl_FragCoord.x, gl_FragCoord.y, 1.0, 1.0);
    //reservoirOut1 = vec4(1.0, 1.0, 1.0, 1.0);
    //reservoirOut2 = vec4(1.0, 1.0, 1.0, 1.0);
    //color = vec4(1.0);
}
