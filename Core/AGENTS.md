# Core — Application Code

User-modifiable application code. All modifications go here.

## STRUCTURE

```
Core/
├── Inc/              # Headers
│   ├── main.h        # Pin defines, function prototypes
│   ├── stm32f3xx_hal_conf.h  # HAL module enable/disable
│   └── stm32f3xx_it.h        # Interrupt prototypes
└── Src/
    ├── main.c              # Entry point, main loop, peripheral init
    ├── stm32f3xx_it.c      # Interrupt handlers
    ├── stm32f3xx_hal_msp.c # HAL MSP (low-level peripheral setup)
    ├── system_stm32f3xx.c  # SystemInit, SystemCoreClock
    ├── syscalls.c          # Newlib syscalls (_write, _read, etc.)
    └── sysmem.c            # Heap management (_sbrk)
```

## WHERE TO LOOK

| Task                  | File         | Location                          |
| --------------------- | ------------ | --------------------------------- |
| Main loop logic       | `Src/main.c` | `USER CODE BEGIN WHILE` block     |
| Add variables         | `Src/main.c` | `USER CODE BEGIN PV` block        |
| Add functions         | `Src/main.c` | `USER CODE BEGIN 0` or `4` blocks |
| Add includes          | `Src/main.c` | `USER CODE BEGIN Includes` block  |
| Configure peripherals | CubeMX       | `.ioc` file, regenerate           |

## CURRENT IMPLEMENTATION

**LED Animation**: Rotates through 8 compass LEDs (PE8-PE15) at 100ms intervals
when button pressed.

```
LED_PINS[] = {LD4, LD3, LD5, LD7, LD9, LD10, LD8, LD6}  // circular order
animation_enabled: toggled by B1 button press
current_led: index 0-7, wraps
```

## ANTI-PATTERNS

- **NEVER** edit outside `USER CODE BEGIN/END` — CubeMX regeneration will delete
- **NEVER** block in interrupt handlers — use flags, process in main loop
- **NEVER** call HAL_Delay() in ISR context

## PERIPHERAL HANDLES

| Handle        | Peripheral | Configured                 |
| ------------- | ---------- | -------------------------- |
| `hi2c1`       | I2C1       | PB6/PB7, 7-bit addressing  |
| `hspi1`       | SPI1       | PA5/PA6/PA7, 4-bit, master |
| `hpcd_USB_FS` | USB        | PA11/PA12, full speed      |

## ADDING NEW CODE

1. Simple logic → Add to `USER CODE` blocks in existing files
2. New peripheral → Configure in CubeMX, regenerate, add logic in `USER CODE`
3. New module → Create files, add to `CMakeLists.txt` target_sources
