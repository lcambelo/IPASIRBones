# Makefile for IPASIRBones
# Compatible with Linux and macOS
#
# IMPORTANT: SAT solver libraries must be rebuilt on the target platform.
# If switching between macOS and Linux, run 'make clean-all' first to
# remove platform-specific object files, then rebuild with 'make solvers'.
#
# Requirements:
#   - C++17 compatible compiler (GCC 7+ or Clang 5+)
#   - GCC 10+ recommended for -flto=auto support
#   - Standard POSIX tools: make, tar, patch, sed

# Detect operating system
UNAME_S := $(shell uname -s)

# Compiler (can be overridden: make CXX=clang++)
CXX ?= g++

# Base optimization flags for maximum performance
CXXFLAGS := -std=c++17 -Wall -Wextra -DNDEBUG
CXXFLAGS += -O3 -march=native -mtune=native
CXXFLAGS += -flto -fomit-frame-pointer
CXXFLAGS += -funroll-loops -ffast-math

# Platform-specific flags
ifeq ($(UNAME_S),Darwin)
    # macOS
    LDFLAGS_CADICAL := -lpthread
    LDFLAGS_MINISAT := -lz
    # macOS may need different LTO flags
    CXXFLAGS += -flto=auto
else
    # Linux
    LDFLAGS_CADICAL := -lpthread
    LDFLAGS_MINISAT := -lm -lz
    CXXFLAGS += -flto=auto
endif

# Directories
SRC_DIR := app/IPASIRBones
IPASIR_DIR := ../ipasir
MINISAT_DIR := $(IPASIR_DIR)/sat/minisat220
CADICAL_ROOT := $(IPASIR_DIR)/sat/cadical
CADICAL_DIR := $(CADICAL_ROOT)/build

# Source files
SRC := $(SRC_DIR)/IPASIRBones.cpp

# Libraries
MINISAT_LIB := $(MINISAT_DIR)/libipasirminisat220.a
CADICAL_LIB := $(CADICAL_DIR)/libcadical.a

# Targets
TARGET_MINISAT := IPASIRBones_MiniSat
TARGET_CADICAL := IPASIRBones_CaDiCaL

# Include paths
INCLUDES := -I$(IPASIR_DIR)

# Default target: build both CaDiCaL and MiniSat versions
.PHONY: all clean cadical minisat solvers help

all: both

# Build both versions
both: cadical minisat

# Build CaDiCaL version
cadical: $(TARGET_CADICAL)

# Build MiniSat version
minisat: $(TARGET_MINISAT)

# Build the SAT solvers
solvers: solver-cadical solver-minisat

solver-cadical:
	@echo "Building CaDiCaL solver..."
	@if [ ! -f $(CADICAL_DIR)/makefile ]; then \
		echo "Configuring CaDiCaL..."; \
		cd $(CADICAL_ROOT) && ./configure; \
	fi
	$(MAKE) -C $(CADICAL_DIR)

solver-minisat:
	@echo "Building MiniSat solver..."
	$(MAKE) -C $(MINISAT_DIR) all

# Link IPASIRBones with CaDiCaL
$(TARGET_CADICAL): $(SRC) $(CADICAL_LIB)
	@echo "Building $(TARGET_CADICAL)..."
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ $< $(CADICAL_LIB) $(LDFLAGS_CADICAL)
	@echo "Built $(TARGET_CADICAL) successfully"

# Link IPASIRBones with MiniSat
$(TARGET_MINISAT): $(SRC) $(MINISAT_LIB)
	@echo "Building $(TARGET_MINISAT)..."
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ $< $(MINISAT_LIB) $(LDFLAGS_MINISAT)
	@echo "Built $(TARGET_MINISAT) successfully"

# Check if solver libraries exist, build them if not
$(CADICAL_LIB):
	@echo "CaDiCaL library not found, building..."
	$(MAKE) solver-cadical

$(MINISAT_LIB):
	@echo "MiniSat library not found, building..."
	$(MAKE) solver-minisat

# Clean targets
clean:
	@echo "Cleaning IPASIRBones binaries..."
	rm -f $(TARGET_MINISAT) $(TARGET_CADICAL)

clean-all: clean
	@echo "Cleaning SAT solver builds..."
	-$(MAKE) -C $(CADICAL_DIR) clean 2>/dev/null || true
	-$(MAKE) -C $(MINISAT_DIR) clean 2>/dev/null || true

# Help
help:
	@echo "IPASIRBones Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Build CaDiCaL version (default)"
	@echo "  both         - Build both CaDiCaL and MiniSat versions"
	@echo "  cadical      - Build IPASIRBones_CaDiCaL"
	@echo "  minisat      - Build IPASIRBones_MiniSat"
	@echo "  solvers      - Build both SAT solver libraries"
	@echo "  clean        - Remove IPASIRBones binaries"
	@echo "  clean-all    - Remove binaries and clean solver builds"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Detected OS: $(UNAME_S)"
