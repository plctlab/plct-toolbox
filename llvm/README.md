# LLVM

## Usage of build_llvm.py

### Configuration file

A sample configuration file is placed under this folder.

```js
{
    // The path to the llvm project.
    "llvm_project_path": "/home/PLCT/llvm-project",
    // We can have multiple tasks here.
    // The task we need can be identified by build_llvm.py <command>.
    "tasks": [
        // If we want to run this task: $ build_llvm.py cx86.
        {
            // The label shown when executing.
            "label": "Configure X86",
            // The command used to identify the task.
            // No space is allowed in the command.
            "command": "cx86",
            // Two types: configure or build.
            // For test: user the build type.
            "type": "configure",
            // Can be omitted. Default Ninja.
            "generator": "Ninja",
            // Target build dir name.
            "target_dir": "build",
            // Variables passed to cmake.
            // https://llvm.org/docs/CMake.html
            "vars": {
                "CMAKE_BUILD_TYPE": "Debug",
                "CMAKE_C_COMPILER": "/usr/bin/clang",
                "CMAKE_CXX_COMPILER": "/usr/bin/clang++",
                "LLVM_ENABLE_PROJECTS": [
                    "clang",
                    "compiler-rt"
                ],
                "LLVM_TARGETS_TO_BUILD": [
                    "X86",
                    "RISCV"
                ],
                "LLVM_USE_LINKER": "lld",
                // Recommended value: free --giga | grep Mem | awk '{print int($2 / 8)}'
                // if the following optimizations are applied.
                "LLVM_PARALLEL_LINK_JOBS": 1,
                // Avoid the unneccessary linking after git pull.
                "LLVM_APPEND_VC_REV": "OFF",
                // Set this to ON to improve the linking speed and reduce the binary size.
                // However, the test will be slower.
                "BUILD_SHARED_LIBS": "ON",
                // Consider setting this to ON if you require a debug build, as this will ease memory pressure on the linker.
                // This will make linking much faster, as the binaries will not contain any of the debug information.
                // however, this will generate the debug information in the form of a DWARF object file. 
                // This only applies to host platforms using ELF, such as Linux.
                // This is not supported when cross-compiling from x86_64 to RISC-V.
                "LLVM_USE_SPLIT_DWARF": "ON"
            }
        },
        {
            "label": "Build X86",
            "command": "bx86",
            "type": "build",
            "target_dir": "build",
            // We can specify the targets in an array
            // For example: ["llc", "opt", "clang", "check-llvm-transforms"]
            "targets": "all"
        }
    ]
}
```

Note: a standard json file should not contain any comments.

### Usage

We can put the python program and the configuration file to the system path.

Or we can simply modify our .*shrc file to create a function to call the python program.

Note: The program and the configuration file build_llvm.json should be placed under the same folder.

```sh
# configure
$ build_llvm.py cx86
# build
$ build_llvm.py bx86
# test
$ build_llvm.py tx86
```

### Cross compiling from x86_64 to RISC-V

#### Steps

At the time of writing, we need to download the gnu toolchain to support the cross-compiling.

We can first compile the [gnu toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain), and install it to a clean folder. It means that it can be a trouble if we install it to `/`, `/usr`, `/usr/local`, as cmake may find the wrong library.

And then, look into the build_llvm.json.

#### Troubleshooting

1.  If you’re using Clang as the cross-compiler, relocation R_RISCV_TPREL_HI20 against `a local symbol` can not be used when making a shared object, so for now, you should enable PIC:

    ```
    "LLVM_ENABLE_PIC": "ON"
    ```

2.  For the flags used in C, CXX, ASM:

    ```
    "CMAKE_*_FLAGS": "--target=riscv64-unknown-linux-gnu --gcc-toolchain=/home/PLCT/riscv --sysroot=/home/PLCT/riscv/sysroot -march=rv64ifd"
    ```

    We may get:

    ```
    undefined references to `__atomic_*'
    clang-13: error: linker command failed with exit code 1 (use -v to see invocation)
    ```

    At the time of writing, it is an issue that, cmake cannot determine whether to link it with libatomic.

    Add CMake variables:

    ```
    "CMAKE_EXE_LINKER_FLAGS": "-latomic",
    "CMAKE_SHARED_LINKER_FLAGS": "-latomic"
    ```

    for temporary measure.

#### Note

`CMAKE_CROSSCOMPILING` is always set automatically when `CMAKE_SYSTEM_NAME` is set. Don't put `"CMAKE_CROSSCOMPILING"="TRUE"` in your options.
