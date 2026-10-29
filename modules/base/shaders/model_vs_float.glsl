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
#include "df64.glsl"

layout(location = 0) in vec4 in_position;
layout(location = 1) in vec2 in_texCoords;
layout(location = 2) in vec3 in_normal;
layout(location = 3) in vec3 in_tangent;
layout(location = 4) in vec3 in_color;

out Data {
  vec4 positionCameraSpace;
  vec2 texCoords;
  vec3 normalViewSpace;
  vec3 color;
  float screenSpaceDepth;
  mat3 tbn;
  vec4 lightspacePosition;
} out_data;

uniform mat4 modelViewTransform;
uniform mat4 projectionTransform;
uniform mat4 normalTransform;
uniform mat4 meshTransform;
uniform mat4 meshNormalTransform;

uniform mat4 model_hi;
uniform mat4 model_lo;
uniform mat4 light_vp_hi;
uniform mat4 light_vp_lo;

void main() {
  out_data.positionCameraSpace = modelViewTransform * (meshTransform * in_position);

  gl_Position = z_normalization(projectionTransform * out_data.positionCameraSpace);
  out_data.texCoords = in_texCoords;
  out_data.color = in_color;
  out_data.screenSpaceDepth = gl_Position.w;

  out_data.normalViewSpace =
    normalize(mat3(normalTransform) * (mat3(meshNormalTransform) * in_normal));

  // TBN matrix for normal mapping
  vec3 t = normalize(mat3(normalTransform) * (mat3(meshNormalTransform) * in_tangent));
  vec3 n = normalize(mat3(normalTransform) * (mat3(meshNormalTransform) * in_normal));

  // Re-orthogonalize t with respect to n
  t = normalize(t - dot(t, n) * n);

  // Retrieve perpendicular vector b with cross product of t and n
  vec3 b = normalize(cross(n, t));
  out_data.tbn = mat3(t, b, n);

  vec4 meshPos = meshTransform * in_position;
  vec4 worldPos = df64_mat4_mul_vec4(model_hi, model_lo, meshPos.xyz, meshPos.w);
  out_data.lightspacePosition = df64_mat4_mul_vec4(light_vp_hi, light_vp_lo, worldPos.xyz, worldPos.w);
}
