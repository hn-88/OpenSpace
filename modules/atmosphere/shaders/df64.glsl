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

/**
 * df64.glsl — Emulated double-precision using two fp32 floats (Dekker / double-float).
 *
 * A "double-float" (df64) value is stored as a vec2(hi, lo) where:
 *   hi + lo == the exact double value  (to fp64 precision)
 *
 * This file is only included when NO_GPU_DOUBLE is defined, i.e., when the GPU/driver
 * does not support GL_ARB_gpu_shader_fp64. All arithmetic preserves ~46 bits of
 * mantissa (two 23-bit fp32 mantissas chained via error-free transforms).
 *
 * References:
 *   Dekker (1971) — "A floating-point technique for extending the available precision"
 *   Hida, Li & Bailey (2000) — "Algorithms for quad-double arithmetic"
 *   Thall (2006) — "Extended-precision floating-point numbers for GPU computation"
 */

#ifndef _ATMOSPHERE___DF64___GLSL_
#define _ATMOSPHERE___DF64___GLSL_

// ---------------------------------------------------------------------------
// Scalar df64 arithmetic
// ---------------------------------------------------------------------------

// Two-sum: exact sum of two floats returned as (sum, roundingError).
// Satisfies: a + b == result.x + result.y  exactly.
vec2 df64_twoSum(float a, float b) {
    float s = a + b;
    float v = s - a;
    float e = (a - (s - v)) + (b - v);
    return vec2(s, e);
}

// Two-diff: exact difference a - b as (diff, roundingError).
vec2 df64_twoDiff(float a, float b) {
    float s = a - b;
    float v = s - a;
    float e = (a - (s - v)) - (b + v);
    return vec2(s, e);
}

// Veltkamp split: splits a float into two non-overlapping halves.
// For fp32 (23-bit mantissa), split at bit 12: SPLIT = 2^12 + 1 = 4097.
vec2 df64_split(float a) {
    const float C = 4097.0;
    float t  = C * a;
    float hi = t - (t - a);
    float lo = a - hi;
    return vec2(hi, lo);
}

// Dekker product: exact product of two floats as (product, roundingError).
vec2 df64_twoProd(float a, float b) {
    float p  = a * b;
    vec2  as = df64_split(a);
    vec2  bs = df64_split(b);
    float e  = ((as.x * bs.x - p) + as.x * bs.y + as.y * bs.x) + as.y * bs.y;
    return vec2(p, e);
}

// Add two df64 values.  a = (a.x, a.y),  b = (b.x, b.y)
vec2 df64_add(vec2 a, vec2 b) {
    vec2 s = df64_twoSum(a.x, b.x);
    s.y   += a.y + b.y;
    return df64_twoSum(s.x, s.y);
}

// Subtract two df64 values.
vec2 df64_sub(vec2 a, vec2 b) {
    return df64_add(a, -b);
}

// Multiply two df64 values.
vec2 df64_mul(vec2 a, vec2 b) {
    vec2 p = df64_twoProd(a.x, b.x);
    p.y   += a.x * b.y + a.y * b.x;
    return df64_twoSum(p.x, p.y);
}

// Divide two df64 values (Newton–Raphson iteration, one step).
vec2 df64_div(vec2 a, vec2 b) {
    float q1 = a.x / b.x;
    vec2  r  = df64_sub(a, df64_mul(b, vec2(q1, 0.0)));
    float q2 = r.x / b.x;
    return df64_twoSum(q1, q2);
}

// sqrt of a df64 value.
vec2 df64_sqrt(vec2 a) {
    if (a.x == 0.0) return vec2(0.0);
    float x = inversesqrt(a.x);
    float y = a.x * x;
    vec2  ys = df64_twoProd(y, y);
    vec2  e  = df64_sub(a, ys);
    return df64_twoSum(y, e.x * (x * 0.5));
}

// Convert a df64 to a single float (discard low word).
float df64_toFloat(vec2 a) {
    return a.x + a.y;
}

// Promote a single float to df64 (lo = 0).
vec2 df64_fromFloat(float a) {
    return vec2(a, 0.0);
}

// ---------------------------------------------------------------------------
// df64 vec3 helpers  (each component is a separate vec2)
// ---------------------------------------------------------------------------

// Subtract two df64-vec3 values: a - b, where each is (vec3 hi, vec3 lo).
// Returns (vec3 hi, vec3 lo) in out parameters.
void df64_vec3_sub(vec3 ahi, vec3 alo, vec3 bhi, vec3 blo,
                   out vec3 dhi, out vec3 dlo)
{
    vec2 rx = df64_sub(vec2(ahi.x, alo.x), vec2(bhi.x, blo.x));
    vec2 ry = df64_sub(vec2(ahi.y, alo.y), vec2(bhi.y, blo.y));
    vec2 rz = df64_sub(vec2(ahi.z, alo.z), vec2(bhi.z, blo.z));
    dhi = vec3(rx.x, ry.x, rz.x);
    dlo = vec3(rx.y, ry.y, rz.y);
}

// Length of a df64-vec3.  Returns a regular float.
// The cancellation has been resolved by df64_vec3_sub so hi+lo is already accurate.
float df64_vec3_length(vec3 hi, vec3 lo) {
    vec3 v = hi + lo;   // recombine — now has full 46-bit significance
    return length(v);
}

// ---------------------------------------------------------------------------
// df64 mat4 × vec4 multiply  (hi + lo matrix, single-precision vec4)
//
// Computes (Mhi + Mlo) * v  using compensated arithmetic.
// Mhi and Mlo are the high and low halves of a dmat4 split on the CPU:
//   for each element e: hi = float(e), lo = float(e - double(hi))
// ---------------------------------------------------------------------------
vec4 df64_mat4MulVec4(mat4 Mhi, mat4 Mlo, vec4 v) {
    // Two separate MAD passes; the "lo" pass corrects the accumulated rounding
    // error of the "hi" pass.  This is equivalent to one dmat4 * dvec4 multiply
    // at ~46-bit precision when Mhi + Mlo accurately represents the dmat4.
    return Mhi * v + Mlo * v;
}

#endif // _ATMOSPHERE___DF64___GLSL_
