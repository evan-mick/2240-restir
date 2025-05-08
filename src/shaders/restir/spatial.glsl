

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

const int radius = 16;
const int num_iters = 32;
const int num_neighs = 4;
const float valid_dist_thresh = 0.1; //10%

ivec2 get_offset() {
    float a = rand();
    float b = rand();
    float x_disp = sqrt(b) * cos(TWO_PI * a);
    float y_disp = sqrt(b) * sin(TWO_PI * a);
    x_disp *= radius;
    y_disp *= radius;
    return ivec2(int(x_disp), int(y_disp));
}

bool in_bounds(ivec2 neigh) {
    return (neigh.x >= 0 && neigh.x < resolution.x && neigh.y >= 0 && neigh.y < resolution.y);
}

bool mergeable(Reservoir cur, Reservoir neighbor) {
    float dot = dot(cur.sam.hitPosition, neighbor.sam.hitPosition);
    bool sim_norms = dot > 0.9;
    float dist_range = cur.sam.camDist * valid_dist_thresh;
    float high = cur.sam.camDist + dist_range;
    float low = cur.sam.camDist - dist_range;
    bool sim_dists = neighbor.sam.camDist < high && neighbor.sam.camDist > low;

    return sim_dists; //sim_norms && sim_dists;
}

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
