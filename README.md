vim-plug
========

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
call plug#begin()

Plug 'junegunn/seoul256'
Plug 'junegunn/vim-easy-align'
" Plug 'user/repo1', 'branch_or_tag'
" Plug 'user/repo2', { 'rtp': 'vim/plugin/dir', 'branch': 'devel' }
" Plug 'git@github.com:junegunn/vim-github-dashboard.git'
" ...

call plug#end()
```

Then `:PlugInstall` to install plugins.

### Plugin directory

By default, plugins are installed in `plugged` directory under the first path in
runtimepath at the point when `plug#begin()` is called. This is usually
`~/.vim/plugged` (or `$HOME/vimfiles/plugged` on Windows) given that you didn't
touch runtimepath before the call. You can explicitly set the location of the
plugins with `plug#begin(path)` call.

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

### Dependency resolution

If a Vim plugin specifies its dependent plugins in `Plugfile` in its root
directory, vim-plug will automatically source it recursively during the
installation.

A `Plugfile` should contain a set of `Plug` commands for the dependent plugins.

I've created three dummy repositories with Plugfiles as an example to this
scheme.

- [junegunn/dummy1](https://github.com/junegunn/dummy1/blob/master/Plugfile)
  - Plugfile includes `Plug 'junegunn/dummy2'`
- [junegunn/dummy2](https://github.com/junegunn/dummy2/blob/master/Plugfile)
  - Plugfile includes `Plug 'junegunn/dummy3'`
- [junegunn/dummy3](https://github.com/junegunn/dummy3/blob/master/Plugfile)

If you put `Plug 'junegunn/dummy1'` in your configuration file, and run
`:PlugInstall`,

1. vim-plug first installs dummy1
2. And sees if the repository has Plugfile
3. Plugfile is loaded and vim-plug discovers dependent plugins
4. Dependent plugins are then installed as well, and their Plugfiles are
   examined and their dependencies are resolved recursively.

![](https://raw.github.com/junegunn/vim-plug/master/gif/Plugfile.gif)

### Articles

- [Writing my own Vim plugin manager](http://junegunn.kr/2013/09/writing-my-own-vim-plugin-manager)
- [Thoughts on Vim plugin dependency](http://junegunn.kr/2013/09/thoughts-on-vim-plugin-dependency)

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

