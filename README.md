<div align="center">
<sup>Special thanks to:</sup>
<br>
<br>
<a href="https://warp.dev/?utm_source=github&utm_medium=referral&utm_campaign=vimplug_20240209">
  <div>
    <img src="https://raw.githubusercontent.com/junegunn/i/master/warp.png" width="300" alt="Warp">
  </div>
  <b>Warp is a modern, Rust-based terminal with AI built in so you and your team can build great software, faster.</b>
  <div>
    <sup>Visit warp.dev to learn more.</sup>
  </div>
</a>
<br>
<hr>
</div>
<br>

<h1 title="vim-plug">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="./plug-dark.png">
    <img src="./plug.png" height="75" alt="vim-plug">
  </picture>
  <a href="https://github.com/junegunn/vim-plug/actions/workflows/test.yml?query=branch%3Amaster">
    <img src="https://img.shields.io/github/actions/workflow/status/junegunn/vim-plug/test.yml?branch=master">
  </a>
</h1>

A minimalist Vim plugin manager.

<img src="https://raw.githubusercontent.com/junegunn/i/master/vim-plug/installer.gif" height="450">

### Pros.

- Easy to set up: Single file. No boilerplate code required.
- Easy to use: Concise, intuitive syntax
- [Super-fast][40/4] parallel installation/update
  (with any of `+job`, `+python`, `+python3`, `+ruby`, or [Neovim][nv])
- Creates shallow clones to minimize disk space usage and download time
- On-demand loading for [faster startup time][startup-time]
- Can review and rollback updates
- Branch/tag/commit support
- Post-update hooks
- Support for externally managed plugins

[40/4]: https://raw.githubusercontent.com/junegunn/i/master/vim-plug/40-in-4.gif
[nv]: http://neovim.org/
[startup-time]: https://github.com/junegunn/vim-startuptime-benchmark#result

### Installation

[Download plug.vim](https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim)
and put it in the "autoload" directory.

#### Vim

###### Unix

```sh
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

You can automate the process by putting the command in your Vim configuration
file as suggested [here][auto].

[auto]: https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation

###### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim |`
    ni $HOME/vimfiles/autoload/plug.vim -Force
```

#### Neovim

###### Unix, Linux

```sh
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```

###### Linux (Flatpak)

```sh
curl -fLo ~/.var/app/io.neovim.nvim/data/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

###### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim |`
    ni "$(@($env:XDG_DATA_HOME, $env:LOCALAPPDATA)[$null -eq $env:XDG_DATA_HOME])/nvim-data/site/autoload/plug.vim" -Force
```

### Getting Help

- See [tutorial] page to learn the basics of vim-plug
- See [tips] and [FAQ] pages for common problems and questions
- See [requirements] page for debugging information & tested configurations
- Create an [issue](https://github.com/junegunn/vim-plug/issues/new)

[tutorial]: https://github.com/junegunn/vim-plug/wiki/tutorial
[tips]: https://github.com/junegunn/vim-plug/wiki/tips
[FAQ]: https://github.com/junegunn/vim-plug/wiki/faq
[requirements]: https://github.com/junegunn/vim-plug/wiki/requirements

### Usage

Add a vim-plug section to your `~/.vimrc` (or `stdpath('config') . '/init.vim'` for Neovim)

1. Begin the section with `call plug#begin([PLUGIN_DIR])`
1. List the plugins with `Plug` commands
1. `call plug#end()` to update `&runtimepath` and initialize plugin system
    - Automatically executes `filetype plugin indent on` and `syntax enable`.
      You can revert the settings after the call. e.g. `filetype indent off`, `syntax off`, etc.
1. Reload the file or restart Vim and run `:PlugInstall` to install plugins.

#### Example

```vim
call plug#begin()
" The default plugin directory will be as follows:
"   - Vim (Linux/macOS): '~/.vim/plugged'
"   - Vim (Windows): '~/vimfiles/plugged'
"   - Neovim (Linux/macOS/Windows): stdpath('data') . '/plugged'
" You can specify a custom plugin directory by passing it as the argument
"   - e.g. `call plug#begin('~/.vim/plugged')`
"   - Avoid using standard Vim directory names like 'plugin'

" Make sure you use single quotes

" Shorthand notation for GitHub; translates to https://github.com/junegunn/vim-easy-align
Plug 'junegunn/vim-easy-align'

" Any valid git URL is allowed
Plug 'https://github.com/junegunn/seoul256.vim.git'

" Using a tagged release; wildcard allowed (requires git 1.9.2 or above)
Plug 'fatih/vim-go', { 'tag': '*' }

" Using a non-default branch
Plug 'neoclide/coc.nvim', { 'branch': 'release' }

" Use 'dir' option to install plugin in a non-default directory
Plug 'junegunn/fzf', { 'dir': '~/.fzf' }

