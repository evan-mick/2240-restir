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

out vec4 color;
in vec2 TexCoords;

#include /../common/uniforms.glsl

uniform sampler2D imgTex;
uniform int xcoord;
uniform vec2 resolution;

void main()
{
    color = texture(imgTex, TexCoords);
    // Get x coordinate in [0,1] range from TexCoords
    float x = TexCoords.x;

    // Draw 3-pixel wide white vertical bands at 1/3 and 2/3 of the screen
    // Assuming screen width is normalized to [0,1], we define a threshold in texture space
    float band_width = 3.0 / resolution.x; // 3 pixels wide, convert to normalized width

    if (abs(x - 1.0/3.0) < band_width * 0.5 || abs(x - 2.0/3.0) < band_width * 0.5) {
        color = vec4(1.0, 1.0, 1.0, 1.0); // white divider
    }
}
