#version 330

out vec4 color;
out vec4 reservoirOut0;
out vec4 reservoirOut1;
out vec4 reservoirOut2;

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
#include /../common/pathtrace.glsl
#include /../common/restir.glsl

LightSampleRec GetNewSampleAtPixel(ivec2 pos) {
    LightSampleRec ret;
    ret.normal = normalize(vec3(1.0));
    ret.emission = normalize(vec3(1.0));
    ret.direction = normalize(vec3(1.0));
    ret.dist = 1.0f;
    ret.pdf = .05f;
    return ret;
}

void main(void)
{
    // TODO: Generate sample function
    // Should shoot ray, generate light sample from place where hit, and return that
    // A simpler pathtrace function
    // Can use the same FBO as tile?
    Reservoir prevRev = GetReservoirFromPosition(ivec2(gl_FragCoord.xy));
    for (int i = 0; i < 4; i++) {
        LightSampleRec sam = GetNewSampleAtPixel(ivec2(gl_FragCoord.xy));
        prevRev = UpdateReservoir(prevRev, sam);
    }
    SaveReservoir(prevRev);
    color = vec4(0.0);
}
