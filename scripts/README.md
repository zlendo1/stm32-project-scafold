# Build Scripts

Build, flash, and debug automation for the STM32F3DISCOVERY project.

## Prerequisites

### Linux (Ubuntu/Debian)

```bash
sudo apt install gcc-arm-none-eabi gdb-arm-none-eabi cmake ninja-build openocd stlink-tools
```

### macOS

```bash
brew install arm-none-eabi-gcc cmake ninja openocd stlink
```

### Windows

```powershell
winget install -e --id Kitware.CMake
winget install -e --id Ninja-build.Ninja
```

*Note: ARM toolchain needs manual download from
[ARM website](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
or xPack. OpenOCD via MSYS2 or xPack.*

## Quick Start

```bash
# Linux/macOS
./build.sh build    # Build firmware
./build.sh flash    # Flash to device
./build.sh debug    # Start debug session

# Windows
.\build.ps1 build
.\build.ps1 flash
.\build.ps1 debug
```

## Usage

### Linux/macOS (build.sh)

```bash
./build.sh build                    # Build Debug preset
./build.sh build --preset Release   # Build Release preset
./build.sh flash                    # Flash via OpenOCD (default)
./build.sh flash --flash-tool stlink   # Flash via st-link
./build.sh debug                    # Start GDB debug session
./build.sh clean                    # Clean Debug build
./build.sh clean --all              # Clean all builds
./build.sh help                     # Show all options
```

### Windows (build.ps1)

```powershell
.\build.ps1 build                   # Build Debug preset
.\build.ps1 build -Preset Release   # Build Release preset
.\build.ps1 flash                   # Flash via OpenOCD (default)
.\build.ps1 flash -FlashTool stlink    # Flash via st-link
.\build.ps1 debug                   # Start GDB debug session
.\build.ps1 clean                   # Clean Debug build
.\build.ps1 clean -All              # Clean all builds
.\build.ps1 help                    # Show all options
```

## Manual Commands

### Building

The project uses CMake with Ninja generator.

```bash
cmake --preset Debug        # Configure (or Release)
cmake --build build/Debug   # Build
```

Output: `build/Debug/stm32-setup-test.elf`

### Flashing

#### Method 1: OpenOCD (recommended)

```bash
openocd -f board/stm32f3discovery.cfg -c "program build/Debug/stm32-setup-test.elf verify reset exit"
```

#### Method 2: st-flash

```bash
arm-none-eabi-objcopy -O binary build/Debug/stm32-setup-test.elf build/Debug/stm32-setup-test.bin
st-flash write build/Debug/stm32-setup-test.bin 0x8000000
```

### Debugging

1. Start OpenOCD server:

```bash
openocd -f board/stm32f3discovery.cfg
```

2. In another terminal, run GDB:

```bash
arm-none-eabi-gdb build/Debug/stm32-setup-test.elf
```

3. GDB commands:

```gdb
target remote localhost:3333
monitor reset halt
load
continue
```

## Options Reference

| Option     | Bash               | PowerShell   | Description                          |
| ---------- | ------------------ | ------------ | ------------------------------------ |
| Preset     | `-p, --preset`     | `-Preset`    | Debug or Release (default: Debug)    |
| Flash tool | `-t, --flash-tool` | `-FlashTool` | openocd or stlink (default: openocd) |
| Clean all  | `--all`            | `-All`       | Remove all build directories         |
| Help       | `-h, --help`       | `help`       | Show usage information               |
