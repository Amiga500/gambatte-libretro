# Cross-Compilation Guide

This document explains how to properly cross-compile gambatte-libretro for different platforms.

## For Miyoo Mini / Miyoo Mini Plus (OnionOS)

### Using the build script (Recommended)

The easiest way is to use the provided build script:

```bash
# Default toolchain location (/opt/miyoo/usr/bin/arm-linux-)
./build_miyoo.sh miyoo-mini

# Custom toolchain location
TOOLCHAIN_PREFIX=/path/to/arm-linux-gnueabihf- ./build_miyoo.sh miyoo-mini
```

### Manual build with make

You can also build directly with make:

```bash
# Using default toolchain location
make -f Makefile.libretro platform=miyoo-mini

# Using custom toolchain location
make -f Makefile.libretro platform=miyoo-mini TOOLCHAIN_PREFIX=/path/to/arm-linux-gnueabihf-
```

Available platforms:
- `miyoo-mini` - Optimized for Miyoo Mini Plus (Cortex-A7 with NEON)
- `miyoo` - Compatible build for both Miyoo Mini and Mini Plus

## Generic Cross-Compilation

For other ARM platforms or custom cross-compilation setups:

```bash
# Using CROSS_COMPILE prefix
make -f Makefile.libretro platform=unix CROSS_COMPILE=arm-linux-gnueabihf-

# This will use:
# - CC = arm-linux-gnueabihf-gcc
# - CXX = arm-linux-gnueabihf-g++
# - AR = arm-linux-gnueabihf-ar
```

## Common Errors

### Error: "bad value 'armv7ve' for '-march=' switch"

This error occurs when you try to pass ARM-specific compiler flags to a native (non-cross) compiler.

**Wrong:**
```bash
# DON'T DO THIS - passing ARM flags without cross-compiler
make -f Makefile.libretro platform=unix \
  CFLAGS="-march=armv7ve -mtune=cortex-a7 ..."
```

**Correct:**
```bash
# Use the proper platform which includes the cross-compiler
make -f Makefile.libretro platform=miyoo-mini

# OR use CROSS_COMPILE for generic cross-compilation
make -f Makefile.libretro platform=unix \
  CROSS_COMPILE=arm-linux-gnueabihf- \
  CFLAGS="-march=armv7-a -mtune=cortex-a7 ..."
```

### Error: "Miyoo toolchain not found"

If you get this error from the build script:

1. Install the Miyoo toolchain
2. Set TOOLCHAIN_PREFIX to point to your toolchain:
   ```bash
   export TOOLCHAIN_PREFIX=/path/to/toolchain/bin/arm-linux-
   ./build_miyoo.sh miyoo-mini
   ```

## Toolchain Setup

### For Miyoo Mini

Download the Miyoo toolchain from:
- https://github.com/miyoo-oss/miyoo_src

Extract it and set TOOLCHAIN_PREFIX accordingly:
```bash
export TOOLCHAIN_PREFIX=/opt/miyoo/usr/bin/arm-linux-
```

### For Debian/Ubuntu

Install the ARM cross-compiler:
```bash
sudo apt-get install gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf
```

Then use:
```bash
make -f Makefile.libretro platform=unix CROSS_COMPILE=arm-linux-gnueabihf-
```

## Testing Your Build

After successful compilation, you should see `gambatte_libretro.so`:

```bash
# Check the architecture
file gambatte_libretro.so

# Should show something like:
# gambatte_libretro.so: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV)
```

For native builds (platform=unix without cross-compilation):
```bash
# Should show x86-64
file gambatte_libretro.so

# gambatte_libretro.so: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV)
```
