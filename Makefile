ML := wine ./ML.EXE
LINK := wine ./link.exe

TARGET_NAME = out.exe
SRC_DIR = src
INC_DIR = include
BUILD_DIR = build


MLFLAGS = /c /Zd /Zi /coff /I${INC_DIR} /I.
LDFLAGS = /subsystem:console
LIBS = Irvine32.lib Kernel32.lib User32.lib ws2_32.lib



SOURCES = $(wildcard $(SRC_DIR)/*.asm)
OBJECTS = $(patsubst $(SRC_DIR)/%.asm,$(BUILD_DIR)/%.obj,$(SOURCES))

.PHONY: all
all: $(BUILD_DIR) $(TARGET_NAME)

$(TARGET_NAME): $(OBJECTS)
	@echo [LINK] $@
	$(LINK) $(LDFLAGS) $(OBJECTS) $(LIBS) /OUT:$@

$(BUILD_DIR)/%.obj: $(SRC_DIR)/%.asm
	@echo [ML] $<
	$(ML) $(MLFLAGS) /Fo$@ $<

$(BUILD_DIR):
	mkdir -p $@

.PHONY: run
run: all
	@echo [RUN] $(TARGET_GET)
	./$(TARGET_NAME)

