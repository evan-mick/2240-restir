/*
 * MIT License
 *
 * Copyright(c) 2019 Asif Ali
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#version 330

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 reservoirOut0;
layout(location = 2) out vec4 reservoirOut1;
layout(location = 3) out vec4 reservoirOut2;
layout(location = 4) out vec4 reservoirOut3;

in vec2 TexCoords;

#include common/uniforms.glsl
#include common/globals.glsl
#include common/intersection.glsl
#include common/sampling.glsl
#include common/envmap.glsl
#include common/anyhit.glsl
#include common/closest_hit.glsl
#include common/disney.glsl
#include common/lambert.glsl
#include common/restir.glsl
#include common/pathtrace.glsl

void main(void)
{
    vec2 coordsTile = TexCoords; //gl_FragCoord.xy; //mix(tileOffset, tileOffset + invNumTiles, TexCoords);

    InitRNG(gl_FragCoord.xy, frameNum);

    float r1 = 2.0 * rand();
    float r2 = 2.0 * rand();

    vec2 jitter;
    jitter.x = r1 < 1.0 ? sqrt(r1) - 1.0 : 1.0 - sqrt(2.0 - r1);
    jitter.y = r2 < 1.0 ? sqrt(r2) - 1.0 : 1.0 - sqrt(2.0 - r2);

    jitter /= (resolution * 0.5);
    vec2 d = (coordsTile * 2.0 - 1.0) + jitter;

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

    vec4 accumColor = texture(accumTexture, coordsTile);

    LightSampleRec rec;

    bool useRestir = (TexCoords.x < 0.5);
    vec4 pixelColor = vec4(0, 0, 0, 1.0);
    for (int i = 0; i < 1; i++) {
        pixelColor += PathTraceFull(ray, true, rec);
    }

    // Multiply by W for reservoir
    Reservoir reser = GetReservoirFromPosition(ivec2(gl_FragCoord.xy));
    //float W = useRestir ? CalculateW(reser) : 1.0; // TODO: Figure this stuff out
    //pixelColor.xyz /= 2;
    //pixelColor /= 4;
    //pixelColor.xyz *= reser.W;

    // if (useRestir){
    //    pixelColor.xyz *= reser.W;
    // }

    //vec4 pixelColor = PathTrace(ray);

    color = pixelColor; // + accumColor;
    //reservoirOut0 = vec4(W);

    reservoirOut0 = texelFetch(reservoirs0, ivec2(gl_FragCoord.xy), 0);
    reservoirOut1 = texelFetch(reservoirs1, ivec2(gl_FragCoord.xy), 0);
    reservoirOut2 = texelFetch(reservoirs2, ivec2(gl_FragCoord.xy), 0);
    reservoirOut3 = texelFetch(reservoirs3, ivec2(gl_FragCoord.xy), 0);
    //Reservoir prevRev = GetReservoirFromPosition(ivec2(gl_FragCoord.xy));
    //vec3 col2 = prevRev.picked.emission.rgb;
    //color = vec4(col2.r, col2.g, col2.b, 1.0); //texelFetch(reservoirs0, ivec2(split convex shape with planesplit convex shape with planesplit convex shape with planegl_FragCoord.xy), 0);
    //color.a = 1.0;
}