" Post-update hook: run a shell command after installing or updating the plugin
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" Post-update hook can be a lambda expression
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }

" If the vim plugin is in a subdirectory, use 'rtp' option to specify its path
Plug 'nsf/gocode', { 'rtp': 'vim' }

" On-demand loading: loaded when the specified command is executed
Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }

" On-demand loading: loaded when a file with a specific file type is opened
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }

" Unmanaged plugin (manually installed and updated)
Plug '~/my-prototype-plugin'

" Initialize plugin system
" - Automatically executes `filetype plugin indent on` and `syntax enable`.
call plug#end()
" You can revert the settings after the call like so:
"   filetype indent off   " Disable file-type-specific indentation
"   syntax off            " Disable syntax highlighting
```

#### Example (Lua configuration for Neovim)

In Neovim, you can write your configuration in a Lua script file named
`init.lua`. The following code is the Lua script equivalent to the VimScript
example above.

```lua
local vim = vim
local Plug = vim.fn['plug#']

vim.call('plug#begin')

-- Shorthand notation for GitHub; translates to https://github.com/junegunn/vim-easy-align
Plug('junegunn/vim-easy-align')

-- Any valid git URL is allowed
Plug('https://github.com/junegunn/seoul256.vim.git')

-- Using a tagged release; wildcard allowed (requires git 1.9.2 or above)
Plug('fatih/vim-go', { ['tag'] = '*' })

-- Using a non-default branch
Plug('neoclide/coc.nvim', { ['branch'] = 'release' })

-- Use 'dir' option to install plugin in a non-default directory
Plug('junegunn/fzf', { ['dir'] = '~/.fzf' })

-- Post-update hook: run a shell command after installing or updating the plugin
Plug('junegunn/fzf', { ['dir'] = '~/.fzf', ['do'] = './install --all' })

-- Post-update hook can be a lambda expression
Plug('junegunn/fzf', { ['do'] = function()
  vim.fn['fzf#install']()
end })

-- If the vim plugin is in a subdirectory, use 'rtp' option to specify its path
Plug('nsf/gocode', { ['rtp'] = 'vim' })

-- On-demand loading: loaded when the specified command is executed
Plug('preservim/nerdtree', { ['on'] = 'NERDTreeToggle' })

-- On-demand loading: loaded when a file with a specific file type is opened
Plug('tpope/vim-fireplace', { ['for'] = 'clojure' })

-- Unmanaged plugin (manually installed and updated)
Plug('~/my-prototype-plugin')

