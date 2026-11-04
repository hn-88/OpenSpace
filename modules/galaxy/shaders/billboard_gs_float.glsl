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

#include "floatoperations.glsl"
#include "powerscaling/powerscalingmath.glsl"
#include "df64.glsl"

layout(points) in;
in Data {
  vec3 color;
} in_data[];

layout(triangle_strip, max_vertices = 4) out;
out Data {
  vec4 position;
  vec2 psfCoords;
  flat vec3 color;
  flat float screenSpaceDepth;
} out_data;

uniform vec3 eyePosition_hi;
uniform vec3 eyePosition_lo;
uniform vec3 cameraUp;
uniform mat4 viewProjectionMatrix_hi;
uniform mat4 viewProjectionMatrix_lo;
uniform mat4 modelMatrix_hi;
uniform mat4 modelMatrix_lo;

const float Parsec = 3.08567756E16;

void main() {
  out_data.position = gl_in[0].gl_Position;
  out_data.color = in_data[0].color;

  df64_vec4 dpos = df64_mat4_mul_vec4(
    modelMatrix_hi,
    modelMatrix_lo,
    vec4(out_data.position.xyz * 8.0, out_data.position.w)
  );
  // In upstream, dpos is a dvec4, so dpos /= Parsec divides ALL 4 components (including w) by Parsec.
  dpos.hi /= Parsec;
  dpos.lo /= Parsec;

  // Compute normal in parsecs to prevent float overflow (FLT_MAX = 3.4e38, but squared meters = ~1e41).
  vec3 eyePos_pc = (eyePosition_hi + eyePosition_lo) / Parsec;
  vec3 dpos_pc = dpos.hi.xyz + dpos.lo.xyz;
  vec3 eyeDiff = eyePos_pc - dpos_pc;
  float m = max(abs(eyeDiff.x), max(abs(eyeDiff.y), abs(eyeDiff.z)));
  vec3 normal = m > 0.0 ? normalize(eyeDiff / m) : vec3(0.0, 0.0, 1.0);
  vec3 newRight = normalize(cross(cameraUp, normal));
  vec3 newUp = cross(normal, newRight);
  vec3 scaledRight = 32.0 * newRight;
  vec3 scaledUp = 32.0 * newUp;

  df64_vec4 bl_pos = df64_vec4(
    vec4(dpos.hi.xyz - scaledRight - scaledUp, dpos.hi.w),
    dpos.lo
  );
  vec4 bottomLeftVertex = z_normalization(df64_vec4_to_vec4(df64_mat4_mul_df64_vec4(
    viewProjectionMatrix_hi,
    viewProjectionMatrix_lo,
    bl_pos
  )));

  out_data.screenSpaceDepth = bottomLeftVertex.w;

  df64_vec4 tr_pos = df64_vec4(
    vec4(dpos.hi.xyz + scaledUp + scaledRight, dpos.hi.w),
    dpos.lo
  );
  vec4 topRightVertex = z_normalization(df64_vec4_to_vec4(df64_mat4_mul_df64_vec4(
    viewProjectionMatrix_hi,
    viewProjectionMatrix_lo,
    tr_pos
  )));

  df64_vec4 br_pos = df64_vec4(
    vec4(dpos.hi.xyz + scaledRight - scaledUp, dpos.hi.w),
    dpos.lo
  );
  vec4 bottomRightVertex = z_normalization(df64_vec4_to_vec4(df64_mat4_mul_df64_vec4(
    viewProjectionMatrix_hi,
    viewProjectionMatrix_lo,
    br_pos
  )));

  df64_vec4 tl_pos = df64_vec4(
    vec4(dpos.hi.xyz + scaledUp - scaledRight, dpos.hi.w),
    dpos.lo
  );
  vec4 topLeftVertex = z_normalization(df64_vec4_to_vec4(df64_mat4_mul_df64_vec4(
    viewProjectionMatrix_hi,
    viewProjectionMatrix_lo,
    tl_pos
  )));

  // Build primitive
  gl_Position = topLeftVertex;
  out_data.psfCoords = vec2(-1.0, 1.0);
  EmitVertex();

  gl_Position = bottomLeftVertex;
  out_data.psfCoords = vec2(-1.0, -1.0);
  EmitVertex();

  gl_Position = topRightVertex;
  out_data.psfCoords = vec2(1.0, 1.0);
  EmitVertex();

  gl_Position = bottomRightVertex;
  out_data.psfCoords = vec2(1.0, -1.0);
  EmitVertex();

  EndPrimitive();
}
