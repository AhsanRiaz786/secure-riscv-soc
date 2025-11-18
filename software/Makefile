# Makefile for Secure RISC-V SoC Firmware
# Compiles boot ROM and application firmware

# Toolchain
TOOLCHAIN_PREFIX ?= riscv64-unknown-elf-
CC      = $(TOOLCHAIN_PREFIX)gcc
AS      = $(TOOLCHAIN_PREFIX)as
LD      = $(TOOLCHAIN_PREFIX)ld
OBJCOPY = $(TOOLCHAIN_PREFIX)objcopy
OBJDUMP = $(TOOLCHAIN_PREFIX)objdump
SIZE    = $(TOOLCHAIN_PREFIX)size

# Flags
ARCH_FLAGS = -march=rv32i -mabi=ilp32
CFLAGS = $(ARCH_FLAGS) -O2 -g -Wall -Wextra -ffreestanding -nostdlib
ASFLAGS = $(ARCH_FLAGS)
LDFLAGS = $(ARCH_FLAGS) -nostdlib -nostartfiles

# Directories
BUILD_DIR = ../build
MEM_INIT_DIR = ../hardware/mem_init
TOOLS_DIR = tools

# Output files
BOOT_ELF = $(BUILD_DIR)/boot.elf
BOOT_BIN = $(BUILD_DIR)/boot.bin
BOOT_HEX = $(MEM_INIT_DIR)/boot_rom.hex

FW_ELF = $(BUILD_DIR)/firmware.elf
FW_BIN = $(BUILD_DIR)/firmware.bin
FW_HEX = $(MEM_INIT_DIR)/firmware.hex

# Source files
BOOT_SRC = boot/boot.S
FW_SRCS = firmware/start.S common/uart.c firmware/test_mpu.c

.PHONY: all clean boot firmware

all: boot firmware
	@echo ""
	@echo "================================================"
	@echo "  Build Complete!"
	@echo "================================================"
	@echo "Boot ROM:  $(BOOT_HEX)"
	@echo "Firmware:  $(FW_HEX)"
	@echo ""

# Create build directories
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(MEM_INIT_DIR):
	mkdir -p $(MEM_INIT_DIR)

# Build boot ROM
boot: $(BOOT_HEX)

$(BOOT_HEX): $(BOOT_ELF) | $(MEM_INIT_DIR)
	@echo "Creating boot ROM hex file..."
	$(OBJCOPY) -O binary $(BOOT_ELF) $(BOOT_BIN)
	python3 $(TOOLS_DIR)/bin2hex.py $(BOOT_BIN) $(BOOT_HEX) 1024
	@echo "✓ Boot ROM ready"

$(BOOT_ELF): $(BOOT_SRC) boot/boot.ld | $(BUILD_DIR)
	@echo "Compiling boot ROM..."
	$(CC) $(ASFLAGS) -T boot/boot.ld -o $(BOOT_ELF) $(BOOT_SRC)
	$(OBJDUMP) -d $(BOOT_ELF) > $(BUILD_DIR)/boot.dis
	$(SIZE) $(BOOT_ELF)

# Build firmware
firmware: $(FW_HEX)

$(FW_HEX): $(FW_ELF) | $(MEM_INIT_DIR)
	@echo "Creating firmware hex file..."
	$(OBJCOPY) -O binary $(FW_ELF) $(FW_BIN)
	python3 $(TOOLS_DIR)/bin2hex.py $(FW_BIN) $(FW_HEX) 16384
	@echo "✓ Firmware ready"

$(FW_ELF): $(FW_SRCS) firmware/firmware.ld | $(BUILD_DIR)
	@echo "Compiling firmware..."
	$(CC) $(CFLAGS) -T firmware/firmware.ld -o $(FW_ELF) $(FW_SRCS)
	$(OBJDUMP) -d $(FW_ELF) > $(BUILD_DIR)/firmware.dis
	$(SIZE) $(FW_ELF)

# Clean
clean:
	rm -rf $(BUILD_DIR)
	rm -f $(MEM_INIT_DIR)/*.hex
	@echo "Clean complete"

# Help
help:
	@echo "Secure RISC-V SoC Firmware Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build boot ROM and firmware (default)"
	@echo "  boot      - Build boot ROM only"
	@echo "  firmware  - Build firmware only"
	@echo "  clean     - Remove build artifacts"
	@echo "  help      - Show this help"
	@echo ""
	@echo "Variables:"
	@echo "  TOOLCHAIN_PREFIX - RISC-V toolchain prefix (default: riscv64-unknown-elf-)"

