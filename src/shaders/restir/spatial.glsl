

/*
 * The purpose of this shader is to resample the neighbors
 *
*/

#version 330

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 reservoirOut0;
layout(location = 2) out vec4 reservoirOut1;
layout(location = 3) out vec4 reservoirOut2;
layout(location = 4) out vec4 reservoirOut3;

in vec2 TexCoords;

#include /../common/uniforms.glsl
#include /../common/globals.glsl
#include /../common/restir.glsl

const int num_iters = 4;
const int num_neighs = 4;

void main(void)
{
    ivec2 cur_pix = ivec2(gl_FragCoord.xy);
    Reservoir cur = GetReservoirFromPosition(ivec2(gl_FragCoord.xy));

    bool useSpatial = true; //(TexCoords.x < 0.5);

    if (useSpatial) {
        for (int i = 0; i < num_iters; i++) {
            for (int n = 0; n < num_neighs; n++) {
                ivec2 offset = get_offset();
                ivec2 neigh = cur_pix + offset;
                if (in_bounds(neigh)) {
                    Reservoir neighbor = GetReservoirFromPosition(neigh);
                    if (mergeable(cur, neighbor)) {
                        cur = CombineReservoirs(cur, neighbor);
                    }
                }
            }
        }
    }
    SaveReservoir(cur);
}
