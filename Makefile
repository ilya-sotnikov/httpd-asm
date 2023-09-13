.PHONY: all clean

AS := nasm

SRC_DIR := src
TARGET_DIR := target

TARGET_NAME := asm-httpd
SRC := $(wildcard $(SRC_DIR)/*.asm)
OBJ := $(filter %.o, $(SRC:$(SRC_DIR)/%.asm=$(TARGET_DIR)/%.o))

AS_FLAGS := -f elf64 -I $(SRC_DIR)

all: $(TARGET_DIR)/$(TARGET_NAME)

$(TARGET_DIR)/$(TARGET_NAME): $(OBJ)
	$(LD) -o $@ $^

$(TARGET_DIR)/%.o: $(SRC_DIR)/%.asm
	mkdir -p $(TARGET_DIR)
	$(AS) $(AS_FLAGS) -o $@ $<

clean:
	rm -rf $(TARGET_DIR)
