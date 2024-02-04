---
date: 2024-02-01
categories:
  - linux
  - programming
---

# Why clang-format suddenly breaks under nvim

TL;DR: `clang-format` became stricter with recent versions; `.clang-format` files with duplicate keys used to work but now they silently fail.

<!-- more -->

## The problem

I use `nvim` with [`kickstart.nvim`](https://github.com/patrislav1/kickstart.nvim) configuration and [format on save](https://github.com/patrislav1/kickstart.nvim/blob/master/lua/kickstart/plugins/autoformat.lua) activated,
which runs the language server formatter on each save, via `vim.lsp.buf.format()`.

For C/C++ projects I use `clangd` LSP and every project has a `.clang-format` configuration in the project root. 

After some upgrade (I don't recall if it was an upgrade of [Mason](https://github.com/williamboman/mason.nvim),
`clangd`, or nvim itself), the formatting in some C/C++ projects suddenly broke. The code was still auto-formatted,
but it was *formatted wrong* - such as indentation with 2 spaces, when `.clang-format` was configured to 4 spaces, etc.

## Debugging

First let's check if the problem persists when calling `clang-format` directly, or if it's limited to inside nvim.

```bash
$ clang-format -i src/foo.c
```

OK - when called directly, `clang-format` will respect `.clang-format` and apply the correct formatting. So what's different when it runs inside nvim?

### `vim.lsp.buf.format()`

When formatting via LSP, nvim doesn't actually call `clang-format` but runs the LSP (`clangd` in this case) and sends a format command via RPC.
`clangd` integrates the `clang-format` functionality for this.

But since it's managed by Mason, maybe the `clangd` used by nvim is a whole other version than the system-wide one?

```bash
$ clangd --version
clangd version 10.0.0-4ubuntu1 
$ find ~/.* -name "clangd"
/home/huesmann/.local/share/nvim/mason/bin/clangd
/home/huesmann/.local/share/nvim/mason/packages/clangd
/home/huesmann/.local/share/nvim/mason/packages/clangd/clangd_17.0.3/bin/clangd
```

OK - the version used by nvim is seven major versions more recent than the system-wide one 🙃

Maybe it *doesn't like* something about the `.clang-format` that the older version had no problem with? 🤔

Let's enable LSP trace logging:
```lua
vim.lsp.set_log_level("trace")
```

Now there's interesting stuff in the LSP log file `~/.local/state/nvim/lsp.log`.
The file is difficult to read - it shows a wall of text, including the escaped error messages from the LSP as raw strings received through the RPC protocol.
When removing the uninteresting bits to make it more readable, the interesting stuff that remains reads like:

```
... error: duplicated mapping key 'AllowAllParametersOfDeclarationOnNextLine'\nAllowAllParametersOfDeclarationOnNextLine: false
... getStyle() failed for file .../src/foo.c: Error reading .../.clang-format: Invalid argument. Fallback is LLVM style.
... error: duplicated mapping key 'AllowAllParametersOfDeclarationOnNextLine'\nAllowAllParametersOfDeclarationOnNextLine: false
... Couldn't infer style
```

So now it's clear what's happening:

There's multiple instances of the same key (`AllowAllParametersOfDeclarationOnNextLine` in this case) in `.clang-format`.
Previous versions of `clang-format` silently ignored this, but the recent version included in 
`clangd` used by nvim doesn't tolerate it any more. The funny part is:
Instead of raising an error and aborting the format request, it *falls back to a default style*
and just formats the code with those default settings.

After removing the redundant, second instance of `AllowAllParametersOfDeclarationOnNextLine`,
the issue goes away and code formatting works again as expected 👍

## Conclusion

* Current `clang-format` / `clangd` cannot handle multiple instances of same key in `.clang-format`
* When it can't parse `.clang-format` it will fall back to LLVM style
* nvim will not raise that error to the user, but just silently keep that "default-style" formatting

I think it's a bit unfortunate that such errors stay hidden until someone bothers to look at the log file.
Not sure if nvim forgot to implement it or it's a lack of the LSP protocol. (Or maybe just a config option that I didn't set...?)
