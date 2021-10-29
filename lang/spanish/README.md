<img src="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.png" height="75" alt="vim-plug">[![travis-ci](https://travis-ci.org/junegunn/vim-plug.svg?branch=master)](https://travis-ci.org/junegunn/vim-plug)
===

<p>
<a href="https://github.com/junegunn/vim-plug">English</a> |
  <span>Español</span>  
</p>

Un administrador de plugins minimalista para Vim.

<img src="https://raw.githubusercontent.com/junegunn/i/master/vim-plug/installer.gif" height="450">

### Pros.

- Fácil de iniciar: Un único archivo. Sin código repetido.
- Fácil de usar: Conciso, sintaxis intuitiva
- Instalación/actualización en paralelo [Super-rapida][40/4]
   (con cualquiera de: `+job`, `+python`, `+python3`, `+ruby`, o [Neovim][nv])
- Crea clones simples para minimizar uso de disco y tiempo de descarga
- Carga a demanda con [faster startup time][startup-time]
- Puedes revisar y revertir actualizaciones
- Soporte para branch/tag/commit
- Acciones post-actualización
- Soporte para complementos externos


[40/4]: https://raw.githubusercontent.com/junegunn/i/master/vim-plug/40-in-4.gif
[nv]: http://neovim.org/
[startup-time]: https://github.com/junegunn/vim-startuptime-benchmark#result

### Instalación

[Descarga plug.vim](https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim)
y péguelo en el directorio "autoload".

#### Vim

###### Unix

```sh
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

Puede automatizar el proceso poniendo el comando en su archivo de configuración
de vim, tal como sugerimos [aquí][auto].


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

### Obteniendo ayuda
 
- Consulte la página [tutorial] para aprender las bases de vim-plug
- Consulte las paginas [tips] y [FAQ] por problemas comunes y preguntas
- Consulte la página [requisitos] para obtener información sobre depuración y configuraciones probadas
- Cree un [issue](https://github.com/junegunn/vim-plug/issues/new)
 
[tutorial]: https://github.com/junegunn/vim-plug/wiki/tutorial
[tips]: https://github.com/junegunn/vim-plug/wiki/tips
[FAQ]: https://github.com/junegunn/vim-plug/wiki/faq
[requirements]: https://github.com/junegunn/vim-plug/wiki/requirements

### Uso

Añada una sección para vim-plug en su `~/.vimrc` (o `stdpath('config') . '/init.vim'` para Neovim)
 
1. Comience la sección con `call plug#begin()`
1. Liste los plugins con el comando `Plug`
1. Finalice la sección con `call plug#end()` para actualizar `&runtimepath` e inicializar el sistema de plugin
   - Automáticamente ejecuta `filetype plugin indent on` y `syntax enable`.
     Puede revertir estas configuraciones luego del llamado. ej: `filetype indent off`, `syntax off`, etc.

#### Ejemplo

```vim
" Especificar un directorio para plugins
"- Para Neovim: stdpath ('data'). '/plugged'
"- Evite el uso de nombres de directorios estándar de Vim como 'plugin'
call plug#begin('~/.vim/plugged')

" Asegúrese de usar comillas simples


" Notación abreviada; busca https://github.com/junegunn/vim-easy-align
Plug 'junegunn/vim-easy-align'

" Se permite cualquier URL de git válida
Plug 'https://github.com/junegunn/vim-github-dashboard.git'

" Se pueden escribir varios comandos Plug en una sola línea utilizando separadores |
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'

" Carga bajo demanda
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }

" Usando una rama no predeterminada
Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }

" Usando una versión etiquetada; comodín permitido (requiere git 1.9.2 o superior)
Plug 'fatih/vim-go', { 'tag': '*' }

" opciones del plugin 
Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }


" Plugin fuera de ~/.vim/plugged con una acción post-actualización
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

"Plugin no administrado (instalado y actualizado manualmente)
Plug '~/my-prototype-plugin'

" Inicializar el sistema de plugins
call plug#end()
```

Recargue el .vimrc y ejecute `:PlugInstall` para instalar los plugins

### Comandos

| Comando                             | Descripción                                                        |
| ----------------------------------- | ------------------------------------------------------------------ |
| `PlugInstall [name ...] [#threads]` | Instalar plugins                                                   |
| `PlugUpdate [name ...] [#threads]`  | Instalar o actualizar plugins                                      |
| `PlugClean[!]`                      | Remover plugins sin listar                                         |
| `PlugUpgrade`                       | Actualizar vim-plug                                                |
| `PlugStatus`                        | Verificar el estado de los plugins                                 |
| `PlugDiff`                          | Examinar cambios entre la última actualización y los cambios pendientes |
| `PlugSnapshot[!] [output path]`     | Generar un script para restaurar el snapshot actual de plugins     |

### Opciones `Plug` 

| Opcion                  | Descripción                                      |
| ----------------------- | ------------------------------------------------ |
| `branch`/`tag`/`commit` | Branch/tag/commit del repositorio a usar         |
| `rtp`                   | Subdirectorio que contiene Vim Plugin            |
| `dir`                   | Directorio personalizado para plugins            |
| `as`                    | Usar un nombre distinto para el plugin           |
| `do`                    | Acciones post-actualización  (string o funcref)    |
| `on`                    | Carga bajo demanda: Comandos o asignaciones `<Plug>` |
| `for`                   | Carga bajo demanda: Tipos de archivo            |
| `frozen`                | No se actualizará a menos que se indique explícitamente |

### Opciones globales

| Bandera                | Por defecto                    | Descripción                                        |
| ------------------- | --------------------------------- | ------------------------------------------------------ |
| `g:plug_threads`    | 16                                | Número por defecto de subprocesos a utilizar           |
| `g:plug_timeout`    | 60                                | Tiempo límite de cada tarea en segundos (*Ruby & Python*)  |
| `g:plug_retries`    | 2                                 | Número de reintentos en caso de timeout (*Ruby & Python*) |
| `g:plug_shallow`    | 1                                 | Usar clon superficial                                  |
| `g:plug_window`     | `vertical topleft new`            | Comando para abrir la ventana de  `<Plug>`             |
| `g:plug_pwindow`    | `above 12new`                     | Comando para abrir la vista previa de `PlugDiff`       |
| `g:plug_url_format` | `https://git::@github.com/%s.git` | `printf` formato para crear la URL del repositorio (solo se aplica a los comandos `Plug` subsiguientes) | 


### Atajos de teclado

- `D` - `PlugDiff`
- `S` - `PlugStatus`
- `R` - Reintentar actualizaciones o instalaciones fallidas
- `U` - Actualizar plugins en el rango seleccionado
- `q` - Cerrar ventana
- `:PlugStatus`
    - `L` - Cargar plugin
- `:PlugDiff`
    - `X` - Revertir la actualización

### Ejemplo: Una pequeña configuration 

```vim
call plug#begin()
Plug 'tpope/vim-sensible'
call plug#end()
```

### Carga bajo demanda de plugins

```vim
" NERD tree será cargado en la primera invocación del comando NERDTreeToggle
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }

" Múltiples comandos
Plug 'junegunn/vim-github-dashboard', { 'on': ['GHDashboard', 'GHActivity'] }

" Cargado cuando se abre un archivo clojure
Plug 'tpope/vim-fireplace', { 'for': 'clojure' }

" Múltiples tipos de archivos
Plug 'kovisoft/paredit', { 'for': ['clojure', 'scheme'] }

"Carga bajo demanda con ambas condiciones
Plug 'junegunn/vader.vim',  { 'on': 'Vader', 'for': 'vader' }

"Código para ejecutar cuando el plugin se carga de forma diferida a pedido
Plug 'junegunn/goyo.vim', { 'for': 'markdown' }
autocmd! User goyo.vim echom 'Goyo is now loaded!'
```

La opción `for` generalmente no es necesaria ya que la mayoría
de los plugins para tipos de archivos específicos no suelen
tener demasiado código en el directorio `plugin`. 
Es posible que desee examinar la salida de `vim --startuptime`
antes de aplicar la opción.


### Acciónes post-actualizacion

Hay algunos plugins que requieren pasos extra luego de la instalación 
o actualización. En esos casos, use la opción do para describir la 
tarea a ser ejecutada

```vim
Plug 'Shougo/vimproc.vim', { 'do': 'make' }
Plug 'ycm-core/YouCompleteMe', { 'do': './install.py' }
```


Si el valor comienza con `:`, sera considerado como un comando de Vim

```vim
Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' }
```

Si usted necesita un mayor control, puede pasarle una referencia 
a una función Vim que tome un solo argumento

```vim
function! BuildYCM(info)
  " info es un diccionario con 3 campos 
  " - name:   nombre del plugin
  " - status: 'installed', 'updated', o 'unchanged'
  " - force: configurado en PlugInstall! o PlugUpdate!
  if a:info.status == 'installed' || a:info.force
    !./install.py
  endif
endfunction

Plug 'ycm-core/YouCompleteMe', { 'do': function('BuildYCM') }
```

Ambas acciones post-actualización se ejecutan dentro del 
directorio del plugin y solo se ejecutan cuando el 
repositorio haya cambiado, pero puede obligarlo a ejecutarse 
incondicionalmente con los comandos: `PlugInstall!` Y `PlugUpdate!`.

Asegúrese de evitar las barras y las comillas dobles cuando 
escriba la opción `do` en línea, ya que se reconocen erróneamente 
como separadores de comandos o como el comienzo del comentario 
final.

```vim
Plug 'junegunn/fzf', { 'do': 'yes \| ./install' }
```

Pero puede evitar el escape si extrae la especificación en línea usando una
variable (o cualquier expresión de Vimscript) de la siguiente manera:

```vim
let g:fzf_install = 'yes | ./install'
Plug 'junegunn/fzf', { 'do': g:fzf_install }
```

### `PlugInstall!` y `PlugUpdate!`

El instalador toma los siguientes pasos cuando se instala o actualiza un plugin

1. `git clone` o `git fetch` desde el origen
2. Verifica ramas, tags o commits y opcionalmente `git merge` ramas remotas
3. Si el plugin fue actualizado (o instalado por primera vez)
    1. actualiza submódulos
    2. Ejecuta acciones post-actualización

Los comandos con el sufijo `!` se aseguran que todos los pasos son ejecutados incondicionalmente


### Artículos

- [Escribiendo mi propio administrador de plugins para vim](http://junegunn.kr/2013/09/writing-my-own-vim-plugin-manager)
- [Plugins de vim y tiempo de inicio](http://junegunn.kr/2014/07/vim-plugins-and-startup-time)
- ~~[Pensamientos sobre la dependencia en los plugins de Vim](http://junegunn.kr/2013/09/thoughts-on-vim-plugin-dependency)~~
    - *El soporte para Plugfile se ha eliminado desde 0.5.0*

### Colaboradores

- [Jan Edmund Lazo](https://github.com/janlazo) - Soporte de ventanas
- [Jeremy Pallats](https://github.com/starcraftman) - Instalador de Python 

### Licencia

MIT