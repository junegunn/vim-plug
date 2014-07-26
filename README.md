![vim-plug](https://raw.github.com/junegunn/vim-plug/master/plug.png)
![travis-ci](https://travis-ci.org/junegunn/vim-plug.svg?branch=master)

A single-file Vim plugin manager.

Somewhere between [Pathogen](https://github.com/tpope/vim-pathogen) and
[Vundle](https://github.com/gmarik/vundle), but with faster parallel installer.

![](https://raw.github.com/junegunn/i/master/vim-plug/installer.gif)

### Pros.

- Easier to setup
- Parallel installation/update (requires
  [+ruby](http://junegunn.kr/2013/09/installing-vim-with-ruby-support/))
- Smallest possible feature set
- Branch/tag support
- On-demand loading
- Dependency resolution using `Plugfile` (experimental)

### Cons.

- Everything else

### Usage

[Download plug.vim](https://raw.github.com/junegunn/vim-plug/master/plug.vim)
and put it in ~/.vim/autoload

```sh
mkdir -p ~/.vim/autoload
curl -fLo ~/.vim/autoload/plug.vim https://raw.github.com/junegunn/vim-plug/master/plug.vim
```

Edit your .vimrc

```vim
call plug#begin('~/.vim/plugged')

" Make sure you use single quotes
Plug 'junegunn/seoul256.vim'
Plug 'junegunn/vim-easy-align'

" On-demand loading
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }

" Using git URL
Plug 'https://github.com/junegunn/vim-github-dashboard.git'

" Plugin options
Plug 'nsf/gocode', { 'tag': 'go.weekly.2012-03-13', 'rtp': 'vim' }

" Locally-managed plugin
Plug '~/.fzf'

call plug#end()
```

Reload .vimrc and `:PlugInstall` to install plugins.

### Commands

| Command                           | Description                                                        |
| --------------------------------- | ------------------------------------------------------------------ |
| PlugInstall [name ...] [#threads] | Install plugins                                                    |
| PlugUpdate [name ...] [#threads]  | Install or update plugins                                          |
| PlugClean[!]                      | Remove unused directories (bang version will clean without prompt) |
| PlugUpgrade                       | Upgrade vim-plug itself                                            |
| PlugStatus                        | Check the status of plugins                                        |
| PlugDiff                          | See the updated changes from the previous PlugUpdate               |

### `Plug` options

| Option         | Description                                                          |
| -------------- | -------------------------------------------------------------------- |
| `branch`/`tag` | Branch or tag of the repository to use                               |
| `rtp`          | Subdirectory that contains Vim plugin                                |
| `do`           | Post-update hook (string of funcref)                                 |
| `on`           | On-demand loading: Commands or <Plug>-mappings                       |
| `for`          | On-demand loading: File types                                        |
| `frozen`       | Do not install/update plugin unless explicitly given as the argument |

### Options for parallel installer

| Flag             | Default | Description                          |
| ---------------- | ------- | ------------------------------------ |
| `g:plug_threads` | 16      | Default number of threads to use     |
| `g:plug_timeout` | 60      | Time limit of each task in seconds   |
| `g:plug_retries` | 2       | Number of retries in case of timeout |

### Keybindings

- `D` - `PlugDiff`
- `S` - `PlugStatus`
- `R` - Retry failed update or installation tasks
- `q` - Close the window

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

" On-demand loading on both conditions
Plug 'junegunn/vader.vim',  { 'on': 'Vader', 'for': 'vader' }
```

### Dependency resolution

See [Dependency
Resolution](https://github.com/junegunn/vim-plug/wiki/Dependency-Resolution).

### Articles

- [Writing my own Vim plugin manager](http://junegunn.kr/2013/09/writing-my-own-vim-plugin-manager)
- [Thoughts on Vim plugin dependency](http://junegunn.kr/2013/09/thoughts-on-vim-plugin-dependency)

### FAQ/Troubleshooting

#### Plugins are not installed/updated in parallel

Your Vim does not support Ruby interface. `:echo has('ruby')` should print 1.
In order to setup Vim with Ruby support, you may refer to [this
article](http://junegunn.kr/2013/09/installing-vim-with-ruby-support).

#### *Vim: Caught deadly signal SEGV*

If your Vim crashes with the above message, first check if its Ruby interface is
working correctly with the following command:

```vim
:ruby puts RUBY_VERSION
```

If Vim crashes even with this command, it is likely that Ruby interface is
broken, and you have to rebuild Vim with a working version of Ruby.
(`brew remove vim && brew install vim` or `./configure && make ...`)

If you're on OS X, one possibility is that you had installed Vim with
[Homebrew](http://brew.sh/) while using a Ruby installed with
[RVM](http://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv) and later
removed that version of Ruby.

[Please let me know](https://github.com/junegunn/vim-plug/issues) if you can't
resolve the problem. In the meantime, you can set `g:plug_threads` to 1, so that
Ruby installer is not used at all.

#### Errors on fish shell

If vim-plug doesn't work correctly on fish shell, you might need to add `set
shell=/bin/sh` to your .vimrc.

Refer to the following links for the details:
- http://badsimplicity.com/vim-fish-e484-cant-open-file-tmpvrdnvqe0-error/
- https://github.com/junegunn/vim-plug/issues/12

#### Freezing plugin version with commit hash

vim-plug does not allow you to freeze the version of a plugin with its commit
hash. This is by design. I don't believe a user of a plugin should be looking
at its individual commits. Instead, one should be choosing the right version
using release tags or versioned branches (e.g. 1.2.3, stable, devel, etc.)

```vim
Plug 'junegunn/vim-easy-align', '2.9.2'
```

If the repository doesn't come with such tags or branches, you should think of
it as "unstable" or "in development", and always use its latest revision.

If you really must choose a certain untagged revision, consider forking the
repository.

### License

MIT

