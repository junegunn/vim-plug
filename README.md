vim-plug
========

A single-file Vim plugin manager.

Somewhere between [Pathogen](https://github.com/tpope/vim-pathogen) and
[Vundle](https://github.com/gmarik/vundle), but with faster parallel installer.

### Pros.

- Easier to setup
- Parallel installation/update (requires
  [+ruby](http://junegunn.kr/2013/09/installing-vim-with-ruby-support/))
- Smallest possible feature set

### Cons.

- Everything else

### Usage

Download plug.vim and put it in ~/.vim/autoload

```sh
mkdir -p ~/.vim/autoload
curl -fLo ~/.vim/autoload/plug.vim https://raw.github.com/junegunn/vim-plug/master/plug.vim
```

Edit your .vimrc

```vim
call plug#begin()

Plug 'junegunn/seoul256'
Plug 'junegunn/vim-easy-align'
" Plug 'user/repo', 'branch_or_tag'
" Plug 'git@github.com:junegunn/vim-github-dashboard.git'
" ...

call plug#end()
```

Then `:PlugInstall` to install plugins.

### Plugin directory

By default, plugins are installed in `plugged` directory under the first path in
runtimepath at the point when `plug#begin()` is called. This is usually
`~/.vim/plugged` (or `$HOME/vimfiles` on Windows) given that you didn't touch
runtimepath before the call. You can explicitly set the location of the plugins
with `plug#begin(path)` call.

### Commands

| Command                | Description               |
| ---------------------- | ------------------------- |
| PlugInstall [#threads] | Install plugins           |
| PlugUpdate  [#threads] | Install or update plugins |
| PlugClean              | Remove unused directories |
| PlugUpgrade            | Upgrade vim-plug itself   |

(Default number of threads = `g:plug_threads` or 16)

### Articles

- [Writing my own Vim plugin manager](http://junegunn.kr/2013/09/writing-my-own-vim-plugin-manager)

### Screenshots

#### Parallel installation

![](https://raw.github.com/junegunn/vim-plug/master/gif/pi.gif)

#### Serial installation

![](https://raw.github.com/junegunn/vim-plug/master/gif/si.gif)

#### Parallel update

![](https://raw.github.com/junegunn/vim-plug/master/gif/pu.gif)

#### Serial update

![](https://raw.github.com/junegunn/vim-plug/master/gif/su.gif)

