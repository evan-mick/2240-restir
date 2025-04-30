

/*
 * The purpose of this shader is to resample the neighbors
 *
*/

#version 330

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 reservoirOut0;
layout(location = 2) out vec4 reservoirOut1;
layout(location = 3) out vec4 reservoirOut2;

in vec2 TexCoords;

#include /../common/uniforms.glsl
#include /../common/globals.glsl
#include /../common/restir.glsl

const int sampleRange = 16;

void main(void)
{
    Reservoir cur = GetReservoirFromPosition(ivec2(gl_FragCoord.xy));

    if (TexCoords.x > 0.5) {
        for (int x = -sampleRange; x < sampleRange; x++) {
            for (int y = -sampleRange; y < sampleRange; x++) {
                cur = CombineReservoirs(cur, GetReservoirFromPosition(ivec2(gl_FragCoord.xy) + ivec2(x, y)));
            }
        }
    }

    SaveReservoir(cur);
}
