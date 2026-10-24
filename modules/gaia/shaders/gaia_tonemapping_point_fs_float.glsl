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

#include "fragment.glsl"

in Data {
  vec2 texCoords;
} in_data;

uniform sampler2D renderedTexture;
uniform mat4 projection;
uniform vec2 screenSize;
uniform int filterSize;
uniform float sigma;
uniform float pixelWeightThreshold;

const float M_PI = 3.141592653589793238462;
const float DefaultDepth = 3.08567758e19; // 1000 Pc

Fragment getFragment() {
  mat4 proj = projection;
  float near = proj[3][2] / (proj[2][2] - 1.0);
  float left = near * (proj[2][0] - 1.0) / proj[0][0];
  float right = near * (proj[2][0] + 1.0) / proj[0][0];
  float top = near * (proj[2][1] + 1.0) / proj[1][1];
  float bottom = near * (proj[2][1] - 1.0) / proj[1][1];

  float xFactor = proj[0][0];
  float yFactor = proj[1][1];

  float planeAspect = yFactor / xFactor;
  float screenAspect = screenSize.x / screenSize.y;
  float fullAspect = planeAspect / screenAspect;

  vec2 screenPos =
    in_data.texCoords * vec2(right - left, top - bottom) + vec2(left, bottom);

  float beta = atan(length(screenPos) / near);
  vec2 sigmaScaleFactor = vec2(1.0 / cos(beta), 1.0 / pow(cos(beta), 2.0));

  float defaultScreen = 1200.0;
  float scaling = screenSize.y / defaultScreen * yFactor;

  vec2 filterScaleFactor = vec2(
    pow(screenPos.x / near, 2.0) * fullAspect,
    pow(screenPos.y / near, 2.0)
  );

  bool useCircleDist = false;

  vec2 newFilterSize = vec2(filterSize) * (1.0 + length(filterScaleFactor)) * scaling;

  float a = 0.0;
  float b = 0.0;
  float c = 0.0;
  if (!useCircleDist) {
    float alpha = atan(screenPos.y, screenPos.x);
    float sigmaMajor = sigma * sigmaScaleFactor.y * scaling;
    float sigmaMinor = sigma * sigmaScaleFactor.x * scaling;

    a = pow(cos(alpha), 2.0) / (2.0 * pow(sigmaMajor, 2.0)) +
        pow(sin(alpha), 2.0) / (2.0 * pow(sigmaMinor, 2.0));
    b = sin(2.0 * alpha) / (4.0 * pow(sigmaMajor, 2.0)) -
        sin(2.0 * alpha) / (4.0 * pow(sigmaMinor, 2.0));
    c = pow(sin(alpha), 2.0) / (2.0 * pow(sigmaMajor, 2.0)) +
        pow(cos(alpha), 2.0) / (2.0 * pow(sigmaMinor, 2.0));
  }

  vec3 intensity = vec3(0.0);
  vec2 pixelSize = 1.0 / screenSize;
  ivec2 halfFilterSize = ivec2((newFilterSize - 1.0) / 2.0);
  for (int y = -halfFilterSize.y; y <= halfFilterSize.y; y++) {
    for (int x = -halfFilterSize.x; x <= halfFilterSize.x; x++) {
      vec2 sPoint = in_data.texCoords + (pixelSize * ivec2(x, y));

      float pixelWeight = exp(
        -(a * pow(x * fullAspect, 2.0) + 2.0 * b * x * y * fullAspect + c * pow(y, 2.0))
      );

      if (all(greaterThan(sPoint, vec2(0.0))) && all(lessThan(sPoint, vec2(1.0))) &&
          pixelWeight > pixelWeightThreshold)
      {
        vec4 sIntensity = texture(renderedTexture, sPoint);

        if (useCircleDist) {
          float circleDist = sqrt(pow(x / (1.0 + length(filterScaleFactor)), 2.0) +
            pow(y / (1.0 + length(filterScaleFactor)), 2.0));
          intensity += sIntensity.rgb * (1.0 / (sigma * sqrt(2.0 * M_PI))) *
            exp(-(pow(circleDist, 2.0) / (2.0 * pow(sigma, 2.0)))) / filterSize;
        }
        else {
          intensity += sIntensity.rgb * pixelWeight * fullAspect;
        }
      }
    }
  }

  intensity = pow(intensity, vec3(0.8));

  if (length(intensity) < 0.01) {
    discard;
  }

  Fragment frag;
  frag.color = vec4(intensity, 1.0);
  frag.depth = DefaultDepth;
  frag.gNormal = vec4(0.0, 0.0, 0.0, 1.0);
  frag.blend = BlendModeNormal;

  return frag;
}
