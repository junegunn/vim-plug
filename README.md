vim-plug
========

Vim plugin manager.

### Why?

Because I can?

### Pros.

- Marginally simpler
- Parallel installation/update (requires +ruby)
- Alternative directory structure: user/repo/branch

### Cons.

Everything else.

### Usage

Download plug.vim and put it in ~/.vim/autoload

```sh
mkdir -p ~/.vim/autoload
curl -fL -o ~/.vim/autoload/plug.vim https://raw.github.com/junegunn/vim-plug/master/plug.vim
```

Edit your .vimrc

```vim
call plug#init()

Plug 'junegunn/seoul256'
Plug 'junegunn/vim-easy-align'
" Plug 'user/repo', 'branch_or_tag'
" ...
```

Then :PlugInstall to install plugins. (Default plugin directory: `~/.vim/plugged`)

You can change the location of the plugins with `plug#init(path)` call.

### Commands

| Command                | Description               |
| ---------------------- | ------------------------- |
| PlugInstall [#threads] | Install plugins           |
| PlugUpdate  [#threads] | Install or update plugins |
| PlugClean              | Remove unused directories |
| PlugUpgrade            | Upgrade vim-plug itself   |

(Default #threads = Number of plugins)

