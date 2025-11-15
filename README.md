
# asm-final

This is a repo for the final project of the course 組合語言與系統程式(CE2012).
Please read the following to properly setup the project.

**Also do notice that, despite the target is Win32(x86),
the project is mainly developed and tested on MacOS (M3/Apple Silicon)
with VMware Fusion running Windows on ARM.**
The emulation layer should get the job done, but please expect bug when running on native x64 platform.

[ToC]

## Requirements

The MASM32 environment is already built-in within the repo, so you don't need to install the MASM32 SDK separately.
In order to properly build and run, the following tools are required:

### Terminal emulators

In order to display true color, please use modern terminal that supports true color display, such as kitty and ghostty.

### Build Tool

- make: the main build tool for the project.

### Custom Fonts

Note: This is not required if you're not going to generate the font by yourself.

- uv: svg tiling
- bun: JavaScript runtimes for svgtofont

## Build & Run

To build the project, a simple `make` should do the job, you can configure the output file via `Makefile`.
To run the project, 'make run' is also available, which would also run `chcp 65001`,
this allows UTF-8 character to be properly displayed.
