/*
 * Miyoo Mini / OnionOS Performance Optimizations
 * Target: ARM926EJ-S @ 1.2GHz (original) or ARM Cortex-A7 @ 1.2GHz (Plus), 128MB RAM
 * Goal: +30% FPS improvement for GB/GBC games
 */

#ifndef MIYOO_OPTIMIZATIONS_H
#define MIYOO_OPTIMIZATIONS_H

#ifdef GAMBATTE_MIYOO_OPTIMIZATIONS

// Fast cycle counter update - batch updates instead of per-instruction
#define MIYOO_FAST_CYCLES 1

// Skip sub-4-cycle alignment in halt mode for better performance
#define MIYOO_FAST_HALT 1

// Use optimized fixed-point audio resampling
#define MIYOO_FAST_AUDIO 1

// Reduce precision of sound event timing (safe for most games)
#define MIYOO_RELAXED_TIMING 1

// Memory allocation optimizations
#define MIYOO_REDUCE_ALLOCS 1

// Miyoo Mini Plus (Cortex-A7) has NEON support
#ifdef GAMBATTE_MIYOO_PLUS
#define MIYOO_HAS_NEON 1
#endif

#endif // GAMBATTE_MIYOO_OPTIMIZATIONS

#endif // MIYOO_OPTIMIZATIONS_H
