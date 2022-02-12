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
                "LLVM_PARALLEL_LINK_JOBS": 1,
                // Avoid the unneccessary linking after git pull.
                "LLVM_APPEND_VC_REV": "OFF",
                // Set this to ON to improve the linking speed.
                // However, the test will be slower.
                "BUILD_SHARED_LIBS": "OFF"
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

### Cross compiling from x86_64 to RISC-V

#### Steps

At the time of writing, we need to download the gnu toolchain to support the cross-compiling.

We can first compile the [gnu toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain), and install it to a clean folder. It means that it can be a trouble if we install it to `/`, `/usr`, `/usr/local`, as cmake may find the wrong library.

And then, look into the build_llvm.json.

#### Troubleshooting

For the flags used in C, CXX, ASM:

```
"CMAKE_*_FLAGS": "--target=riscv64-unknown-linux-gnu --gcc-toolchain=/home/PLCT/riscv --sysroot=/home/PLCT/riscv/sysroot -march=rv64ifd"
```

We may get:

```
undefined references to `__atomic_*'
clang-13: error: linker command failed with exit code 1 (use -v to see invocation)
```

At the time of writing, it is an issue that, cmake cannot determine whether to link it with libatomic.

Use

```
"CMAKE_*_FLAGS": "--target=riscv64-unknown-linux-gnu --gcc-toolchain=/home/PLCT/riscv --sysroot=/home/PLCT/riscv/sysroot -march=rv64ifd -latomic"
```

for temporary measure.

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
