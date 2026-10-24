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

#extension GL_ARB_shader_storage_buffer_object : require

#include "floatoperations.glsl"
#include "${MODULE_GAIA}/shaders/df64.glsl"

layout (std430, binding = 0) readonly buffer StarData {
  float allData[];
};

layout (std430, binding = 1) readonly buffer AdditionalData {
  int chunkInfo[];
};

out Data {
  vec4 gPosition;
  vec2 brightness;
  float starDistFromSun;
  float cameraDistFromSun;
} out_data;

uniform mat4 model_hi;
uniform mat4 model_lo;
uniform mat4 view_hi;
uniform mat4 view_lo;
uniform mat4 projection;
uniform float time;
uniform int renderOption;
uniform int maxStarsPerNode;
uniform int valuesPerStar;
uniform int nChunksToRender;
uniform vec2 posXThreshold;
uniform vec2 posYThreshold;
uniform vec2 posZThreshold;
uniform vec2 gMagThreshold;
uniform vec2 bpRpThreshold;
uniform vec2 distThreshold;

const int RenderOptionStatic = 0;
const int RenderOptionColor = 1;
const int RenderOptionMotion = 2;
const float Eps = 1e-5;
const float Parsec = 3.0856776e16;

int findChunkId(int left, int right, int id) {
  while (left <= right) {
    int middle = (left + right) / 2;
    int chunkOffset = middle * 3;
    int firstStarIdInChunk = chunkInfo[chunkOffset];
    int nStarsInChunk = chunkInfo[chunkOffset + 1];

    if (id >= firstStarIdInChunk && id < (firstStarIdInChunk + nStarsInChunk)) {
      return middle;
    }
    if (id < firstStarIdInChunk) {
      right = middle - 1;
    }
    else {
      left = middle + 1;
    }
  }
  return -1;
}

void main() {
  int chunkId = findChunkId(0, nChunksToRender - 1, gl_VertexID);
  if (chunkId < 0) {
    out_data.gPosition = vec4(0.0);
    gl_Position = vec4(0.0);
    return;
  }

  int chunkOffset = chunkId * 3;
  int firstStarIdInChunk = chunkInfo[chunkOffset];
  int nStarsInChunk = chunkInfo[chunkOffset + 1];
  int firstStarInChunk = chunkInfo[chunkOffset + 2];
  int placeInChunk = gl_VertexID - firstStarIdInChunk;

  if (nStarsInChunk <= 0) {
    out_data.gPosition = vec4(0.0);
    gl_Position = vec4(0.0);
    return;
  }

  int idxPos = firstStarInChunk + placeInChunk * 3;
  vec3 position = vec3(allData[idxPos], allData[idxPos + 1], allData[idxPos + 2]);

  if ((abs(posXThreshold.x) > Eps && position.x < posXThreshold.x) ||
      (abs(posXThreshold.y) > Eps && position.x > posXThreshold.y) ||
      (abs(posYThreshold.x) > Eps && position.y < posYThreshold.x) ||
      (abs(posYThreshold.y) > Eps && position.y > posYThreshold.y) ||
      (abs(posZThreshold.x) > Eps && position.z < posZThreshold.x) ||
      (abs(posZThreshold.y) > Eps && position.z > posZThreshold.y) ||
      (abs(distThreshold.x - distThreshold.y) < Eps &&
      abs(length(position) - distThreshold.y) < Eps))
  {
    out_data.gPosition = vec4(0.0);
    gl_Position = vec4(0.0);
    return;
  }

  vec2 brightness = vec2(0.0);
  vec3 velocity = vec3(0.0);
  if (renderOption != RenderOptionStatic) {
    int idxCol = firstStarInChunk + nStarsInChunk * 3 + placeInChunk * 2;
    brightness = vec2(allData[idxCol], allData[idxCol + 1]);

    if ((abs(gMagThreshold.x - gMagThreshold.y) < Eps &&
         abs(gMagThreshold.x - brightness.x) < Eps) ||
        (abs(gMagThreshold.x - 20.0) > Eps && brightness.x < gMagThreshold.x) ||
        (abs(gMagThreshold.y - 20.0) > Eps && brightness.x > gMagThreshold.y) ||
        (abs(bpRpThreshold.x - bpRpThreshold.y) < Eps &&
         abs(bpRpThreshold.x - brightness.y) < Eps) ||
        (abs(bpRpThreshold.x) > Eps && brightness.y < bpRpThreshold.x) ||
        (abs(bpRpThreshold.y) > Eps && brightness.y > bpRpThreshold.y))
    {
      out_data.gPosition = vec4(0.0);
      gl_Position = vec4(0.0);
      return;
    }

    if (renderOption == RenderOptionMotion) {
      int idxVel = firstStarInChunk + nStarsInChunk * 5 + placeInChunk * 3;
      velocity = vec3(allData[idxVel], allData[idxVel + 1], allData[idxVel + 2]);
    }
  }
  out_data.brightness = brightness;

  vec4 objectPosition = vec4(position * 1000.0 * Parsec, 1.0);
  objectPosition.xyz += time * velocity;

  float distPosition = length(objectPosition.xyz / (1000.0 * Parsec));
  if ((abs(distThreshold.x - distThreshold.y) > Eps &&
      ((abs(distThreshold.x) > Eps && distPosition < distThreshold.x) ||
      (abs(distThreshold.y) > Eps && distPosition > distThreshold.y))))
  {
    out_data.gPosition = vec4(0.0);
    gl_Position = vec4(0.0);
    return;
  }

  vec4 worldPos = df64_mat4_mul_vec4(
    model_hi,
    model_lo,
    objectPosition.xyz,
    objectPosition.w
  );
  vec4 viewPosition = df64_mat4_mul_vec4(
    view_hi,
    view_lo,
    worldPos.xyz,
    worldPos.w
  );

  vec4 sunWorld = df64_mat4_mul_vec4(model_hi, model_lo, vec3(0.0), 1.0);
  vec4 sunPosition = df64_mat4_mul_vec4(view_hi, view_lo, sunWorld.xyz, sunWorld.w);

  out_data.starDistFromSun = safeLength(objectPosition);
  out_data.cameraDistFromSun = safeLength(sunPosition);

  if (length(position) > Eps) {
    out_data.gPosition = worldPos;
    gl_Position = projection * viewPosition;
  }
  else {
    out_data.gPosition = vec4(0.0);
    gl_Position = vec4(0.0);
  }
}
