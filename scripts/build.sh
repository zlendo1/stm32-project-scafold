#!/usr/bin/env bash
set -euo pipefail

# Color codes (respects NO_COLOR env var)
if [[ -z "${NO_COLOR:-}" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'  # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

# Configuration
PROJECT_NAME="stm32-setup-test"
BINARY_NAME="${PROJECT_NAME}.elf"
FLASH_ADDRESS="0x8000000"
OPENOCD_CONFIG="board/stm32f3discovery.cfg"
OPENOCD_PORT=3333

# Defaults
PRESET="Debug"
FLASH_TOOL="openocd"
COMMAND=""

# Helper functions
log_info() {
    echo -e "${YELLOW}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

usage() {
    cat << 'EOF'
STM32 Build Script

USAGE:
    build.sh [COMMAND] [OPTIONS]

COMMANDS:
    build       Build the project (default)
    flash       Flash firmware to device
    debug       Start GDB debugger with OpenOCD
    clean       Remove build artifacts
    help        Show this help message

OPTIONS:
    -p, --preset PRESET     Build preset: Debug or Release (default: Debug)
    -t, --flash-tool TOOL   Flash tool: stlink or openocd (default: openocd)
    -h, --help              Show this help message

EXAMPLES:
    # Build with Debug preset
    ./build.sh build

    # Build with Release preset
    ./build.sh build --preset Release

    # Flash using OpenOCD
    ./build.sh flash --flash-tool openocd

    # Debug with GDB
    ./build.sh debug

    # Clean build artifacts
    ./build.sh clean

    # Clean all presets
    ./build.sh clean --all

ENVIRONMENT:
    NO_COLOR    Disable colored output (set to any value)

EOF
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -p|--preset)
                PRESET="$2"
                shift 2
                ;;
            --preset=*)
                PRESET="${1#*=}"
                shift
                ;;
            -t|--flash-tool)
                FLASH_TOOL="$2"
                shift 2
                ;;
            --flash-tool=*)
                FLASH_TOOL="${1#*=}"
                shift
                ;;
            build|flash|debug|clean)
                COMMAND="$1"
                shift
                ;;
            --all)
                ALL_PRESETS=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Validate preset
validate_preset() {
    case "$PRESET" in
        Debug|Release)
            return 0
            ;;
        *)
            log_error "Invalid preset: $PRESET (must be Debug or Release)"
            exit 1
            ;;
    esac
}

# Validate flash tool
validate_flash_tool() {
    case "$FLASH_TOOL" in
        stlink|openocd)
            return 0
            ;;
        *)
            log_error "Invalid flash tool: $FLASH_TOOL (must be stlink or openocd)"
            exit 1
            ;;
    esac
}

# Build command
cmd_build() {
    log_info "Building with preset: $PRESET"
    
    if ! cmake --preset "$PRESET" 2>&1; then
        log_error "CMake configuration failed"
        exit 1
    fi
    
    if ! cmake --build "build/$PRESET" 2>&1; then
        log_error "Build failed"
        exit 1
    fi
    
    log_success "Build completed successfully"
}

# Flash command
cmd_flash() {
    local build_dir="build/$PRESET"
    local elf_file="$build_dir/$BINARY_NAME"
    
    if [[ ! -f "$elf_file" ]]; then
        log_error "Binary not found: $elf_file"
        log_info "Run 'build.sh build' first"
        exit 1
    fi
    
    log_info "Flashing with $FLASH_TOOL (preset: $PRESET)"
    
    if [[ "$FLASH_TOOL" == "stlink" ]]; then
        local bin_file="$build_dir/$PROJECT_NAME.bin"
        
        log_info "Converting ELF to binary..."
        if ! arm-none-eabi-objcopy -O binary "$elf_file" "$bin_file"; then
            log_error "Failed to convert ELF to binary"
            exit 1
        fi
        
        log_info "Writing to device..."
        if ! st-flash write "$bin_file" "$FLASH_ADDRESS"; then
            log_error "Flash write failed"
            exit 1
        fi
    elif [[ "$FLASH_TOOL" == "openocd" ]]; then
        log_info "Programming device via OpenOCD..."
        if ! openocd -f "$OPENOCD_CONFIG" \
            -c "program $elf_file verify reset exit"; then
            log_error "OpenOCD programming failed"
            exit 1
        fi
    fi
    
    log_success "Flashing completed successfully"
}

# Debug command
cmd_debug() {
    local build_dir="build/$PRESET"
    local elf_file="$build_dir/$BINARY_NAME"
    
    if [[ ! -f "$elf_file" ]]; then
        log_error "Binary not found: $elf_file"
        log_info "Run 'build.sh build' first"
        exit 1
    fi
    
    log_info "Starting OpenOCD in background..."
    
    # Start OpenOCD in background
    openocd -f "$OPENOCD_CONFIG" \
        -c "tcl_port disabled" \
        -c "telnet_port disabled" &
    local openocd_pid=$!
    
    # Trap to kill OpenOCD on exit
    trap "kill $openocd_pid 2>/dev/null || true" EXIT
    
    # Give OpenOCD time to start
    sleep 1
    
    log_info "Launching GDB..."
    arm-none-eabi-gdb "$elf_file" \
        -ex "target remote localhost:$OPENOCD_PORT" \
        -ex "monitor reset halt" \
        -ex "load"
}

# Clean command
cmd_clean() {
    if [[ "${ALL_PRESETS:-false}" == "true" ]]; then
        log_info "Cleaning all build artifacts..."
        if [[ -d "build" ]]; then
            rm -rf build
            log_success "Cleaned all presets"
        else
            log_info "Nothing to clean"
        fi
    else
        log_info "Cleaning preset: $PRESET"
        if [[ -d "build/$PRESET" ]]; then
            rm -rf "build/$PRESET"
            log_success "Cleaned $PRESET preset"
        else
            log_info "Nothing to clean for $PRESET"
        fi
    fi
}

# Main
main() {
    # Default to build if no command specified
    if [[ -z "$COMMAND" ]]; then
        COMMAND="build"
    fi
    
    # Validate configuration
    validate_preset
    validate_flash_tool
    
    # Execute command
    case "$COMMAND" in
        build)
            cmd_build
            ;;
        flash)
            cmd_flash
            ;;
        debug)
            cmd_debug
            ;;
        clean)
            cmd_clean
            ;;
        help)
            usage
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            usage
            exit 1
            ;;
    esac
}

# Parse arguments and run
parse_args "$@"
main