vim.call('plug#end')
```

More examples can be found in:

* https://gitlab.com/sultanahamer/dotfiles/-/blob/master/nvim/lua/plugins.lua?ref_type=heads

### Commands

| Command                             | Description                                                        |
| ----------------------------------- | ------------------------------------------------------------------ |
| `PlugInstall [name ...] [#threads]` | Install plugins                                                    |
| `PlugUpdate [name ...] [#threads]`  | Install or update plugins                                          |
| `PlugClean[!]`                      | Remove unlisted plugins (bang version will clean without prompt) |
| `PlugUpgrade`                       | Upgrade vim-plug itself                                            |
| `PlugStatus`                        | Check the status of plugins                                        |
| `PlugDiff`                          | Examine changes from the previous update and the pending changes   |
| `PlugSnapshot[!] [output path]`     | Generate script for restoring the current snapshot of the plugins  |

### `Plug` options

| Option                  | Description                                      |
| ----------------------- | ------------------------------------------------ |
| `branch`/`tag`/`commit` | Branch/tag/commit of the repository to use       |
| `rtp`                   | Subdirectory that contains Vim plugin            |
| `dir`                   | Custom directory for the plugin                  |
| `as`                    | Use different name for the plugin                |
| `do`                    | Post-update hook (string or funcref)             |
| `on`                    | On-demand loading: Commands or `<Plug>`-mappings |
| `for`                   | On-demand loading: File types                    |
| `frozen`                | Do not update unless explicitly specified        |

### Global options

| Flag                | Default                           | Description                                            |
| ------------------- | --------------------------------- | ------------------------------------------------------ |
| `g:plug_threads`    | 16                                | Default number of threads to use                       |
| `g:plug_timeout`    | 60                                | Time limit of each task in seconds (*Ruby & Python*)   |
| `g:plug_retries`    | 2                                 | Number of retries in case of timeout (*Ruby & Python*) |
| `g:plug_shallow`    | 1                                 | Use shallow clone                                      |
| `g:plug_window`     | `-tabnew`                         | Command to open plug window                            |
| `g:plug_pwindow`    | `vertical rightbelow new`         | Command to open preview window in `PlugDiff`           |
| `g:plug_url_format` | `https://git::@github.com/%s.git` | `printf` format to build repo URL (Only applies to the subsequent `Plug` commands) |


### Keybindings

- `D` - `PlugDiff`
- `S` - `PlugStatus`
- `R` - Retry failed update or installation tasks
- `U` - Update plugins in the selected range
- `q` - Close the window
- `:PlugStatus`
    - `L` - Load plugin
- `:PlugDiff`
    - `X` - Revert the update

### Example: A small [sensible](https://github.com/tpope/vim-sensible) Vim configuration

```vim
call plug#begin()
Plug 'tpope/vim-sensible'
call plug#end()
```

### On-demand loading of plugins

```vim
" NERD tree will be loaded on the first invocation of NERDTreeToggle command
Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }

" Multiple commands
Plug 'junegunn/vim-github-dashboard', { 'on': ['GHDashboard', 'GHActivity'] }

" Loaded when clojure file is opened
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }

" Multiple file types
Plug 'kovisoft/paredit', { 'for': ['clojure', 'scheme'] }

" On-demand loading on both conditions
Plug 'junegunn/vader.vim',  { 'on': 'Vader', 'for': 'vader' }

" Code to execute when the plugin is lazily loaded on demand
Plug 'junegunn/goyo.vim', { 'for': 'markdown' }
autocmd! User goyo.vim echom 'Goyo is now loaded!'
```

> [!NOTE]
> #### Should I set up on-demand loading?
>
> You probably don't need to.
>
> A properly implemented Vim plugin should already load lazily without any
> help from a plugin manager (`:help autoload`). So there are few cases where
> these options actually make much sense. Making a plugin load faster is
> the responsibility of the plugin developer, not the user. If you find
> a plugin that takes too long to load, consider opening an issue on the
> plugin's issue tracker.
>
> Let me give you a perspective. The time it takes to load a plugin is usually
> less than 2 or 3ms on modern computers. So unless you use a very large
> number of plugins, you are unlikely to save more than 50ms. If you have
> spent an hour carefully setting up the options to shave off 50ms, you
> will have to start Vim 72,000 times just to break even. You should ask
> yourself if that's a good investment of your time.
>
> Make sure that you're tackling the right problem by breaking down the
> startup of time of Vim using `--startuptime`.
>
> ```sh
> vim --startuptime /tmp/log
> ```
>
> On-demand loading should only be used as a last resort. It is basically
> a hacky workaround and is not always guaranteed to work.

> [!TIP]
> You can pass an empty list to `on` or `for` option to disable the loading
> of the plugin. You can manually load the plugin using `plug#load(NAMES...)`
> function.
>
> See https://github.com/junegunn/vim-plug/wiki/tips#loading-plugins-manually


### Post-update hooks

There are some plugins that require extra steps after installation or update.
In that case, use the `do` option to describe the task to be performed.

```vim
Plug 'Shougo/vimproc.vim', { 'do': 'make' }
Plug 'ycm-core/YouCompleteMe', { 'do': './install.py' }
```

If the value starts with `:`, it will be recognized as a Vim command.

```vim
Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' }
```

To call a Vim function, you can pass a lambda expression like so:

```vim
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
```

If you need more control, you can pass a reference to a Vim function that
takes a dictionary argument.

```vim
function! BuildYCM(info)
  " info is a dictionary with 3 fields
  " - name:   name of the plugin
  " - status: 'installed', 'updated', or 'unchanged'
  " - force:  set on PlugInstall! or PlugUpdate!
  if a:info.status == 'installed' || a:info.force
    !./install.py
  endif
endfunction

Plug 'ycm-core/YouCompleteMe', { 'do': function('BuildYCM') }
```

A post-update hook is executed inside the directory of the plugin and only run
when the repository has changed, but you can force it to run unconditionally
with the bang-versions of the commands: `PlugInstall!` and `PlugUpdate!`.

> [!TIP]
> Make sure to escape BARs and double-quotes when you write the `do` option
> inline as they are mistakenly recognized as command separator or the start of
> the trailing comment.
>
> ```vim
> Plug 'junegunn/fzf', { 'do': 'yes \| ./install' }
> ```
>
> But you can avoid the escaping if you extract the inline specification using a
> variable (or any Vimscript expression) as follows:
>
> ```vim
> let g:fzf_install = 'yes | ./install'
> Plug 'junegunn/fzf', { 'do': g:fzf_install }
> ```

### `PlugInstall!` and `PlugUpdate!`

The installer takes the following steps when installing/updating a plugin:

1. `git clone` or `git fetch` from its origin
2. Check out branch, tag, or commit and optionally `git merge` remote branch
3. If the plugin was updated (or installed for the first time)
    1. Update submodules
    2. Execute post-update hooks

The commands with the `!` suffix ensure that all steps are run unconditionally.

### Collaborators

- [Jan Edmund Lazo](https://github.com/janlazo) - Windows support
- [Jeremy Pallats](https://github.com/starcraftman) - Python installer

### License

MIT
