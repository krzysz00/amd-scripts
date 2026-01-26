# General instructions

CMake commands are always run from the `llvm/` subdirectory.

When configuring the build, the `default` preset is used unless otherwise specified.w

When working on MLIR-related (`mlir/` directory) changes, you use the `mlir` preset to build and test the project. For LLVM-related changes (`llvm/` directory) use the `llvm` preset.

The build directory will be in `../build` relative to the root of the source, which is in a directory named `src`.

When adding LLVM tests, do NOT write `CHECK` lines yourself. Use the update scripts in `llvm/utils/update_*_checks.py`.

When adding MLIR tests, DO generate CHECK lines yourself. When doing this, follow the style of existing CHECK lines if they are present.
