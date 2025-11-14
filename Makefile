ML := ./ML.exe
LINK := ./link.exe

TARGET_NAME = out.exe
SRC_DIR = src
INC_DIR = include
BUILD_DIR = build


MLFLAGS = /c /Zd /Zi /coff /I${INC_DIR} /I.
LDFLAGS = /subsystem:console
LIBS = Irvine32.lib Kernel32.lib User32.lib



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
	@if not exist $@ mkdir $@

debug:
	@echo SOURCES: $(SOURCES)
	@echo INCLUDES: $(OBJECTS)
