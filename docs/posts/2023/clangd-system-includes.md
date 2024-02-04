---
date: 2023-12-20
categories:
  - programming
---

# Why doesn't clangd LSP find my compiler's system headers?

When using `clangd` as LSP for C/C++ projects, e.g. in nvim, it
enables all the nice convenience features we're used to from
heavyweight IDEs like VS Code, Eclipse etc.
Jump to definition, jump to references, autocompletion etc.

But sometimes, when using more complex compiler setups like multiple different
compilers installed in parallel, cross compilation etc., it can suddenly fail
to find standard includes like `<fstream>`, `<string>` (aka *system headers*),
making it completely useless. What's happening there?

<!-- more -->

## The problem

`clangd` must figure out the whole compilation environment - preprocessor symbols
(aka `#define`s), compiler flags, language version, include paths etc. - to interpret
the source code correctly *outside of the actual build*.
The standard way to achieve this is to make the build system (e.g. CMake) generate a
*compilation database*, a JSON file called `compile_commands.json`, which contains
the compiler call, including command line parameters, for each source file.

```cmake
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
```

When used as LSP in nvim, `clangd` is smart enough to find `compile_commands.json`
in the `build` subdirectory on its own. However, by default, CMake will only put
the *project-specific* include paths there, not the standard include paths
used implicitly by the compiler.
So `clangd` is forced to hallucinate these paths (a more polite word would be
[heuristics](https://clangd.llvm.org/guides/system-headers#heuristic-search-for-system-headers)).

This can work OK if we're lucky, but it can as well go wrong, leave include paths
missing or even pointing to the wrong places.

## The solution

Luckily, CMake has
[an option to export the standard directories](https://gitlab.kitware.com/cmake/cmake/-/issues/20912#note_795673)
implicitly used by the compiler. When this option is activated, the system include paths
will be exported as `-isystem` arguments to the compilation database:

```cmake
set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
```

Now `clangd` has explicit information about system include paths and won't need
to hallucinate them any more. 🎉
