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

layout(lines) in;
in Data {
  flat float currentRevolutionFraction;
  flat float vertexRevolutionFraction;
} in_data[];

layout(triangle_strip, max_vertices = 4) out;
out Data {
  vec4 viewSpace;
  vec2 texCoords;
  float projectionViewDepth;
} out_data;

uniform mat4 modelTransform_hi;
uniform mat4 modelTransform_lo;
uniform mat4 viewTransform_hi;
uniform mat4 viewTransform_lo;
uniform mat4 projectionTransform;
uniform float pointSizeExponent;
uniform bool enableMaxSize;
uniform float maxSize;
uniform int renderOption;

// Camera View Direction
uniform vec3 cameraViewDirectionUp;
uniform vec3 cameraViewDirectionRight;

// Camera Normal
uniform vec3 cameraPositionWorld_hi;
uniform vec3 cameraPositionWorld_lo;
uniform vec3 cameraUpWorld;

const int RenderOptionCameraViewDirection = 0;
const int RenderOptionCameraPositionNormal = 1;

void main() {
  float cFrac = in_data[0].currentRevolutionFraction;
  float v0Frac = in_data[0].vertexRevolutionFraction;
  float v1Frac = in_data[1].vertexRevolutionFraction;

  float dFrac = cFrac - v0Frac;
  float vFrac = v1Frac - v0Frac;
  float percentage = dFrac / vFrac;

  vec4 pos = mix(gl_in[0].gl_Position, gl_in[1].gl_Position, percentage);

  vec4 vertPosWorldSpace = df64_mat4_mul_vec4(
    modelTransform_hi,
    modelTransform_lo,
    pos.xyz,
    pos.w
  );
  vec3 camPosToVertPos = df64_vec3_sub(
    cameraPositionWorld_hi,
    cameraPositionWorld_lo,
    vertPosWorldSpace.xyz,
    vec3(0.0)
  );

  vec3 up;
  vec3 right;
  if (renderOption == RenderOptionCameraViewDirection) {
    up = cameraViewDirectionUp;
    right = cameraViewDirectionRight;
  }
  else {
    vec3 normal = normalize(camPosToVertPos);
    right = normalize(cross(cameraUpWorld, normal));
    up = normalize(cross(normal, right));
  }

  float initialSize = pow(10.0, pointSizeExponent);
  right *= initialSize;
  up *= initialSize;

  float opp = length(right);
  float adj = length(camPosToVertPos);
  float angle = atan(opp / adj);
  float maxAngle = radians(maxSize * 0.5);

  if (enableMaxSize && (angle > maxAngle) && (adj > 0.0)) {
    float correction = (adj * tan(maxAngle)) / opp;
    right *= correction;
    up *= correction;
  }

  vec4 p0World = vec4(vertPosWorldSpace.xyz + (up - right), 1.0);
  vec4 p1World = vec4(vertPosWorldSpace.xyz + (-right - up), 1.0);
  vec4 p2World = vec4(vertPosWorldSpace.xyz + (right + up), 1.0);
  vec4 p3World = vec4(vertPosWorldSpace.xyz + (right - up), 1.0);

  vec4 viewSpaceOrigin = df64_mat4_mul_vec4(
    viewTransform_hi,
    viewTransform_lo,
    vertPosWorldSpace.xyz,
    1.0
  );
  out_data.viewSpace = z_normalization(projectionTransform * viewSpaceOrigin);
  out_data.projectionViewDepth = out_data.viewSpace.w;

  // left-top
  vec4 v0 = df64_mat4_mul_vec4(viewTransform_hi, viewTransform_lo, p0World.xyz, 1.0);
  gl_Position = z_normalization(projectionTransform * v0);
  out_data.texCoords = vec2(0.0, 0.0);
  EmitVertex();

  // left-bot
  vec4 v1 = df64_mat4_mul_vec4(viewTransform_hi, viewTransform_lo, p1World.xyz, 1.0);
  gl_Position = z_normalization(projectionTransform * v1);
  out_data.texCoords = vec2(1.0, 0.0);
  EmitVertex();

  // right-top
  vec4 v2 = df64_mat4_mul_vec4(viewTransform_hi, viewTransform_lo, p2World.xyz, 1.0);
  gl_Position = z_normalization(projectionTransform * v2);
  out_data.texCoords = vec2(0.0, 1.0);
  EmitVertex();

  // right-bot
  vec4 v3 = df64_mat4_mul_vec4(viewTransform_hi, viewTransform_lo, p3World.xyz, 1.0);
  gl_Position = z_normalization(projectionTransform * v3);
  out_data.texCoords = vec2(1.0, 1.0);
  EmitVertex();

  EndPrimitive();
}
