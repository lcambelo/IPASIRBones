# IPASIRBones: High-Performance Backbone Extraction for SAT Formulas

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

**IPASIRBones** is a state-of-the-art research tool for extracting backbones from Boolean satisfiability (SAT) formulas using incremental SAT solving. A **backbone** is the set of literals that must have a fixed polarity (true or false) across all satisfying assignments of a formula.

## Algorithms

IPASIRBones implements two distinct backbone extraction algorithms:

### Algorithm 1: Naive Iterative (FlamaPy) `-s`
Tests each variable independently by assuming its negation and solving. If the formula becomes unsatisfiable, the literal is a backbone element. Simple but comprehensive.

### Algorithm 2: Advanced Iterative with Solution Filtering (FeatureIDE) `-t` (default)
Leverages the initial satisfying assignment to reduce the search space. Only tests candidates from the solution and filters out invalidated candidates after each iteration. Significantly faster on structured instances.

### Inject the backbone literals as they are discovered `-i`
IPASIRBones_MiniSat also includes the `-i` option (MiniSat only), which extends the algorithms by permanently adding discovered backbone literals as unit clauses to the formula. This guides the SAT solver to exploit learned backbones in subsequent iterations, further improving performance.

## Installation

### Prerequisites
- C++17 compatible compiler (GCC 7+ or Clang 5+)
- Make build system
- Git
- **Linux**: zlib development library (`zlib1g-dev` on Ubuntu/Debian, `zlib-devel` on Fedora/RHEL)
- **macOS**: Xcode Command Line Tools (`xcode-select --install`)

### Cross-Platform Support

IPASIRBones builds on both **Linux** and **macOS**. See [`BUILD_COMPATIBILITY.md`](BUILD_COMPATIBILITY.md) for detailed platform-specific instructions.

### Quick Start

```bash
# Clone the repository
git clone https://github.com/lcambelo/IPASIRBones.git
cd IPASIRBones

# Build IPASIRBones
./build.sh
```

## Usage

After building, two executables will be available in the `src/` directory:

- **`IPASIRBones_CaDiCaL`** - Uses CaDiCaL SAT solver (modern CDCL solver, v2.1.3)
- **`IPASIRBones_MiniSat`** - Uses MiniSat SAT solver (classic solver, v2.2.0)

### Command-Line Syntax

#### CaDiCaL Version

```bash
./IPASIRBones_CaDiCaL <file.dimacs> [options]

Options:
  -s  Algorithm 1: Naive Iterative (FlamaPy)
  -t  Algorithm 2: Advanced Iterative with solution filtering (FeatureIDE) [default]
```

If no algorithm is specified, `-t` (Advanced) is used by default.

#### MiniSat Version

```bash
./IPASIRBones_MiniSat <file.dimacs> [options]

Options:
  -s  Algorithm 1: Naive Iterative (FlamaPy)
  -t  Algorithm 2: Advanced Iterative with solution filtering (FeatureIDE) [default]
  -i  Algorithm 3: Add backbone literals as unit clauses (works with -s or -t)
```

**Note**: The `-i` option (unit clause injection) is only available for MiniSat.

### Examples

```bash
# Run Advanced algorithm with CaDiCaL (fastest for most instances)
./IPASIRBones_CaDiCaL minibench/toybox.dimacs

# Run Naive algorithm with CaDiCaL
./IPASIRBones_CaDiCaL minibench/toybox.dimacs -s

# Run Advanced algorithm with MiniSat
./IPASIRBones_MiniSat minibench/toybox.dimacs -t

# Run Advanced algorithm with unit clause injection (MiniSat only)
./IPASIRBones_MiniSat minibench/toybox.dimacs -t -i

# Run Naive algorithm with unit clause injection (MiniSat only)
./IPASIRBones_MiniSat minibench/toybox.dimacs -s -i
```

### Input Format

