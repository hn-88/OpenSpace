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
#include "tile.glsl"
#include "texturetilemapping.glsl"
#include "tileheight.glsl"
#include "tilevertexskirt.glsl"
#include "df64.glsl"

#define nDepthMaps #{nDepthMaps}

layout(location = 1) in vec2 in_texCoords;

out Data {
  vec4 position;
  vec2 texCoords;
  float isSkirt;
  vec3 ellipsoidNormalCameraSpace;
  vec3 levelWeights;
  vec3 positionCameraSpace;
  vec3 posObjSpace;
  vec3 normalObjSpace;
#if USE_ACCURATE_NORMALS
  vec3 ellipsoidTangentThetaCameraSpace;
  vec3 ellipsoidTangentPhiCameraSpace;
#endif // USE_ACCURATE_NORMALS
#if USE_ECLIPSE_SHADOWS
  vec3 positionWorldSpace;
#endif // USE_ECLIPSE_SHADOWS
#if SHADOW_MAPPING_ENABLED
  vec4 shadowCoords;
#endif // SHADOW_MAPPING_ENABLED
#if nDepthMaps > 0
  vec4 positionsLightspace[nDepthMaps];
#endif // nDepthMaps > 0
} out_data;

uniform mat4 inverseViewTransform_hi;
uniform mat4 inverseViewTransform_lo;
uniform mat4 modelTransform_hi;
uniform mat4 modelTransform_lo;

#if SHADOW_MAPPING_ENABLED
  uniform mat4 shadowMatrix_hi;
  uniform mat4 shadowMatrix_lo;
#endif // SHADOW_MAPPING_ENABLED

uniform mat4 projectionTransform;
// Input points in camera space
uniform vec3 p00;
uniform vec3 p10;
uniform vec3 p01;
uniform vec3 p11;
uniform vec3 patchNormalCameraSpace;
uniform float chunkMinHeight;
uniform float distanceScaleFactor;
uniform int chunkLevel;

#if nDepthMaps > 0
  uniform mat4 inverseView_hi;
  uniform mat4 inverseView_lo;
  uniform mat4 lightView_hi[nDepthMaps];
  uniform mat4 lightView_lo[nDepthMaps];
#endif // nDepthMaps > 0


vec3 bilinearInterpolation(vec2 uv) {
  vec3 p0 = mix(p00, p10, uv.x);
  vec3 p1 = mix(p01, p11, uv.x);
  return mix(p0, p1, uv.y);
}


void main() {
  // Position in cameraspace
  vec3 p = bilinearInterpolation(in_texCoords);

  // Calculate desired level based on distance to the vertex on the ellipsoid
  // Before any heightmapping is done
  float distToVertexOnEllipsoid = length(p + patchNormalCameraSpace * chunkMinHeight);

  // use level weight for height sampling, and output to fragment shader
  float projectedScaleFactor = distanceScaleFactor / distToVertexOnEllipsoid;
  float desiredLevel = log2(projectedScaleFactor);
  float levelInterp = chunkLevel - desiredLevel;
  out_data.levelWeights = vec3(
    clamp(1.0 - levelInterp, 0.0, 1.0),
    clamp(levelInterp, 0.0, 1.0) - clamp(levelInterp - 1.0, 0.0, 1.0),
    clamp(levelInterp - 1.0, 0.0, 1.0)
  );

  // Get the height value and apply skirts
  float skirtLength = tileVertexSkirtLength();
  out_data.isSkirt = skirtLength > 0.0 ? 1.0 : 0.0;
  float height =
    tileHeightScaled(in_texCoords, out_data.levelWeights) - skirtLength *
    100.0;

  // Translate the point along normal
  p += patchNormalCameraSpace * height;

#if USE_ACCURATE_NORMALS
  // Calculate tangents
  out_data.ellipsoidTangentThetaCameraSpace = normalize(p10 - p00);
  out_data.ellipsoidTangentPhiCameraSpace = normalize(p01 - p00);
#endif // USE_ACCURATE_NORMALS

  // Write output
  out_data.texCoords = in_texCoords;
  out_data.position = z_normalization(projectionTransform * vec4(p, 1.0));
  gl_Position = out_data.position;
  out_data.ellipsoidNormalCameraSpace = patchNormalCameraSpace;
  out_data.positionCameraSpace = p;
  out_data.posObjSpace = df64_vec4_to_vec4(
    df64_mat4_mul_vec4(inverseViewTransform_hi, inverseViewTransform_lo, vec4(p, 1.0))
  ).xyz;

#if USE_ECLIPSE_SHADOWS
  out_data.positionWorldSpace = df64_vec4_to_vec4(
    df64_mat4_mul_vec4(modelTransform_hi, modelTransform_lo, vec4(p, 1.0))
  ).xyz;
#endif // USE_ECLIPSE_SHADOWS

#if SHADOW_MAPPING_ENABLED
  out_data.shadowCoords = df64_vec4_to_vec4(
    df64_mat4_mul_vec4(shadowMatrix_hi, shadowMatrix_lo, vec4(p, 1.0))
  );
#endif // SHADOW_MAPPING_ENABLED

#if nDepthMaps > 0
  for (int idx = 0; idx < nDepthMaps; idx++) {
    df64_vec4 posWorld = df64_mat4_mul_vec4(
      inverseView_hi, inverseView_lo, vec4(p, 1.0)
    );
    out_data.positionsLightspace[idx] = df64_vec4_to_vec4(
      df64_mat4_mul_df64_vec4(lightView_hi[idx], lightView_lo[idx], posWorld)
    );
  }
#endif // nDepthMaps > 0
}
