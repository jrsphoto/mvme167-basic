# m68k Enhanced BASIC for MVME167
# Direct S-record output from vasm (no linker needed)

AS = vasmm68k_mot
OBJDUMP = m68k-elf-objdump

ASFLAGS = -m68040 -Fsrec -nocase -quiet

SOURCE = src/enhanced_basic.s
BUILD_DIR = build

SREC_RAM = $(BUILD_DIR)/enhanced_basic_ram.srec

.PHONY: all clean disasm help

all: $(SREC_RAM)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Assemble directly to S-record
$(SREC_RAM): $(SOURCE) | $(BUILD_DIR)
	@echo "Assembling to S-record..."
	@$(AS) $(ASFLAGS) -o $@ $<
	@echo "✓ S-record created: $@"
	@ls -lh $@

disasm: $(SOURCE) | $(BUILD_DIR)
	$(AS) -m68040 -Felf -nocase -quiet -o $(BUILD_DIR)/enhanced_basic.o $<
	$(OBJDUMP) -d $(BUILD_DIR)/enhanced_basic.o > $(BUILD_DIR)/enhanced_basic.asm
	@echo "✓ Disassembly created: $(BUILD_DIR)/enhanced_basic.asm"

clean:
	rm -rf $(BUILD_DIR)
	@echo "✓ Clean complete"

help:
	@echo "Enhanced BASIC for MVME167 - Build Targets"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  make              Build RAM version (default)"
	@echo "  make disasm       Generate disassembly listing"
	@echo "  make clean        Remove all build artifacts"
	@echo "  make help         Show this help"
