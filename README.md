<img src="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.png" height="75" alt="vim-plug">[![travis-ci](https://travis-ci.org/junegunn/vim-plug.svg?branch=master)](https://travis-ci.org/junegunn/vim-plug)
===

A minimalist Vim plugin manager.

<img src="https://raw.githubusercontent.com/junegunn/i/master/vim-plug/installer.gif" height="450">

### Pros.

- Easier to setup: Single file. No boilerplate code required.
- Easier to use: Concise, intuitive syntax
- [Super-fast][40/4] parallel installation/update
  (with any of `+python`, `+python3`, `+ruby`, or [Neovim][nv])
- Creates shallow clones to minimize disk space usage and download time
- On-demand loading for [faster startup time][startup-time]
- Can review and rollback updates
- Branch/tag/commit support
- Post-update hooks
- Support for externally managed plugins

[40/4]: https://raw.githubusercontent.com/junegunn/i/master/vim-plug/40-in-4.gif
[nv]: http://neovim.org/
[startup-time]: http://junegunn.kr/images/vim-startup-time.png

### Installation

[Download plug.vim](https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim)
and put it in the "autoload" directory.

###### Unix

```sh
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

###### Neovim

```sh
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

###### Windows

```powershell
md ~\vimfiles\autoload

$uri = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
(New-Object Net.WebClient).DownloadFile($uri, (Resolve-Path ~\vimfiles\autoload\plug.vim))
```

###### Git
```
git clone 'https://github.com/frtmelody/vim-plug.git' '~/.vim/plugged/vim-plug'
```

### Usage

Add a vim-plug section to your .vimrc:

1. Begin the section with `plug#begin()`
1. List the plugins with `Plug` commands
1. `plug#end()` to add the plugins to `&runtimepath`

#### Example

```vim
set rtp+= ~/.vim/plugged/vim-plug
call plug#begin('~/.vim/plugged')

" use vim-plug manage vim-plug
Plug 'frtmelody/vim-plug'

" Make sure you use single quotes
Plug 'junegunn/seoul256.vim'
Plug 'junegunn/vim-easy-align'

" Group dependencies, vim-snippets depends on ultisnips
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'

" On-demand loading
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }

" Using git URL
Plug 'https://github.com/junegunn/vim-github-dashboard.git'

" Using a non-master branch
Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }

" Plugin options
Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }

" Plugin outside ~/.vim/plugged with post-update hook
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" Unmanaged plugin (manually installed and updated)
Plug '~/my-prototype-plugin'

" Add plugins to &runtimepath
call plug#end()
```

Reload .vimrc and `:PlugInstall` to install plugins.

### Commands

| Command                             | Description                                                        |
| ----------------------------------- | ------------------------------------------------------------------ |
| `PlugInstall [name ...] [#threads]` | Install plugins                                                    |
| `PlugUpdate [name ...] [#threads]`  | Install or update plugins                                          |
| `PlugClean[!]`                      | Remove unused directories (bang version will clean without prompt) |
| `PlugUpgrade`                       | Upgrade vim-plug itself                                            |
| `PlugStatus`                        | Check the status of plugins                                        |
| `PlugDiff`                          | See the updated changes from the previous PlugUpdate               |
| `PlugSnapshot[!] [output path]`     | Generate script for restoring the current snapshot of the plugins  |

### `Plug` options

| Option                  | Description                                      |
| ----------------------- | ------------------------------------------------ |
| `branch`/`tag`/`commit` | Branch/tag/commit of the repository to use       |
| `rtp`                   | Subdirectory that contains Vim plugin            |
| `dir`                   | Custom directory for the plugin                  |
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
| `g:plug_window`     | `vertical topleft new`            | Command to open plug window                            |
| `g:plug_url_format` | `https://git::@github.com/%s.git` | `printf` format to build repo URL                      |

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
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }

" Multiple commands
Plug 'junegunn/vim-github-dashboard', { 'on': ['GHDashboard', 'GHActivity'] }

" Loaded when clojure file is opened
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }

" Multiple file types
Plug 'kovisoft/paredit', { 'for': ['clojure', 'scheme'] }

" On-demand loading on both conditions
Plug 'junegunn/vader.vim',  { 'on': 'Vader', 'for': 'vader' }

" Code to execute when the plugin is loaded on demand
Plug 'Valloric/YouCompleteMe', { 'for': 'cpp' }
autocmd! User YouCompleteMe call youcompleteme#Enable()
```

`for` option is generally not needed as most plugins for specific file types
usually don't have too much code in `plugin` directory. You might want to
examine the output of `vim --startuptime` before applying the option.

### Post-update hooks

There are some plugins that require extra steps after installation or update.
In that case, use `do` option to describe the task to be performed.

```vim
Plug 'Shougo/vimproc.vim', { 'do': 'make' }
Plug 'Valloric/YouCompleteMe', { 'do': './install.py' }
```

If you need more control, you can pass a reference to a Vim function that
takes a single argument.

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

Plug 'Valloric/YouCompleteMe', { 'do': function('BuildYCM') }
```

Both forms of post-update hook are executed inside the directory of the plugin
and only run when the repository has changed, but you can force it to run
unconditionally with the bang-versions of the commands: `PlugInstall!` and
`PlugUpdate!`.

Make sure to escape BARs and double-quotes when you write `do` option inline
as they are mistakenly recognized as command separator or the start of the
trailing comment.

```vim
Plug 'junegunn/fzf', { 'do': 'yes \| ./install' }
```

But you can avoid the escaping if you extract the inline specification using a
variable (or any Vimscript expression) as follows:

```vim
let g:fzf_install = 'yes | ./install'
Plug 'junegunn/fzf', { 'do': g:fzf_install }
```

### FAQ/Troubleshooting

See [FAQ/Troubleshooting](https://github.com/junegunn/vim-plug/wiki/faq).

### Articles

- [Writing my own Vim plugin manager](http://junegunn.kr/2013/09/writing-my-own-vim-plugin-manager)
- [Vim plugins and startup time](http://junegunn.kr/2014/07/vim-plugins-and-startup-time)
- ~~[Thoughts on Vim plugin dependency](http://junegunn.kr/2013/09/thoughts-on-vim-plugin-dependency)~~
    - *Support for Plugfile has been removed since 0.5.0*

### License

MIT

