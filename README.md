# STM32F3DISCOVERY Template

Project template for STM32F3DISCOVERY.

Clone this template, generate STM32CubeMX code into it, and start developing.

## Quick Start

### 1. Clone

```bash
git clone https://github.com/youruser/stm32f3discovery-template my-project
cd my-project
```

### 2. Generate STM32CubeMX Code

1. Open **STM32CubeMX**
2. Select board: **STM32F3DISCOVERY**
3. Configure peripherals as needed
4. **Project Manager** tab:
   - Project Name: `my-project`
   - Project Location: *this repository's parent directory*
   - Toolchain/IDE: **CMake**
5. Click **Generate Code**

CubeMX creates: `Core/`, `Drivers/`, `startup_*.s`, `STM32*_FLASH.ld`,
`cmake/stm32cubemx/CMakeLists.txt`

### 3. Build and Flash

```bash
./scripts/build.sh build    # Build firmware
./scripts/build.sh flash    # Flash to device
./scripts/build.sh debug    # Start GDB session
```

Or manually:

```bash
cmake --preset Debug
cmake --build build/Debug
openocd -f board/stm32f3discovery.cfg -c "program build/Debug/my-project.elf verify reset exit"
```

## Prerequisites

| Tool | Linux | macOS | Windows | | ------- | ------------------------------- |
-------------------------------- | ---------------------------------- | | ARM
GCC | `apt install gcc-arm-none-eabi` | `brew install arm-none-eabi-gcc` |
`scoop install gcc-arm-none-eabi` | | CMake | `apt install cmake` |
`brew install cmake` | `winget install Kitware.CMake` | | Ninja |
`apt install ninja-build` | `brew install ninja` |
`winget install Ninja-build.Ninja` | | OpenOCD | `apt install openocd` |
`brew install openocd` | MSYS2 or xPack |

## Project Structure

```
├── scripts/
│   ├── build.sh                   # Linux/macOS automation
│   └── build.ps1                  # Windows automation
├── .clang-format                  # Code style
└── .clangd                        # LSP config
```

After CubeMX generation:

```
├── Core/                          # Your application code
│   ├── Inc/                       # Headers
│   └── Src/                       # main.c, interrupts, etc.
├── Drivers/                       # HAL/CMSIS (gitignored)
├── startup_stm32f303xc.s          # Startup assembly
└── STM32F303XX_FLASH.ld           # Linker script
```

## Development Workflow

1. **Configure peripherals** → STM32CubeMX → Generate Code
2. **Write application code** → `Core/Src/main.c` inside `USER CODE` blocks
3. **Build** → `./scripts/build.sh build`
4. **Flash** → `./scripts/build.sh flash`
5. **Debug** → `./scripts/build.sh debug`

Code inside `USER CODE BEGIN/END` blocks is preserved across CubeMX
regeneration.

## Hardware

- **Board**: STM32F3DISCOVERY
- **MCU**: STM32F303VCTx (Cortex-M4, 72MHz max, FPU)
- **Flash**: 256KB @ 0x08000000
- **RAM**: 40KB @ 0x20000000 + 8KB CCMRAM @ 0x10000000

## License

MIT
