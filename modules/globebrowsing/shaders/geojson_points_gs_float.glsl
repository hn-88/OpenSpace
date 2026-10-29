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
#include "df64.glsl"

layout(points) in;
in Data {
  vec3 normal; // Point normals correspond to globe out direction, model space
  flat float dynamicHeight;
} in_data[];

layout(triangle_strip, max_vertices = 4) out;
out Data {
  vec4 positionViewSpace;
  vec2 texCoords;
  flat float screenSpaceDepth;
} out_data;

// General settings
uniform mat4 modelTransform_hi;
uniform mat4 modelTransform_lo;
uniform mat4 viewTransform_hi;
uniform mat4 viewTransform_lo;
uniform mat4 projectionTransform;

uniform float heightOffset;
uniform bool useHeightMapData;

// Camera information
uniform vec3 cameraUp;
uniform vec3 cameraRight;
uniform vec3 cameraPosition_hi; // world coordinates
uniform vec3 cameraPosition_lo;
uniform vec3 cameraLookUp;

uniform float pointSize;
uniform float textureWidthFactor;

// If false, use the center
uniform bool useBottomAnchorPoint = true;

// Render mode
uniform int renderMode;
// OBS! Keep in sync with option property options
const int RenderOptionCameraDir = 0;
const int RenderOptionCameraPos = 1;
const int RenderOptionGlobeNormal = 2;
const int RenderOptionGlobeSurface = 3;

const vec2 Corners[4] = vec2[4](
  vec2(0.0, 0.0),
  vec2(1.0, 0.0),
  vec2(1.0, 1.0),
  vec2(0.0, 1.0)
);


void main() {
  vec4 dpos = vec4(gl_in[0].gl_Position.xyz, 1.0);

  // Offset position based on height information
  if (length(dpos.xyz) > 0.0) {
    vec3 outDirection = normalize(dpos.xyz);
    float height =
      useHeightMapData ? in_data[0].dynamicHeight + heightOffset : heightOffset;
    dpos += vec4(outDirection * height, 0.0);
  }
  // World coordinates
  df64_vec4 worldPos_df = df64_mat4_mul_vec4(modelTransform_hi, modelTransform_lo, dpos);
  vec3 worldNormal = normalize(mat3(modelTransform_hi) * in_data[0].normal);

  // Set up and right directions based on render mode.
  // renderMode 0 is default
  vec3 right = cameraRight;
  vec3 up = cameraUp;

  df64_vec3 camPos_df = df64_vec3(cameraPosition_hi, cameraPosition_lo);
  df64_vec3 diff = df64_vec3_sub(camPos_df, df64_vec3(worldPos_df.hi.xyz, worldPos_df.lo.xyz));
  vec3 cameraToPosDir = normalize(df64_vec3_to_vec3(diff));

  // Update right and up based on render mode
  if (renderMode == RenderOptionCameraPos) {
    right = normalize(cross(cameraLookUp, cameraToPosDir));
    up = normalize(cross(cameraToPosDir, right));
  }
  else if (renderMode == RenderOptionGlobeNormal) {
    up = worldNormal;
    right = normalize(cross(up, cameraToPosDir));
  }
  else if (renderMode == RenderOptionGlobeSurface) {
    // Compute up to be orthogonal to globe normal and camera right direction
    up = normalize(cross(worldNormal, right));
    // Recompute right to be orthogonal to globe normal
    right = cross(up, worldNormal);
  }

  vec4 scaledRight = pointSize * vec4(right, 0.0) * 0.5;
  vec4 scaledUp = pointSize * vec4(up, 0.0) * 0.5;

  // View space position
  vec4 posView = df64_vec4_to_vec4(df64_mat4_mul_df64_vec4(viewTransform_hi, viewTransform_lo, worldPos_df));
  vec4 scaledRightView = viewTransform_hi * scaledRight;
  vec4 scaledUpView = viewTransform_hi * scaledUp;

  vec4 dposClip = projectionTransform * posView;
  vec4 scaledRightClip = textureWidthFactor * (projectionTransform * scaledRightView);
  vec4 scaledUpClip = projectionTransform * scaledUpView;

  // Place anchor point at the bottom
  vec4 bottomLeft = z_normalization(dposClip - scaledRightClip);
  vec4 bottomRight = z_normalization(dposClip + scaledRightClip);
  vec4 topRight = z_normalization(dposClip + 2.0 * scaledUpClip + scaledRightClip);
  vec4 topLeft = z_normalization(dposClip + 2.0 * scaledUpClip - scaledRightClip);

  if (!useBottomAnchorPoint) {
    // Place anchor point at the center
    bottomLeft = z_normalization(dposClip - scaledRightClip - scaledUpClip);
    bottomRight = z_normalization(dposClip + scaledRightClip - scaledUpClip);
    topRight = z_normalization(dposClip + scaledUpClip + scaledRightClip);
    topLeft = z_normalization(dposClip + scaledUpClip - scaledRightClip);
  }

  out_data.screenSpaceDepth = bottomLeft.w;
  out_data.positionViewSpace = posView;

  // Build primitive
  out_data.texCoords = Corners[0];
  gl_Position = bottomLeft;
  EmitVertex();

  out_data.texCoords = Corners[1];
  gl_Position = bottomRight;
  EmitVertex();

  out_data.texCoords = Corners[3];
  gl_Position = topLeft;
  EmitVertex();

  out_data.texCoords = Corners[2];
  gl_Position = topRight;
  EmitVertex();

  EndPrimitive();
}
