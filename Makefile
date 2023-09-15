.PHONY: all debug release test clean

AS := nasm

SRC_DIR := src
TARGET_DIR := target
TESTS_DIR := tests

TARGET_NAME := httpd-asm
TEST_NAME := $(TARGET_NAME)-test

SRC := $(wildcard $(SRC_DIR)/*.asm)
OBJ := $(filter %.o, $(SRC:$(SRC_DIR)/%.asm=$(TARGET_DIR)/%.o))

TEST_SRC := $(wildcard $(TESTS_DIR)/*.asm)
TEST_OBJ := $(filter %.o, $(TEST_SRC:$(TESTS_DIR)/%.asm=$(TARGET_DIR)/%.o))
TEST_OBJ += $(filter-out $(TARGET_DIR)/main.o, $(OBJ))

AS_FLAGS := -w+all -w+error -f elf64 -I $(SRC_DIR)

debug: AS_FLAGS += -g
release: LD_FLAGS += -s
test: AS_FLAGS += -g

all: release
debug: $(TARGET_DIR)/$(TARGET_NAME)
release: $(TARGET_DIR)/$(TARGET_NAME)
test: $(TARGET_DIR)/$(TEST_NAME)

$(TARGET_DIR)/$(TARGET_NAME): $(OBJ)
	$(LD) $(LD_FLAGS) -o $@ $^

$(TARGET_DIR)/%.o: $(SRC_DIR)/%.asm
	mkdir -p $(TARGET_DIR)
	$(AS) $(AS_FLAGS) -o $@ $<

$(TARGET_DIR)/%.o: $(TESTS_DIR)/%.asm
	mkdir -p $(TARGET_DIR)
	$(AS) $(AS_FLAGS) -o $@ $<

$(TARGET_DIR)/$(TEST_NAME): $(TEST_OBJ)
	$(LD) $(LD_FLAGS) -o $@ $^
	./$@

clean:
	rm -rf $(TARGET_DIR)
