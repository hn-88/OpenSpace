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

#include "powerscaling/powerscalingmath.glsl"
#include "${MODULE_SPACE}/shaders/df64.glsl"

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec3 in_orbitData; // 1: timeOffset, 2: epoch, 3: period

out Data {
  vec4 viewSpacePosition;
  float viewSpaceDepth;
  float periodFraction;
  float offsetPeriods;
} out_data;

uniform mat4 modelViewTransform_hi;
uniform mat4 modelViewTransform_lo;
uniform mat4 projectionTransform;
uniform float inGameTime;

void main() {
  float timeOffset = in_orbitData.x;
  float epoch = in_orbitData.y;
  float period = in_orbitData.z;

  float nrOfRevolutions = (inGameTime - epoch) / period;
  float frac = float(int(nrOfRevolutions));
  out_data.periodFraction = nrOfRevolutions - frac;
  if (out_data.periodFraction < 0.0) {
    out_data.periodFraction += 1.0;
  }

  out_data.offsetPeriods = timeOffset / period;
  out_data.viewSpacePosition = df64_mat4_mul_vec4(
    modelViewTransform_hi,
    modelViewTransform_lo,
    in_position,
    1.0
  );
  gl_Position = z_normalization(projectionTransform * out_data.viewSpacePosition);
  out_data.viewSpaceDepth = gl_Position.w;
}
