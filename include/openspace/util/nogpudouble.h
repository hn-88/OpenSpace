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

#pragma once

#include <cstdlib>
#include <string>
#include <string_view>
#include <utility>
#include <glm/glm.hpp>

namespace openspace {

struct EnvCheckResult {
    bool enabled = false;
    std::string varName;
    std::string value;
};

/**
 * Checks whether the NO_GPU_DOUBLE (or NO_DOUBLE / OPENSPACE_NO_GPU_DOUBLE)
 * environment variable is set to a truthy value (e.g. 1, true, TRUE).
 * If unset, empty, or set to 0/false, enabled is false.
 */
inline EnvCheckResult checkNoGpuDoubleEnv() {
    for (const char* varName : { "NO_GPU_DOUBLE", "NO_DOUBLE", "OPENSPACE_NO_GPU_DOUBLE" }) {
        const char* val = std::getenv(varName);
        if (val) {
            std::string_view sv(val);
            while (!sv.empty() && (sv.front() == ' ' || sv.front() == '\t')) {
                sv.remove_prefix(1);
            }
            while (!sv.empty() && (sv.back() == ' ' || sv.back() == '\t' || sv.back() == '\r' || sv.back() == '\n')) {
                sv.remove_suffix(1);
            }
            if (!sv.empty() && sv != "0" && sv != "false" && sv != "FALSE" && sv != "False") {
                return { true, varName, std::string(sv) };
            }
            else {
                return { false, varName, std::string(sv) };
            }
        }
    }
    return { false, "", "" };
}

inline bool isNoGpuDoubleSet() {
    return checkNoGpuDoubleEnv().enabled;
}

/**
 * Splits a 64-bit double precision 4x4 matrix into two 32-bit float 4x4 matrices
 * representing the high and low parts using exact Dekker/Veltkamp error decomposition:
 *   val = hi + lo  (where hi is float(val) and lo is float(val - double(hi)))
 */
inline std::pair<glm::mat4, glm::mat4> splitDmat4(const glm::dmat4& m) {
    glm::mat4 hi;
    glm::mat4 lo;
    for (int col = 0; col < 4; ++col) {
        for (int row = 0; row < 4; ++row) {
            const double val = m[col][row];
            const float h = static_cast<float>(val);
            const float l = static_cast<float>(val - static_cast<double>(h));
            hi[col][row] = h;
            lo[col][row] = l;
        }
    }
    return { hi, lo };
}

/**
 * Splits a 64-bit double precision 3D vector into two 32-bit float 3D vectors
 * representing the high and low parts using exact Dekker/Veltkamp error decomposition.
 */
inline std::pair<glm::vec3, glm::vec3> splitDvec3(const glm::dvec3& v) {
    const float hx = static_cast<float>(v.x);
    const float lx = static_cast<float>(v.x - static_cast<double>(hx));
    const float hy = static_cast<float>(v.y);
    const float ly = static_cast<float>(v.y - static_cast<double>(hy));
    const float hz = static_cast<float>(v.z);
    const float lz = static_cast<float>(v.z - static_cast<double>(hz));
    return { glm::vec3(hx, hy, hz), glm::vec3(lx, ly, lz) };
}

} // namespace openspace
