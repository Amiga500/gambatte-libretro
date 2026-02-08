/*
 * NEON-optimized functions for Miyoo Mini & Miyoo Mini Plus
 * SigmaStar SSD202D - ARM Cortex-A7 with NEON SIMD support
 * 
 * Note: Both devices use identical hardware, so these optimizations
 * apply to both Miyoo Mini and Miyoo Mini Plus.
 */

#ifndef MIYOO_NEON_H
#define MIYOO_NEON_H

#if defined(MIYOO_HAS_NEON) && defined(__ARM_NEON)
#include <arm_neon.h>

namespace gambatte {

// NEON-optimized RGB565 color conversion for 4 pixels at once
// Processes 4 BGR15 colors (64 bits) to 4 RGB565 colors (64 bits)
#ifdef VIDEO_RGB565
static inline void gbcToRgb565_neon_fast(const uint16_t* bgr15_input, uint16_t* rgb565_output)
{
   // Load 4 BGR15 pixels
   uint16x4_t bgr15 = vld1_u16(bgr15_input);
   
   // Extract R, G, B components (5 bits each)
   uint16x4_t r = vand_u16(bgr15, vdup_n_u16(0x1F));
   uint16x4_t g = vand_u16(vshr_n_u16(bgr15, 5), vdup_n_u16(0x1F));
   uint16x4_t b = vshr_n_u16(bgr15, 10);
   
   // Fast color correction: rFinal = ((r * 13) + (g * 2) + b) >> 4
   // Use multiply-accumulate for efficiency
   uint16x4_t r_mul13 = vmul_n_u16(r, 13);
   uint16x4_t g_mul2 = vshl_n_u16(g, 1);  // g * 2
   uint16x4_t r_tmp = vadd_u16(r_mul13, g_mul2);
   uint16x4_t r_final = vshr_n_u16(vadd_u16(r_tmp, b), 4);
   
   // gFinal = ((g * 3) + b) >> 2
   uint16x4_t g_mul3 = vadd_u16(g, vshl_n_u16(g, 1));  // g * 3
   uint16x4_t g_final = vshr_n_u16(vadd_u16(g_mul3, b), 2);
   
   // bFinal = ((r * 3) + (g * 2) + (b * 11)) >> 4
   uint16x4_t r_mul3 = vadd_u16(r, vshl_n_u16(r, 1));  // r * 3
   uint16x4_t b_mul11 = vadd_u16(b, vadd_u16(vshl_n_u16(b, 1), vshl_n_u16(b, 3))); // b * 11
   uint16x4_t b_tmp = vadd_u16(vadd_u16(r_mul3, g_mul2), b_mul11);
   uint16x4_t b_final = vshr_n_u16(b_tmp, 4);
   
   // Clamp to 5 bits for R and B, 6 bits for G
   r_final = vmin_u16(r_final, vdup_n_u16(0x1F));
   g_final = vmin_u16(g_final, vdup_n_u16(0x3F));
   b_final = vmin_u16(b_final, vdup_n_u16(0x1F));
   
   // Pack into RGB565: RRRRR GGGGGG BBBBB
   uint16x4_t rgb565 = vorr_u16(vshl_n_u16(r_final, 11),
                        vorr_u16(vshl_n_u16(g_final, 5), b_final));
   
   // Store result
   vst1_u16(rgb565_output, rgb565);
}

// NEON-optimized RGB565 conversion without color correction
static inline void gbcToRgb565_neon_nocc(const uint16_t* bgr15_input, uint16_t* rgb565_output)
{
   // Load 4 BGR15 pixels
   uint16x4_t bgr15 = vld1_u16(bgr15_input);
   
   // Extract R, G, B components (5 bits each)
   uint16x4_t r = vand_u16(bgr15, vdup_n_u16(0x1F));
   uint16x4_t g = vand_u16(vshr_n_u16(bgr15, 5), vdup_n_u16(0x1F));
   uint16x4_t b = vshr_n_u16(bgr15, 10);
   
   // Pack into RGB565: RRRRR GGGGGG BBBBB
   // Green stays at 5 bits, shifted to position 5
   uint16x4_t rgb565 = vorr_u16(vshl_n_u16(r, 11),
                        vorr_u16(vshl_n_u16(g, 5), b));
   
   // Store result
   vst1_u16(rgb565_output, rgb565);
}
#endif // VIDEO_RGB565

// NEON-optimized audio resampling kernel multiply-accumulate
static inline void audio_resample_mac_neon(int32_t* accum_l, int32_t* accum_r,
                                           const int16_t* samples, const int16_t* kernel, 
                                           unsigned count)
{
   int32x4_t acc_l = vld1q_s32(accum_l);
   int32x4_t acc_r = vld1q_s32(accum_r);
   
   unsigned i;
   for (i = 0; i < (count & ~3); i += 4)
   {
      // Load 4 stereo samples (L,R,L,R,L,R,L,R)
      int16x4x2_t stereo = vld2_s16(samples + i * 2);
      
      // Load 4 kernel coefficients
      int16x4_t kern = vld1_s16(kernel + i);
      
      // Multiply and accumulate
      acc_l = vmlal_s16(acc_l, stereo.val[0], kern);
      acc_r = vmlal_s16(acc_r, stereo.val[1], kern);
   }
   
   vst1q_s32(accum_l, acc_l);
   vst1q_s32(accum_r, acc_r);
   
   // Handle remaining samples (scalar fallback)
   for (; i < count; i++)
   {
      accum_l[0] += samples[i * 2] * kernel[i];
      accum_r[0] += samples[i * 2 + 1] * kernel[i];
   }
}

} // namespace gambatte

#endif // MIYOO_HAS_NEON && __ARM_NEON

#endif // MIYOO_NEON_H
