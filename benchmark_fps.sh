#!/bin/bash
# Benchmark script for lr-gambatte RetroArch core on Miyoo Mini/OnionOS
# Tests FPS performance improvements with different ROMs

# Configuration
RETROARCH_BIN=${RETROARCH_BIN:-"retroarch"}
CORE_PATH=${CORE_PATH:-"./gambatte_libretro.so"}
ROM_DIR=${ROM_DIR:-"./test_roms"}
BENCHMARK_FRAMES=${BENCHMARK_FRAMES:-3600}  # 60 seconds at 60 FPS
LOG_FILE="benchmark_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  lr-gambatte FPS Benchmark for Miyoo Mini"
echo "  OnionOS Performance Testing"
echo "=========================================="
echo ""

# Check if bc is available (needed for floating point math)
if ! command -v bc &> /dev/null; then
    echo -e "${RED}Error: 'bc' command not found${NC}"
    echo "Please install bc: sudo apt-get install bc"
    exit 1
fi

# Check if RetroArch is available
if ! command -v $RETROARCH_BIN &> /dev/null; then
    echo -e "${RED}Error: RetroArch not found at $RETROARCH_BIN${NC}"
    echo "Set RETROARCH_BIN environment variable to RetroArch path"
    exit 1
fi

# Check if core exists
if [ ! -f "$CORE_PATH" ]; then
    echo -e "${RED}Error: Core not found at $CORE_PATH${NC}"
    echo "Set CORE_PATH environment variable to gambatte_libretro.so path"
    exit 1
fi

# Check if ROM directory exists
if [ ! -d "$ROM_DIR" ]; then
    echo -e "${YELLOW}Warning: ROM directory not found at $ROM_DIR${NC}"
    echo "Set ROM_DIR environment variable to your ROM directory"
    echo "Creating test directory..."
    mkdir -p "$ROM_DIR"
fi

echo "Configuration:"
echo "  RetroArch: $RETROARCH_BIN"
echo "  Core: $CORE_PATH"
echo "  ROM Directory: $ROM_DIR"
echo "  Benchmark Frames: $BENCHMARK_FRAMES"
echo "  Log File: $LOG_FILE"
echo ""

# Function to benchmark a single ROM
benchmark_rom() {
    local rom_path="$1"
    local rom_name=$(basename "$rom_path")
    
    echo -e "${YELLOW}Testing: $rom_name${NC}"
    
    # Run RetroArch in benchmark mode
    # We'll measure the actual time it takes to render N frames
    local start_time=$(date +%s.%N)
    
    # Run retroarch with the ROM, render N frames, then exit
    timeout 120 $RETROARCH_BIN \
        -L "$CORE_PATH" \
        "$rom_path" \
        --verbose \
        --max-frames=$BENCHMARK_FRAMES \
        2>&1 | tee -a "$LOG_FILE" | grep -i "fps\|performance\|frame" || true
    
    local end_time=$(date +%s.%N)
    local elapsed=$(echo "$end_time - $start_time" | bc)
    
    # Calculate average FPS
    local avg_fps=$(echo "scale=2; $BENCHMARK_FRAMES / $elapsed" | bc)
    
    echo -e "${GREEN}  Average FPS: $avg_fps${NC}"
    echo -e "${GREEN}  Time: ${elapsed}s${NC}"
    echo ""
    
    # Log results
    echo "ROM: $rom_name, Frames: $BENCHMARK_FRAMES, Time: ${elapsed}s, FPS: $avg_fps" >> "$LOG_FILE"
}

# Function to run comprehensive benchmark
run_benchmark() {
    echo "Starting benchmark..."
    echo "Date: $(date)" > "$LOG_FILE"
    echo "Core: $CORE_PATH" >> "$LOG_FILE"
    echo "Benchmark Frames: $BENCHMARK_FRAMES" >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
    
    # Find all GB/GBC ROMs
    local rom_count=0
    local total_fps=0
    
    for ext in gb gbc GB GBC; do
        for rom in "$ROM_DIR"/*.$ext; do
            if [ -f "$rom" ]; then
                benchmark_rom "$rom"
                rom_count=$((rom_count + 1))
                
                # Extract FPS from log
                local last_fps=$(tail -n 1 "$LOG_FILE" | grep -oP 'FPS: \K[0-9.]+' || echo "0")
                total_fps=$(echo "$total_fps + $last_fps" | bc)
            fi
        done
    done
    
    if [ $rom_count -eq 0 ]; then
        echo -e "${RED}No ROMs found in $ROM_DIR${NC}"
        echo "Please add some .gb or .gbc ROM files to test"
        exit 1
    fi
    
    # Calculate average across all ROMs
    local avg_all=$(echo "scale=2; $total_fps / $rom_count" | bc)
    
    echo "=========================================="
    echo "  Benchmark Complete"
    echo "=========================================="
    echo "  Total ROMs tested: $rom_count"
    echo -e "  Average FPS: ${GREEN}$avg_all${NC}"
    echo "  Log file: $LOG_FILE"
    echo ""
}

# Function to run quick test with a single ROM
quick_test() {
    local rom="$1"
    
    if [ ! -f "$rom" ]; then
        echo -e "${RED}Error: ROM file not found: $rom${NC}"
        exit 1
    fi
    
    echo "Quick test mode"
    echo "ROM: $rom"
    echo ""
    
    benchmark_rom "$rom"
}

# Parse command line arguments
case "${1:-}" in
    --quick|-q)
        if [ -z "$2" ]; then
            echo "Usage: $0 --quick <rom_path>"
            exit 1
        fi
        quick_test "$2"
        ;;
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --quick,-q <rom>  Run quick test with a single ROM"
        echo "  --help,-h         Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  RETROARCH_BIN       Path to RetroArch binary (default: retroarch)"
        echo "  CORE_PATH           Path to gambatte_libretro.so (default: ./gambatte_libretro.so)"
        echo "  ROM_DIR             Directory containing test ROMs (default: ./test_roms)"
        echo "  BENCHMARK_FRAMES    Number of frames to render (default: 3600 = 60s)"
        echo ""
        echo "Example:"
        echo "  CORE_PATH=/path/to/gambatte_libretro.so $0"
        echo "  $0 --quick pokemon_gold.gbc"
        ;;
    *)
        run_benchmark
        ;;
esac

echo "Done!"
