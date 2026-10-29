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
  vec4 orientation;
  float colorParameter;
  float textureLayer;
  float scalingParameter;
} in_data[];

layout(triangle_strip, max_vertices = 4) out;
out Data {
  vec4 positionViewSpace;
  vec2 texCoords;
  float screenSpaceDepth;
  flat int textureLayer;
  flat float colorParameter;
} out_data;

// General settings
uniform float scaleExponent;
uniform float scaleFactor;
uniform int renderOption;
uniform mat4 cameraViewMatrix_hi;
uniform mat4 cameraViewMatrix_lo;
uniform mat4 projectionMatrix;
uniform mat4 modelMatrix_hi;
uniform mat4 modelMatrix_lo;
uniform bool enableMaxSizeControl;
uniform bool hasDvarScaling;
uniform float dvarScaleFactor;
uniform bool useOrientationData;

// RenderOption: CameraViewDirection
uniform vec3 up;
uniform vec3 right;

// RenderOption: CameraPositionNormal
uniform vec3 cameraPosition_hi;
uniform vec3 cameraPosition_lo;
uniform vec3 cameraLookUp;

// Max size control: true
// The max size is an angle, in degrees, for the diameter
uniform float maxAngularSize;

uniform vec2 aspectRatioScale;

const vec2 Corners[4] = vec2[4](
  vec2(0.0, 0.0),
  vec2(1.0, 0.0),
  vec2(1.0, 1.0),
  vec2(0.0, 1.0)
);

const int RenderOptionCameraViewDirection = 0;
const int RenderOptionCameraPositionNormal = 1;
const int RenderOptionFixedRotation = 2;

// Quaternion math code from:
// https://gist.github.com/mattatz/40a91588d5fb38240403f198a938a593
vec4 quatMult(vec4 q1, vec4 q2) {
  return vec4(
    q2.xyz * q1.w + q1.xyz * q2.w + cross(q1.xyz, q2.xyz),
    q1.w * q2.w - dot(q1.xyz, q2.xyz)
  );
}

// Vector rotation with a quaternion
// http://mathworld.wolfram.com/Quaternion.html
vec3 rotateVector(vec3 v, vec4 q) {
  vec4 qConjugate = q * vec4(-1.0, -1.0, -1.0, 1.0);
  return quatMult(q, quatMult(vec4(v, 0.0), qConjugate)).xyz;
}

void main() {
  out_data.textureLayer = int(in_data[0].textureLayer);
  out_data.colorParameter = in_data[0].colorParameter;

  vec4 dpos = df64_mat4_mul_vec4(
    modelMatrix_hi,
    modelMatrix_lo,
    gl_in[0].gl_Position.xyz,
    1.0
  );

  float scaleMultiply = pow(10.0, scaleExponent);
  if (hasDvarScaling) {
    scaleMultiply *= in_data[0].scalingParameter * dvarScaleFactor;
  }

  vec3 scaledRight = vec3(1.0, 0.0, 0.0);
  vec3 scaledUp = vec3(0.0, 1.0, 0.0);

  if (renderOption == RenderOptionCameraViewDirection) {
    scaledRight = right;
    scaledUp = up;
  }
  else if (renderOption == RenderOptionCameraPositionNormal) {
    vec3 normal = normalize(df64_vec3_sub(
      cameraPosition_hi,
      cameraPosition_lo,
      dpos.xyz,
      vec3(0.0)
    ));
    vec3 newRight = normalize(cross(cameraLookUp, normal));
    vec3 newUp = cross(normal, newRight);

    scaledRight = newRight;
    scaledUp = newUp;
  }
  else if (renderOption == RenderOptionFixedRotation) {
    if (useOrientationData) {
      vec4 quat = in_data[0].orientation;
      scaledRight = normalize(rotateVector(scaledRight, quat));
      scaledUp = normalize(rotateVector(scaledUp, quat));
    }
  }

  scaledRight *= scaleMultiply * 0.5;
  scaledUp *= scaleMultiply * 0.5;

  if (enableMaxSizeControl) {
    float desiredAngleRadians = radians(maxAngularSize * 0.5);

    vec3 camToPos = df64_vec3_sub(
      dpos.xyz,
      vec3(0.0),
      cameraPosition_hi,
      cameraPosition_lo
    );
    float distanceToCamera = length(camToPos);
    float pointSize = length(scaledRight);
    float angle = atan(pointSize / distanceToCamera);

    if ((angle > desiredAngleRadians) && (distanceToCamera > 0.0)) {
      float correctionScaleFactor =
        distanceToCamera * tan(desiredAngleRadians) / pointSize;
      scaledRight *= correctionScaleFactor;
      scaledUp *= correctionScaleFactor;
    }
  }

  vec4 viewPos = df64_mat4_mul_vec4(
    cameraViewMatrix_hi,
    cameraViewMatrix_lo,
    dpos.xyz,
    1.0
  );
  out_data.positionViewSpace = viewPos;

  vec4 dposClip = projectionMatrix * viewPos;

  vec4 scaledRightView = df64_mat4_mul_vec4(
    cameraViewMatrix_hi,
    cameraViewMatrix_lo,
    scaledRight,
    0.0
  );
  vec4 scaledRightClip = scaleFactor * aspectRatioScale.x * (projectionMatrix * scaledRightView);

  vec4 scaledUpView = df64_mat4_mul_vec4(
    cameraViewMatrix_hi,
    cameraViewMatrix_lo,
    scaledUp,
    0.0
  );
  vec4 scaledUpClip = scaleFactor * aspectRatioScale.y * (projectionMatrix * scaledUpView);

  vec4 initialPosition = z_normalization(dposClip - scaledRightClip - scaledUpClip);
  out_data.screenSpaceDepth = initialPosition.w;

  // Build primitive
  out_data.texCoords = Corners[0];
  gl_Position = initialPosition;
  EmitVertex();

  out_data.texCoords = Corners[1];
  gl_Position = z_normalization(dposClip + scaledRightClip - scaledUpClip);
  EmitVertex();

  out_data.texCoords = Corners[3];
  gl_Position = z_normalization(dposClip + scaledUpClip - scaledRightClip);
  EmitVertex();

  out_data.texCoords = Corners[2];
  gl_Position = z_normalization(dposClip + scaledUpClip + scaledRightClip);
  EmitVertex();

  EndPrimitive();
}
