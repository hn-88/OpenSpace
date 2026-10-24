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
layout(location = 1) in vec3 in_normal;
layout(location = 2) in float in_height;

out Data {
  vec4 positionViewSpace;
  vec3 normal;
  float depth;
} out_data;

uniform mat4 modelTransform_hi;
uniform mat4 modelTransform_lo;
uniform mat4 viewTransform_hi;
uniform mat4 viewTransform_lo;
uniform mat4 projectionTransform;
uniform mat3 normalTransform;

uniform float heightOffset;
uniform bool useHeightMapData;


void main() {
  vec4 modelPos = vec4(in_position, 1.0);

  // Offset model pos based on height info
  if (length(in_position) > 0.0) {
    vec3 outDirection = normalize(in_position);
    float height = useHeightMapData ? in_height + heightOffset : heightOffset;
    modelPos += vec4(outDirection * height, 0.0);
  }

  df64_vec4 worldPos = df64_mat4_mul_vec4(modelTransform_hi, modelTransform_lo, modelPos);
  vec4 viewPos = df64_vec4_to_vec4(df64_mat4_mul_df64_vec4(viewTransform_hi, viewTransform_lo, worldPos));

  out_data.positionViewSpace = viewPos;
  out_data.normal = normalize(normalTransform * in_normal);
  gl_Position = projectionTransform * out_data.positionViewSpace;
  // Set z to 0 to disable near and far plane, unique handling for perspective in space
  gl_Position.z = 0.0;
  out_data.depth = gl_Position.w;
}