IPASIRBones accepts **DIMACS CNF** format files (`.dimacs` or `.cnf` extensions). Sample benchmark files are provided in `src/minibench/`:

- `perezmorago.dimacs` - Small test instance
- `toybox.dimacs` - Medium-sized feature model
- `fiasco.dimacs` - Large real-world feature model

### Output Format

```
c Algorithm 2: Advanced Iterative with solution filtering (FeatureIDE)
v 1 -2 -3 4
c Backbone count: 4
```

- Lines starting with `c` are comments
- Lines starting with `v` contain backbone literals (positive = true, negative = false)

## Repository Structure

```
IPASIRBones/
├── README.md                    # This file
├── build.sh                     # Build IPASIR
├── assets/
│   └── SATBackboneLogo.png     # Logo
├── ipasir/                      # IPASIR incremental SAT interface
│   ├── ipasir.h                # IPASIR C API
│   └── sat/
│       ├── cadical/            # CaDiCaL solver v2.1.3
│       └── minisat220/         # MiniSat solver v2.2.0
└── src/
    ├── Makefile                # Build system (called from ./build.sh)
    ├── app/IPASIRBones/
    │   └── IPASIRBones.cpp     # Main backbone extraction engine
    └── minibench/              # Sample DIMACS test files
        ├── perezmorago.dimacs
        ├── toybox.dimacs
        └── fiasco.dimacs
```

## Technical Details

### IPASIR Interface

IPASIRBones uses the [IPASIR](https://github.com/biotomas/ipasir) standard interface for incremental SAT solving. This allows the same codebase to work with different SAT solvers by simply linking against different libraries.

Key IPASIR functions used:
- `ipasir_init()` - Initialize solver instance
- `ipasir_add()` - Add clause literals
- `ipasir_assume()` - Add temporary assumption for incremental solving
- `ipasir_solve()` - Solve under current assumptions
- `ipasir_val()` - Retrieve variable assignment from satisfying model

### SAT Solver Backends

**CaDiCaL** (v2.1.3)
- Modern Conflict-Driven Clause Learning (CDCL) solver
- State-of-the-art preprocessing and inprocessing
- Excellent performance on structured industrial instances
- Winner of multiple SAT Competition tracks

**MiniSat** (v2.2.0)
- Classic, well-studied CDCL solver
- Clean, readable implementation
- Stable and widely used in research
- Supports unit clause injection optimization

## License

IPASIRBones is released under the **MIT License**, allowing free use in both academic and commercial settings.

This project builds upon:
- **MiniSat**: MIT License
- **CaDiCaL**: MIT License
- **IPASIR**: MIT License

See individual solver directories for their respective licenses.

## Authors

This work is the result of collaborative research by:

- **Luis Cambelo** - Universidad Nacional de Educación a Distancia (UNED), Spain
- **Rubén Heradio** - Universidad Nacional de Educación a Distancia (UNED), Spain
- **José Miguel Horcas** - Universidad de Málaga, Spain
- **Dictino Chaos** - Universidad Nacional de Educación a Distancia (UNED), Spain
- **David Fernández-Amorós** - Universidad Nacional de Educación a Distancia (UNED), Spain

### Related Publication

This repository contains the implementation described in:

> ***A Comparative Analysis of Backbone Algorithms for Configurable Software Systems***
> Luis Cambelo, Rubén Heradio, José M. Horcas, Dictino Chaos, David Fernández-Amorós
> *Software & Systems Modeling (SoSyM)*, 2026

## Contact

For questions or collaboration inquiries, please contact:
- Luis Cambelo: lcambelo1@alumno.uned.es
- Rubén Heradio: rheradio@issi.uned.es

## Acknowledgments

This work is funded by FEDER/Spanish Ministry of Science, Innovation and Universities (MCIN)/Agencia Estatal de Investigacion (AEI) under grant COSY (PID2022-142043NB-I00). 

We thank the developers of CaDiCaL, MiniSat, and IPASIR for their excellent tools that made this research possible.
