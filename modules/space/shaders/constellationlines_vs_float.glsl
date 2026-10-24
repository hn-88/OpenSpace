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

// ---------------------------------------------------------------------------
// Single-precision float emulation path for Constellation Lines Vertex Shader.
// Selected when NO_GPU_DOUBLE is set in the environment.
// Uses Dekker/Veltkamp df64 ModelView transformation to avoid precision loss
// across astronomical parsec coordinates.
// ---------------------------------------------------------------------------

#version __CONTEXT__

#include "powerscaling/powerscaling_vs.glsl"
#include "df64.glsl"

layout(location = 0) in vec3 in_position;

out Data {
  vec4 positionViewSpace;
  float screenSpaceDepth;
} out_data;

uniform mat4 modelViewTransform_hi;
uniform mat4 modelViewTransform_lo;
uniform mat4 projectionTransform;


void main() {
  df64_vec4 posView_df = df64_mat4_mul_vec4(
    modelViewTransform_hi,
    modelViewTransform_lo,
    vec4(in_position, 1.0)
  );
  vec4 positionViewSpace = vec4(posView_df.hi + posView_df.lo);
  gl_Position = vec4(z_normalization(projectionTransform * positionViewSpace));

  out_data.positionViewSpace = positionViewSpace;
  out_data.screenSpaceDepth = gl_Position.w;
}
