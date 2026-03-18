# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HighTide is a benchmark suite of open-source hardware designs ported to asap7/sky130hd/nangate45 technologies using OpenROAD Flow Scripts (ORFS). It serves as a benchmark suite for ML projects in VLSI/EDA.

## Setup

```bash
./setup.sh          # Clone ORFS submodule, create symlinks (scripts/, platforms/, util/)
./runorfs.sh        # Launch Docker container with the matching ORFS version
```

## Build Commands

Designs are run via `./runorfs.sh` which wraps `make` inside the ORFS Docker container:

```bash
# Run full RTL-to-GDS flow for a design
./runorfs.sh make DESIGN_CONFIG=./designs/<platform>/<design>/config.mk

# Run with dev mode (regenerates Verilog from source repos)
./runorfs.sh make dev DESIGN_CONFIG=./designs/<platform>/<design>/config.mk

# Run individual ORFS stages
./runorfs.sh make synth DESIGN_CONFIG=...       # Synthesis only
./runorfs.sh make floorplan DESIGN_CONFIG=...   # Through floorplan
./runorfs.sh make place DESIGN_CONFIG=...       # Through placement
./runorfs.sh make cts DESIGN_CONFIG=...         # Through clock tree synthesis
./runorfs.sh make route DESIGN_CONFIG=...       # Through routing
./runorfs.sh make finish DESIGN_CONFIG=...      # Full flow

# Clean a design's dev artifacts
./runorfs.sh make clean_design DESIGN_CONFIG=...
```

Note: `runorfs.sh` uses `docker run -it` by default. For non-interactive/scripted use, use `runorfs_ni.sh` instead (identical but without `-it`). Always use `runorfs_ni.sh` when running builds from Claude Code or scripts.

Default design: `./designs/nangate45/lfsr_prbs_gen/config.mk`

## Architecture

### Directory Layout

- `designs/<platform>/<design>/config.mk` - Per-design, per-platform configuration (SDC, utilization, die area)
- `designs/src/<design>/` - Pre-generated Verilog and `verilog.mk` (included by config.mk)
- `designs/src/<design>/dev/` - Dev environment: source repo (submodule), setup.sh, generation scripts
- `settings.mk` - Global settings: `BENCH_DESIGN_HOME`, output directory overrides, `DEV_FLAG` path
- `OpenROAD-flow-scripts/` - ORFS submodule (provides flow Makefile, platforms, scripts)
- `Makefile` - Top-level: includes ORFS Makefile, adds `dev` target and incremental rebuild logic

### How Design Configs Work

Each `designs/<platform>/<design>/config.mk` sets `DESIGN_NAME`, `PLATFORM`, SDC path, and floorplan parameters, then includes `designs/src/<design>/verilog.mk` which sets `VERILOG_FILES`.

### Dev vs Release Mode

- **Release mode** (default): Uses pre-generated Verilog checked into `designs/src/<design>/`
- **Dev mode** (`make dev`): Creates a `.dev-run-*` flag file, triggers `verilog.mk` to regenerate RTL from the source repo in `designs/src/<design>/dev/`. Each design's `verilog.mk` checks for `DEV_FLAG` to decide which path to use.

### Platforms

- `asap7` - Arizona State Predictive 7nm PDK
- `nangate45` - NanGate 45nm Open Cell Library
- `sky130hd` - SkyWater 130nm High Density

### Current Designs

lfsr_prbs_gen, minimax, NyuziProcessor, cnn, liteeth (multiple variants), gemmini, floonoc, bp_processor

### Design Source Repos (submodules in `designs/src/<design>/dev/repo`)

Each design's dev repo is a git submodule. The `make dev` target auto-initializes it and runs the design's `setup.sh`, which preprocesses the source repo and places generated Verilog in `dev/generated/`. The `verilog.mk` files check for `DEV_FLAG` to decide whether to use the generated RTL or the pre-checked-in release Verilog.

### yosys-slang Frontend

Some designs (e.g., floonoc) use `SYNTH_HDL_FRONTEND = slang` in their `verilog.mk` to read SystemVerilog directly via the yosys-slang plugin, bypassing sv2v conversion. This is required for complex PULP Platform designs with advanced SV features. The ORFS Docker image includes a locally-built yosys with the slang plugin at `tools/install/yosys/bin/yosys`.

### FlooNoC Design Notes

- **Source**: PULP Platform FlooNoC (floo_noc) — AXI-based Network-on-Chip
- **Topology**: 4x4 narrow-wide mesh (16 cluster endpoints + 4 HBM), configurable via `mesh_config.yml`
- **Tools**: FlooGen (Python, generates mesh RTL from YAML), Bender (SV package manager)
- **Frontend**: yosys-slang (reads .sv directly, no sv2v needed)
- **setup.sh**: Downloads bender, fetches dependencies, runs floogen, outputs file lists (`files.txt`, `includes.txt`, `defines.txt`) for yosys-slang
- **Generated files**: `dev/generated/floo_floonoc_mesh_noc.sv` (top) + `_pkg.sv` (package), plus file lists pointing to bender-managed .sv dependencies

## Design Consistency Guidelines

- Maintain consistency across benchmark designs as much as possible:
  - Use the same `config.mk` structure: `DESIGN_NICKNAME`, `DESIGN_NAME`, `PLATFORM`, then design-specific SDC, utilization, density, die area
  - Use the same `verilog.mk` pattern: `DEV_DIR`, `DEV_FILES`, `DEV_SRC`, `SYNTH_HDL_FRONTEND`
  - File lists should use paths relative to the dev directory for Docker compatibility
  - SRAM macros: use ASAP7 fakeram macros from `$(PLATFORM_DIR)` when available, or design-specific macros when needed; reference via `ADDITIONAL_LEFS`/`ADDITIONAL_LIBS`

## Git Preferences

- Never include `Co-Authored-By` or any Claude/AI author attribution in commits
