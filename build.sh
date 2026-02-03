#!/bin/bash
# Cross-platform build script for IPASIRBones
# Works on both Linux and macOS

set -e  # Exit on error

# Colors for output (if terminal supports it)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}IPASIRBones Build and Verification${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# Detect platform
OS=$(uname -s)
echo -e "${YELLOW}Detected OS:${NC} $OS"

# Detect architecture
ARCH=$(uname -m)
echo -e "${YELLOW}Architecture:${NC} $ARCH"

# Check compiler
if command -v g++ &> /dev/null; then
    GCC_VERSION=$(g++ --version | head -n1)
    echo -e "${YELLOW}GCC:${NC} $GCC_VERSION"
else
    echo -e "${RED}ERROR: g++ not found${NC}"
    exit 1
fi

if command -v clang++ &> /dev/null; then
    CLANG_VERSION=$(clang++ --version | head -n1)
    echo -e "${YELLOW}Clang:${NC} $CLANG_VERSION"
else
    echo -e "${YELLOW}Clang:${NC} Not found (optional)"
fi

echo

# Check required tools
echo -e "${BLUE}Checking required tools...${NC}"
MISSING_TOOLS=()

for tool in make tar patch sed; do
    if command -v $tool &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $tool"
    else
        echo -e "  ${RED}✗${NC} $tool (MISSING)"
        MISSING_TOOLS+=($tool)
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo -e "\n${RED}ERROR: Missing required tools: ${MISSING_TOOLS[*]}${NC}"
    exit 1
fi

echo

# Check for zlib (required for MiniSat)
echo -e "${BLUE}Checking for zlib library...${NC}"
if [ "$OS" = "Darwin" ]; then
    # On macOS, zlib is usually in system libraries
    if [ -f /usr/lib/libz.dylib ] || [ -f /usr/lib/libz.tbd ]; then
        echo -e "  ${GREEN}✓${NC} zlib found"
    else
        echo -e "  ${YELLOW}⚠${NC} zlib may not be installed"
    fi
else
    # On Linux, check for zlib.h
    if [ -f /usr/include/zlib.h ] || ldconfig -p 2>/dev/null | grep -q libz.so; then
        echo -e "  ${GREEN}✓${NC} zlib found"
    else
        echo -e "  ${RED}✗${NC} zlib-dev not found"
        echo -e "  Install with: ${YELLOW}sudo apt-get install zlib1g-dev${NC} (Ubuntu/Debian)"
        echo -e "            or: ${YELLOW}sudo dnf install zlib-devel${NC} (Fedora/RHEL)"
        exit 1
    fi
fi

echo

# Navigate to src directory
if [ ! -d "src" ]; then
    echo -e "${RED}ERROR: src directory not found. Run this script from the repository root.${NC}"
    exit 1
fi

cd src

# Clean previous builds
echo -e "${BLUE}Cleaning previous builds...${NC}"
make clean-all 2>/dev/null || true
echo -e "  ${GREEN}✓${NC} Clean completed"
echo

# Build solvers
echo -e "${BLUE}Building SAT solver libraries...${NC}"
echo -e "${YELLOW}This may take 2-5 minutes on first build...${NC}"
echo

if make solvers; then
    echo -e "\n  ${GREEN}✓${NC} SAT solvers built successfully"
else
    echo -e "\n  ${RED}✗${NC} SAT solver build failed"
    exit 1
fi

echo

# Build IPASIRBones
echo -e "${BLUE}Building IPASIRBones executables...${NC}"

# Build CaDiCaL version
echo -e "${YELLOW}Building CaDiCaL version...${NC}"
if make cadical; then
    echo -e "  ${GREEN}✓${NC} IPASIRBones_CaDiCaL built"
else
    echo -e "  ${RED}✗${NC} CaDiCaL version build failed"
    exit 1
fi

# Build MiniSat version
echo -e "${YELLOW}Building MiniSat version...${NC}"
if make minisat; then
    echo -e "  ${GREEN}✓${NC} IPASIRBones_MiniSat built"
else
    echo -e "  ${RED}✗${NC} MiniSat version build failed"
    exit 1
fi

echo

# Verify executables exist
echo -e "${BLUE}Verifying executables...${NC}"
if [ -f IPASIRBones_CaDiCaL ]; then
    SIZE_CADICAL=$(ls -lh IPASIRBones_CaDiCaL | awk '{print $5}')
    echo -e "  ${GREEN}✓${NC} IPASIRBones_CaDiCaL (${SIZE_CADICAL})"
else
    echo -e "  ${RED}✗${NC} IPASIRBones_CaDiCaL not found"
    exit 1
fi

if [ -f IPASIRBones_MiniSat ]; then
    SIZE_MINISAT=$(ls -lh IPASIRBones_MiniSat | awk '{print $5}')
    echo -e "  ${GREEN}✓${NC} IPASIRBones_MiniSat (${SIZE_MINISAT})"
else
    echo -e "  ${RED}✗${NC} IPASIRBones_MiniSat not found"
    exit 1
fi

echo

# Run basic tests if minibench exists
if [ -f minibench/perezmorago.dimacs ]; then
    echo -e "${BLUE}Running basic functionality tests...${NC}"

    # Test CaDiCaL with default algorithm
    echo -e "${YELLOW}Testing CaDiCaL (default algorithm)...${NC}"
    if ./IPASIRBones_CaDiCaL minibench/perezmorago.dimacs > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} CaDiCaL test passed"
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 10 ] || [ $EXIT_CODE -eq 20 ]; then
            echo -e "  ${GREEN}✓${NC} CaDiCaL test passed (exit code: $EXIT_CODE)"
        else
            echo -e "  ${RED}✗${NC} CaDiCaL test failed (exit code: $EXIT_CODE)"
            exit 1
        fi
    fi

    # Test MiniSat with algorithm 1
    echo -e "${YELLOW}Testing MiniSat (algorithm -s)...${NC}"
    if ./IPASIRBones_MiniSat minibench/perezmorago.dimacs -s > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} MiniSat test passed"
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 10 ] || [ $EXIT_CODE -eq 20 ]; then
            echo -e "  ${GREEN}✓${NC} MiniSat test passed (exit code: $EXIT_CODE)"
        else
            echo -e "  ${RED}✗${NC} MiniSat test failed (exit code: $EXIT_CODE)"
            exit 1
        fi
    fi

    # Test MiniSat with algorithm 2 and injection
    echo -e "${YELLOW}Testing MiniSat (algorithm -t -i)...${NC}"
    if ./IPASIRBones_MiniSat minibench/perezmorago.dimacs -t -i > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} MiniSat with injection test passed"
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 10 ] || [ $EXIT_CODE -eq 20 ]; then
            echo -e "  ${GREEN}✓${NC} MiniSat with injection test passed (exit code: $EXIT_CODE)"
        else
            echo -e "  ${RED}✗${NC} MiniSat with injection test failed (exit code: $EXIT_CODE)"
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}⚠ Test files not found, skipping functional tests${NC}"
fi

echo
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ All verifications passed!${NC}"
echo -e "${BLUE}========================================${NC}"
echo
echo -e "Built executables:"
echo -e "  ${YELLOW}./src/IPASIRBones_CaDiCaL${NC}"
echo -e "  ${YELLOW}./src/IPASIRBones_MiniSat${NC}"
echo
echo -e "Try running:"
echo -e "  ${YELLOW}./src/IPASIRBones_CaDiCaL ./src/minibench/toybox.dimacs${NC}"
echo -e "  ${YELLOW}./src/IPASIRBones_MiniSat ./src/minibench/toybox.dimacs -t -i${NC}"
echo
