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

#include "powerscaling/powerscaling_vs.glsl"
#include "${MODULE_GLOBEBROWSING}/shaders/df64.glsl"

layout(location = 0) in vec2 in_position;
layout(location = 1) in vec2 in_texCoords;
layout(location = 2) in vec3 in_normal;

out Data {
  vec3 posObj;
  vec2 texCoords;
  vec3 normal;
  float screenSpaceDepth;
  vec4 shadowCoords;
} out_data;

uniform mat4 modelViewProjectionMatrix_hi;
uniform mat4 modelViewProjectionMatrix_lo;
uniform mat4 shadowMatrix_hi;
uniform mat4 shadowMatrix_lo;

void main() {
  out_data.texCoords = in_texCoords;
  out_data.normal = mat3(modelViewProjectionMatrix_hi) * in_normal;
  out_data.posObj = vec3(in_position, 0.0);

  vec4 positionClipSpace = df64_mat4_mul_vec4(
    modelViewProjectionMatrix_hi,
    modelViewProjectionMatrix_lo,
    vec3(in_position, 0.0),
    1.0
  );

  out_data.shadowCoords = df64_mat4_mul_vec4(
    shadowMatrix_hi,
    shadowMatrix_lo,
    vec3(in_position, 0.0),
    1.0
  );
  gl_Position = z_normalization(positionClipSpace);
  out_data.screenSpaceDepth = gl_Position.w;
}
