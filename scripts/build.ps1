<#
.SYNOPSIS
    STM32 Project Build Script
.DESCRIPTION
    PowerShell build automation for STM32F303VCTx firmware project.
    Supports build, flash, debug, and clean operations.
.EXAMPLE
    .\build.ps1 build -Preset Debug
    .\build.ps1 flash -FlashTool stlink
    .\build.ps1 debug
    .\build.ps1 clean -All
#>

param(
    [Parameter(Position=0)]
    [ValidateSet("build","flash","debug","clean","help")]
    [string]$Command = "help",
    
    [ValidateSet("Debug","Release")]
    [string]$Preset = "Debug",
    
    [ValidateSet("stlink","openocd")]
    [string]$FlashTool = "openocd",
    
    [switch]$All
)

$ErrorActionPreference = "Stop"

# Project configuration
$ProjectName = "stm32-setup-test"
$BuildDir = "build"
$BinaryName = "$ProjectName.elf"
$BinaryPath = Join-Path $BuildDir $Preset $BinaryName
$BinPath = Join-Path $BuildDir $Preset "$ProjectName.bin"
$OpenOcdConfig = "board/stm32f3discovery.cfg"
$FlashAddress = "0x8000000"

# Color output helper
function Write-Status {
    param([string]$Message, [string]$Color = "Green")
    Write-Host "[*] $Message" -ForegroundColor $Color
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[!] ERROR: $Message" -ForegroundColor Red
    exit 1
}

# Build function
function Invoke-Build {
    Write-Status "Configuring CMake with preset: $Preset"
    & cmake --preset $Preset
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "CMake configuration failed"
    }
    
    Write-Status "Building project..."
    & cmake --build "$BuildDir/$Preset"
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Build failed"
    }
    
    Write-Status "Build completed successfully" "Green"
}

# Flash function
function Invoke-Flash {
    if (-not (Test-Path $BinaryPath)) {
        Write-Error-Custom "Binary not found: $BinaryPath. Run 'build' first."
    }
    
    if ($FlashTool -eq "stlink") {
        Write-Status "Converting ELF to binary..."
        & arm-none-eabi-objcopy -O binary $BinaryPath $BinPath
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "objcopy conversion failed"
        }
        
        Write-Status "Flashing with st-link..."
        & st-flash write $BinPath $FlashAddress
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "st-flash failed"
        }
    }
    elseif ($FlashTool -eq "openocd") {
        Write-Status "Flashing with OpenOCD..."
        & openocd -f $OpenOcdConfig -c "program $BinaryPath verify reset exit"
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "OpenOCD flash failed"
        }
    }
    
    Write-Status "Flash completed successfully" "Green"
}

# Debug function
function Invoke-Debug {
    if (-not (Test-Path $BinaryPath)) {
        Write-Error-Custom "Binary not found: $BinaryPath. Run 'build' first."
    }
    
    Write-Status "Starting OpenOCD server..."
    $OpenOcdProcess = Start-Process -FilePath "openocd" `
        -ArgumentList "-f $OpenOcdConfig" `
        -NoNewWindow `
        -PassThru
    
    # Register cleanup on exit
    $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
        if ($OpenOcdProcess -and -not $OpenOcdProcess.HasExited) {
            Write-Status "Stopping OpenOCD..." "Yellow"
            Stop-Process -Id $OpenOcdProcess.Id -Force -ErrorAction SilentlyContinue
        }
    }
    
    Start-Sleep -Seconds 2
    
    Write-Status "Launching GDB debugger..."
    & arm-none-eabi-gdb `
        -ex "target remote localhost:3333" `
        -ex "monitor reset halt" `
        -ex "load" `
        $BinaryPath
    
    # Cleanup
    if ($OpenOcdProcess -and -not $OpenOcdProcess.HasExited) {
        Stop-Process -Id $OpenOcdProcess.Id -Force -ErrorAction SilentlyContinue
    }
}

# Clean function
function Invoke-Clean {
    if ($All) {
        Write-Status "Cleaning all build artifacts..."
        if (Test-Path $BuildDir) {
            Remove-Item -Path $BuildDir -Recurse -Force
            Write-Status "Removed $BuildDir" "Green"
        }
    }
    else {
        $PresetBuildDir = Join-Path $BuildDir $Preset
        Write-Status "Cleaning $Preset build..."
        if (Test-Path $PresetBuildDir) {
            Remove-Item -Path $PresetBuildDir -Recurse -Force
            Write-Status "Removed $PresetBuildDir" "Green"
        }
    }
}

# Help function
function Show-Help {
    Write-Host @"
STM32 Project Build Script

USAGE:
    .\build.ps1 <command> [options]

COMMANDS:
    build       Configure and build the project
    flash       Flash firmware to device
    debug       Start debugging session with GDB
    clean       Remove build artifacts
    help        Show this help message

OPTIONS:
    -Preset <Debug|Release>         Build preset (default: Debug)
    -FlashTool <stlink|openocd>     Flashing tool (default: stlink)
    -All                            Clean all presets (with clean command)

EXAMPLES:
    .\build.ps1 build
    .\build.ps1 build -Preset Release
    .\build.ps1 flash -FlashTool stlink
    .\build.ps1 flash -FlashTool openocd
    .\build.ps1 debug
    .\build.ps1 clean
    .\build.ps1 clean -All

REQUIREMENTS:
    - CMake 3.20+
    - arm-none-eabi-gcc toolchain
    - st-flash (for stlink flashing)
    - OpenOCD (for openocd flashing and debugging)
    - arm-none-eabi-gdb (for debugging)

"@ -ForegroundColor Cyan
}

# Main dispatcher
switch ($Command) {
    "build" {
        Invoke-Build
    }
    "flash" {
        Invoke-Flash
    }
    "debug" {
        Invoke-Debug
    }
    "clean" {
        Invoke-Clean
    }
    "help" {
        Show-Help
    }
    default {
        Write-Error-Custom "Unknown command: $Command"
    }
}
