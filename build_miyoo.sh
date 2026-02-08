#!/bin/bash
# Build script for lr-gambatte optimized for Miyoo Mini / OnionOS
# Handles cross-compilation and provides helpful output

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PLATFORM="${1:-miyoo-mini}"
JOBS="${2:-$(nproc)}"
TOOLCHAIN_PREFIX="${TOOLCHAIN_PREFIX:-/opt/miyoo/usr/bin/arm-linux-}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  lr-gambatte Build Script${NC}"
echo -e "${BLUE}  Optimized for Miyoo Mini / OnionOS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check platform
if [ "$PLATFORM" != "miyoo-mini" ] && [ "$PLATFORM" != "miyoo" ] && [ "$PLATFORM" != "unix" ]; then
    echo -e "${RED}Error: Unknown platform '$PLATFORM'${NC}"
    echo "Usage: $0 [platform] [jobs]"
    echo "  platform: miyoo-mini (default, optimized), miyoo (compatible), unix (native)"
    echo "  jobs: number of parallel jobs (default: $(nproc))"
    exit 1
fi

# Check if we need cross-compilation
if [ "$PLATFORM" = "miyoo-mini" ] || [ "$PLATFORM" = "miyoo" ]; then
    # Check for Miyoo toolchain
    if [ ! -f "${TOOLCHAIN_PREFIX}gcc" ]; then
        echo -e "${RED}Error: Miyoo toolchain not found at ${TOOLCHAIN_PREFIX}gcc${NC}"
        echo ""
        echo "Please install the Miyoo toolchain first:"
        echo "  1. Download from: https://github.com/miyoo-oss/miyoo_src"
        echo "  2. Extract to /opt/miyoo/"
        echo "  3. Or set TOOLCHAIN_PREFIX environment variable"
        echo ""
        echo "Example:"
        echo "  export TOOLCHAIN_PREFIX=/path/to/toolchain/bin/arm-linux-"
        echo "  $0 $PLATFORM"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Miyoo toolchain found${NC}"
    echo "  GCC: ${TOOLCHAIN_PREFIX}gcc"
    ${TOOLCHAIN_PREFIX}gcc --version | head -n 1
fi

# Show build configuration
echo ""
echo "Build Configuration:"
echo "  Platform: $PLATFORM"
echo "  Jobs: $JOBS"
echo "  Makefile: Makefile.libretro"

if [ "$PLATFORM" = "miyoo-mini" ]; then
    echo ""
    echo -e "${YELLOW}Optimizations enabled:${NC}"
    echo "  - ARM Cortex-A7 tuning"
    echo "  - NEON SIMD instructions"
    echo "  - Link Time Optimization (LTO)"
    echo "  - Fast math operations"
    echo "  - Performance mode (auto-enabled)"
fi

echo ""
echo -e "${BLUE}Starting build...${NC}"
echo ""

# Clean previous build
echo "Cleaning previous build..."
make -f Makefile.libretro platform=$PLATFORM clean > /dev/null 2>&1 || true

# Build
echo "Building gambatte_libretro.so..."
if make -f Makefile.libretro platform=$PLATFORM -j$JOBS; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Build Successful!${NC}"
    echo -e "${GREEN}========================================${NC}"
    
    # Show output file info
    if [ -f "gambatte_libretro.so" ]; then
        echo ""
        echo "Output file: gambatte_libretro.so"
        ls -lh gambatte_libretro.so
        
        # Show file type and architecture
        echo ""
        echo "File information:"
        file gambatte_libretro.so
        
        # Calculate size
        SIZE=$(stat -c%s "gambatte_libretro.so" 2>/dev/null || stat -f%z "gambatte_libretro.so" 2>/dev/null || echo "unknown")
        SIZE_KB=$((SIZE / 1024))
        echo "Size: ${SIZE_KB} KB"
        
        # Show symbols (if stripped or not)
        if command -v ${TOOLCHAIN_PREFIX}strip > /dev/null 2>&1; then
            if ${TOOLCHAIN_PREFIX}nm gambatte_libretro.so > /dev/null 2>&1; then
                echo "Symbols: Present (not stripped)"
                echo ""
                echo -e "${YELLOW}Tip: Strip symbols to reduce size:${NC}"
                echo "  ${TOOLCHAIN_PREFIX}strip gambatte_libretro.so"
            else
                echo "Symbols: Stripped"
            fi
        fi
        
        echo ""
        echo -e "${GREEN}Next steps:${NC}"
        echo "  1. Test build (if on compatible system):"
        echo "     ./benchmark_fps.sh --quick /path/to/test.gb"
        echo ""
        echo "  2. Install on Miyoo Mini:"
        echo "     scp gambatte_libretro.so root@<miyoo-ip>:/mnt/SDCARD/RetroArch/.retroarch/cores/"
        echo ""
        echo "  3. Or copy to SD card:"
        echo "     cp gambatte_libretro.so /path/to/sdcard/RetroArch/.retroarch/cores/"
        echo ""
        echo "  4. Enable 'Performance Mode' in RetroArch core options for best results"
        
    else
        echo -e "${RED}Warning: Output file not found${NC}"
    fi
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  Build Failed!${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "Check the error messages above for details."
    echo ""
    echo "Common issues:"
    echo "  - Missing toolchain: Set TOOLCHAIN_PREFIX"
    echo "  - Missing dependencies: Install build-essential"
    echo "  - Wrong platform: Try 'unix' for native build"
    exit 1
fi
