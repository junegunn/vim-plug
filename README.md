![vim-plug](https://raw.github.com/junegunn/vim-plug/master/plug.png)

A single-file Vim plugin manager.

Somewhere between [Pathogen](https://github.com/tpope/vim-pathogen) and
[Vundle](https://github.com/gmarik/vundle), but with faster parallel installer.

![](https://raw.github.com/junegunn/vim-plug/master/gif/vim-plug.gif)

### Pros.

- Easier to setup
- Parallel installation/update (requires
  [+ruby](http://junegunn.kr/2013/09/installing-vim-with-ruby-support/))
- Smallest possible feature set
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

Plug 'junegunn/seoul256.vim'
Plug 'junegunn/vim-easy-align'
" Plug 'user/repo1', 'branch_or_tag'
" Plug 'user/repo2', { 'rtp': 'vim/plugin/dir', 'branch': 'devel' }
" Plug 'git@github.com:junegunn/vim-github-dashboard.git'
" ...

call plug#end()
```

Reload .vimrc and `:PlugInstall` to install plugins.

### Plugin directory

If you omit the path argument to `plug#begin()`, plugins are installed in
`plugged` directory under the first path in `runtimepath` at the point when
`plug#begin()` is called. This is usually `~/.vim/plugged` (or
`$HOME/vimfiles/plugged` on Windows) given that you didn't touch runtimepath
before the call.

### Commands

| Command                | Description                                                        |
| ---------------------- | ------------------------------------------------------------------ |
| PlugInstall [#threads] | Install plugins                                                    |
| PlugUpdate  [#threads] | Install or update plugins                                          |
| PlugClean[!]           | Remove unused directories (bang version will clean without prompt) |
| PlugUpgrade            | Upgrade vim-plug itself                                            |
| PlugStatus             | Check the status of plugins                                        |

### Options for parallel installer

| Flag             | Default | Description                        |
| ---------------- | ------- | ---------------------------------  |
| `g:plug_threads` | 16      | Default number of threads to use   |
| `g:plug_timeout` | 60      | Time limit of each task in seconds |

### Example: A small [sensible](https://github.com/tpope/vim-sensible) Vim configuration

```vim
call plug#begin()
Plug 'tpope/vim-sensible'
call plug#end()
```

### Dependency resolution

See [Dependency
Resolution](https://github.com/junegunn/vim-plug/wiki/Dependency-Resolution).

### Articles

- [Writing my own Vim plugin manager](http://junegunn.kr/2013/09/writing-my-own-vim-plugin-manager)
- [Thoughts on Vim plugin dependency](http://junegunn.kr/2013/09/thoughts-on-vim-plugin-dependency)

### Troubleshooting

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

### Regarding feature request

You may submit a request for a new feature by [creating an
issue](https://github.com/junegunn/vim-plug/issues). However, please be minded
that this is an opinionated software and I want to keep the feature set as small
as possible. So I may not agree with you on the necessity of the suggested
feature. If that happens, I suggest the following options.

1. Check out [Vundle](https://github.com/gmarik/vundle) or
   [NeoBundle](https://github.com/Shougo/neobundle.vim).
   They offer broader feature sets.
2. Create a fork of this project and let it be your own plugin manager.
   There's no need for us to have a single canonical branch.

