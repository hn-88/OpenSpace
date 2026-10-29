/*****************************************************************************************
 *                                                                                       *
 * OpenSpace                                                                             *
 *                                                                                       *
 * Copyright (c) 2014-2026                                                               *
 *                                                                                       *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this  *
 * software and associated documentation files (the "Software"), to deal in the Software *
 * without restriction, including without limitation the rights to use, copy, modify,    *
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    *
 * permit persons to whom the Software is furnished to do so, subject to the following   *
 * conditions:                                                                           *
 *                                                                                       *
 * The above copyright notice and this permission notice shall be included in all copies *
 * or substantial portions of the Software.                                              *
 *                                                                                       *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   *
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         *
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    *
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF  *
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE  *
 * OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                         *
 ****************************************************************************************/

#version __CONTEXT__

#include "df64.glsl"

layout(location = 0) in vec3 in_position;

out Data {
  vec4 positionViewSpace;
  float depthClipSpace;
} out_data;

uniform mat4 modelView_hi;
uniform mat4 modelView_lo;
uniform mat4 modelViewProjection_hi;
uniform mat4 modelViewProjection_lo;

void main() {
  vec4 positionClipSpace = df64_mat4_mul_vec4(
    modelViewProjection_hi,
    modelViewProjection_lo,
    in_position,
    1.0
  );
  positionClipSpace.z = 0.0;
  out_data.depthClipSpace = positionClipSpace.w;
  gl_Position = positionClipSpace;

  out_data.positionViewSpace = df64_mat4_mul_vec4(
    modelView_hi,
    modelView_lo,
    in_position,
    1.0
  );
}
