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
#include "${MODULE_GALAXY}/shaders/df64.glsl"

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec3 in_color;

out Data {
  vec4 position;
  vec3 color;
  float screenSpaceDepth;
  float starBrightness;
} out_data;

uniform mat4 viewProjectionMatrix_hi;
uniform mat4 viewProjectionMatrix_lo;
uniform mat4 modelMatrix_hi;
uniform mat4 modelMatrix_lo;
uniform vec3 eyePosition_hi;
uniform vec3 eyePosition_lo;

const float Parsec = 3.08567756E16;

void main() {
  out_data.position = vec4(in_position, 1.0);

  vec3 eyeDiff = df64_vec3_sub(in_position, vec3(0.0), eyePosition_hi, eyePosition_lo);
  float distanceToStar = length(eyeDiff);
  out_data.starBrightness = clamp(8000.0 * Parsec / distanceToStar, 0.0, 1.0);

  vec4 dpos = df64_mat4_mul_vec4(
    modelMatrix_hi,
    modelMatrix_lo,
    in_position * 8.0,
    1.0
  );
  dpos.xyz /= Parsec;

  gl_Position = z_normalization(df64_mat4_mul_vec4(
    viewProjectionMatrix_hi,
    viewProjectionMatrix_lo,
    dpos.xyz,
    dpos.w
  ));
  out_data.color = in_color;
  out_data.screenSpaceDepth = gl_Position.w;
}
