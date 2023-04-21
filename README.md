# pensieve.nvim

[Pensieve] implements a markdown-based diary using Neovim. Strong file-based
encryption is optionally supported through [gocryptfs], enabling incremental sync to cloud providers.

## Installation

Install and load the plugin, for example via [vim-plug]:

```
Plug 'LokiLuciferase/pensieve.nvim'
```

Make sure to add a call to the `setup` function with the proper configuration in your `init` file.
See the [help] for available configuration options.

If you use `init.vim`:

```
lua require('pensieve').setup {default_encryption = 'plaintext'}
```
Or, if you use `init.lua`:

```
require('pensieve').setup {default_encryption = 'plaintext'}
```

## Usage
```
:PensieveInit <repo>
```
Initializes a new diary repo at the passed path. Fails if the path points to a non-empty directory.

```
:PensieveOpen <repo>
```
Opens the diary repo at path `repo`. Unless any files are edited in the repo, it will automatically close after `options.encryption_timeout`. The repo will also close upon closing of Neovim.

```
:PensieveClose
```
Explicitly closes the currently open repo. For encrypted repos, this will make any files in the repo inaccessible until calling `:PensieveOpen` once again.

```
:PensieveEdit [datestring]
```
Opens a diary page from the currently open repo for editing - per default, today's entry. By passing either a date string like `2023-04-20` or a day offset like `t-3`, entries of other days can be edited. In case the entry for the given day does not yet exist, it is created from a markdown template.

```
:PensieveAttach <glob> [datestring]
```
Copies files and directories matching `glob` (e.g., `./*.png`) to a subdirectory `attachments/`
of the diary entry for the given date (per default, today).

```
:Pensieve <repo> [datestring]
```
Convenience method to open a repo and immediately edit a diary page.

[Pensieve]: https://www.hp-lexicon.org/thing/pensieve/
[vim-plug]: https://github.com/junegunn/vim-plug
[gocryptfs]: https://www.github.com/rfjakob/gocryptfs
[integration-badge]: https://github.com/LokiLuciferase/pensieve.nvim/actions/workflows/integration.yml/badge.svg
[integration-runs]: https://github.com/LokiLuciferase/pensieve.nvim/actions/workflows/integration.yml
[help]: doc/pensieve.txt
