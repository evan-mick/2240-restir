

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

void main(void)
{
    Reservoir cur = GetReservoirFromPosition(ivec2(gl_FragCoord.xy));

    //if (TexCoords.x > 0.5) {
    //    cur = CombineReservoirs(cur, GetReservoirFromPosition(ivec2(gl_FragCoord.xy) + ivec2(-1, -1)));
    //    cur = CombineReservoirs(cur, GetReservoirFromPosition(ivec2(gl_FragCoord.xy) + ivec2(-1, 0)));
    //    cur = CombineReservoirs(cur, GetReservoirFromPosition(ivec2(gl_FragCoord.xy) + ivec2(-1, 1)));
    //    cur = CombineReservoirs(cur, GetReservoirFromPosition(ivec2(gl_FragCoord.xy) + ivec2(0, -1)));
    //    cur = CombineReservoirs(cur, GetReservoirFromPosition(ivec2(gl_FragCoord.xy) + ivec2(0, 0)));
    //    cur = CombineReservoirs(cur, GetReservoirFromPosition(ivec2(gl_FragCoord.xy) + ivec2(0, 1)));
    //    cur = CombineReservoirs(cur, GetReservoirFromPosition(ivec2(gl_FragCoord.xy) + ivec2(1, -1)));
    //    cur = CombineReservoirs(cur, GetReservoirFromPosition(ivec2(gl_FragCoord.xy) + ivec2(1, 0)));
    //    cur = CombineReservoirs(cur, GetReservoirFromPosition(ivec2(gl_FragCoord.xy) + ivec2(1, 1)));
    //}

    SaveReservoir(cur);
}
