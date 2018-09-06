" vim-plug: Vim plugin manager
" ============================
"
" Download plug.vim and put it in ~/.vim/autoload
"
"   curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
"     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"
" Edit your .vimrc
"
"   call plug#begin('~/.vim/plugged')
"
"   " Make sure you use single quotes
"
"   " Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
"   Plug 'junegunn/vim-easy-align'
"
"   " Any valid git URL is allowed
"   Plug 'https://github.com/junegunn/vim-github-dashboard.git'
"
"   " Multiple Plug commands can be written in a single line using | separators
"   Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
"
"   " On-demand loading
"   Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
"   Plug 'tpope/vim-fireplace', { 'for': 'clojure' }
"
"   " Using a non-master branch
"   Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }
"
"   " Using a tagged release; wildcard allowed (requires git 1.9.2 or above)
"   Plug 'fatih/vim-go', { 'tag': '*' }
"
"   " Plugin options
"   Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }
"
"   " Plugin outside ~/.vim/plugged with post-update hook
"   Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
"
"   " Unmanaged plugin (manually installed and updated)
"   Plug '~/my-prototype-plugin'
"
"   " Initialize plugin system
"   call plug#end()
"
" Then reload .vimrc and :PlugInstall to install plugins.
"
" Plug options:
"
"| Option                  | Description                                      |
"| ----------------------- | ------------------------------------------------ |
"| `branch`/`tag`/`commit` | Branch/tag/commit of the repository to use       |
"| `rtp`                   | Subdirectory that contains Vim plugin            |
"| `dir`                   | Custom directory for the plugin                  |
"| `as`                    | Use different name for the plugin                |
"| `do`                    | Post-update hook (string or funcref)             |
"| `on`                    | On-demand loading: Commands or `<Plug>`-mappings |
"| `for`                   | On-demand loading: File types                    |
"| `frozen`                | Do not update unless explicitly specified        |
"
" More information: https://github.com/junegunn/vim-plug
"
"
" Copyright (c) 2017 Junegunn Choi
"
" MIT License
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

if exists('g:loaded_plug')
  finish
endif
let g:loaded_plug = 1

let s:cpo_save = &cpo
set cpo&vim

let s:plug_src = 'https://github.com/junegunn/vim-plug.git'
let s:plug_tab = get(s:, 'plug_tab', -1)
let s:plug_buf = get(s:, 'plug_buf', -1)
let s:mac_gui = has('gui_macvim') && has('gui_running')
let s:is_win = has('win32')
let s:nvim = has('nvim-0.2') || (has('nvim') && exists('*jobwait') && !s:is_win)
let s:vim8 = has('patch-8.0.0039') && exists('*job_start')
let s:me = resolve(expand('<sfile>:p'))
let s:base_spec = { 'branch': 'master', 'frozen': 0 }
let s:TYPE = {
\   'string':  type(''),
\   'list':    type([]),
\   'dict':    type({}),
\   'funcref': type(function('call'))
\ }
let s:loaded = get(s:, 'loaded', {})
let s:triggers = get(s:, 'triggers', {})

function! plug#begin(...)
  if a:0 > 0
    let s:plug_home_org = a:1
    let home = s:path(fnamemodify(expand(a:1), ':p'))
  elseif exists('g:plug_home')
    let home = s:path(g:plug_home)
  elseif !empty(&rtp)
    let home = s:path(split(&rtp, ',')[0]) . '/plugged'
  else
    return s:err('Unable to determine plug home. Try calling plug#begin() with a path argument.')
  endif
  if fnamemodify(home, ':t') ==# 'plugin' && fnamemodify(home, ':h') ==# s:first_rtp
    return s:err('Invalid plug home. '.home.' is a standard Vim runtime path and is not allowed.')
  endif

  let g:plug_home = home
  let g:plugs = {}
  let g:plugs_order = []
  let s:triggers = {}

  call s:define_commands()
  return 1
endfunction

function! s:define_commands()
  command! -nargs=+ -bar Plug call plug#(<args>)
  if !executable('git')
    return s:err('`git` executable not found. Most commands will not be available. To suppress this message, prepend `silent!` to `call plug#begin(...)`.')
  endif
  command! -nargs=* -bar -bang -complete=customlist,s:names PlugInstall call s:install(<bang>0, [<f-args>])
  command! -nargs=* -bar -bang -complete=customlist,s:names PlugUpdate  call s:update(<bang>0, [<f-args>])
  command! -nargs=0 -bar -bang PlugClean call s:clean(<bang>0)
  command! -nargs=0 -bar PlugUpgrade if s:upgrade() | execute 'source' s:esc(s:me) | endif
  command! -nargs=0 -bar PlugStatus  call s:status()
  command! -nargs=0 -bar PlugDiff    call s:diff()
  command! -nargs=? -bar -bang -complete=file PlugSnapshot call s:snapshot(<bang>0, <f-args>)
endfunction

function! s:to_a(v)
  return type(a:v) == s:TYPE.list ? a:v : [a:v]
endfunction

function! s:to_s(v)
  return type(a:v) == s:TYPE.string ? a:v : join(a:v, "\n") . "\n"
endfunction

function! s:glob(from, pattern)
  return s:lines(globpath(a:from, a:pattern))
endfunction

function! s:source(from, ...)
  let found = 0
  for pattern in a:000
    for vim in s:glob(a:from, pattern)
      execute 'source' s:esc(vim)
      let found = 1
    endfor
  endfor
  return found
endfunction

function! s:assoc(dict, key, val)
  let a:dict[a:key] = add(get(a:dict, a:key, []), a:val)
endfunction

function! s:ask(message, ...)
  call inputsave()
  echohl WarningMsg
  let answer = input(a:message.(a:0 ? ' (y/N/a) ' : ' (y/N) '))
  echohl None
  call inputrestore()
  echo "\r"
  return (a:0 && answer =~? '^a') ? 2 : (answer =~? '^y') ? 1 : 0
endfunction

function! s:ask_no_interrupt(...)
  try
    return call('s:ask', a:000)
  catch
    return 0
  endtry
endfunction

function! plug#end()
  if !exists('g:plugs')
    return s:err('Call plug#begin() first')
  endif

  if exists('#PlugLOD')
    augroup PlugLOD
      autocmd!
    augroup END
    augroup! PlugLOD
  endif
  let lod = { 'ft': {}, 'map': {}, 'cmd': {} }

  if exists('g:did_load_filetypes')
    filetype off
  endif
  for name in g:plugs_order
    if !has_key(g:plugs, name)
      continue
    endif
    let plug = g:plugs[name]
    if get(s:loaded, name, 0) || !has_key(plug, 'on') && !has_key(plug, 'for')
      let s:loaded[name] = 1
      continue
    endif

    if has_key(plug, 'on')
      let s:triggers[name] = { 'map': [], 'cmd': [] }
      for cmd in s:to_a(plug.on)
        if cmd =~? '^<Plug>.\+'
          if empty(mapcheck(cmd)) && empty(mapcheck(cmd, 'i'))
            call s:assoc(lod.map, cmd, name)
          endif
          call add(s:triggers[name].map, cmd)
        elseif cmd =~# '^[A-Z]'
          let cmd = substitute(cmd, '!*$', '', '')
          if exists(':'.cmd) != 2
            call s:assoc(lod.cmd, cmd, name)
          endif
          call add(s:triggers[name].cmd, cmd)
        else
          call s:err('Invalid `on` option: '.cmd.
          \ '. Should start with an uppercase letter or `<Plug>`.')
        endif
      endfor
    endif

    if has_key(plug, 'for')
      let types = s:to_a(plug.for)
      if !empty(types)
        augroup filetypedetect
        call s:source(s:rtp(plug), 'ftdetect/**/*.vim', 'after/ftdetect/**/*.vim')
        augroup END
      endif
      for type in types
        call s:assoc(lod.ft, type, name)
      endfor
    endif
  endfor

  for [cmd, names] in items(lod.cmd)
    execute printf(
    \ 'command! -nargs=* -range -bang -complete=file %s call s:lod_cmd(%s, "<bang>", <line1>, <line2>, <q-args>, %s)',
    \ cmd, string(cmd), string(names))
  endfor

  for [map, names] in items(lod.map)
    for [mode, map_prefix, key_prefix] in
          \ [['i', '<C-O>', ''], ['n', '', ''], ['v', '', 'gv'], ['o', '', '']]
      execute printf(
      \ '%snoremap <silent> %s %s:<C-U>call <SID>lod_map(%s, %s, %s, "%s")<CR>',
      \ mode, map, map_prefix, string(map), string(names), mode != 'i', key_prefix)
    endfor
  endfor

  for [ft, names] in items(lod.ft)
    augroup PlugLOD
      execute printf('autocmd FileType %s call <SID>lod_ft(%s, %s)',
            \ ft, string(ft), string(names))
    augroup END
  endfor

  call s:reorg_rtp()
  filetype plugin indent on
  if has('vim_starting')
    if has('syntax') && !exists('g:syntax_on')
      syntax enable
    end
  else
    call s:reload_plugins()
  endif
endfunction

function! s:loaded_names()
  return filter(copy(g:plugs_order), 'get(s:loaded, v:val, 0)')
endfunction

function! s:load_plugin(spec)
  call s:source(s:rtp(a:spec), 'plugin/**/*.vim', 'after/plugin/**/*.vim')
endfunction

function! s:reload_plugins()
  for name in s:loaded_names()
    call s:load_plugin(g:plugs[name])
  endfor
endfunction

function! s:trim(str)
  return substitute(a:str, '[\/]\+$', '', '')
endfunction

function! s:version_requirement(val, min)
  for idx in range(0, len(a:min) - 1)
    let v = get(a:val, idx, 0)
    if     v < a:min[idx] | return 0
    elseif v > a:min[idx] | return 1
    endif
  endfor
  return 1
endfunction

function! s:git_version_requirement(...)
  if !exists('s:git_version')
    let s:git_version = map(split(split(s:system('git --version'))[2], '\.'), 'str2nr(v:val)')
  endif
  return s:version_requirement(s:git_version, a:000)
endfunction

function! s:progress_opt(base)
  return a:base && !s:is_win &&
        \ s:git_version_requirement(1, 7, 1) ? '--progress' : ''
endfunction

if s:is_win
  function! s:rtp(spec)
    return s:path(a:spec.dir . get(a:spec, 'rtp', ''))
  endfunction

  function! s:path(path)
    return s:trim(substitute(a:path, '/', '\', 'g'))
  endfunction

  function! s:dirpath(path)
    return s:path(a:path) . '\'
  endfunction

  function! s:is_local_plug(repo)
    return a:repo =~? '^[a-z]:\|^[%~]'
  endfunction
else
  function! s:rtp(spec)
    return s:dirpath(a:spec.dir . get(a:spec, 'rtp', ''))
  endfunction

  function! s:path(path)
    return s:trim(a:path)
  endfunction

  function! s:dirpath(path)
    return substitute(a:path, '[/\\]*$', '/', '')
  endfunction

  function! s:is_local_plug(repo)
    return a:repo[0] =~ '[/$~]'
  endfunction
endif

function! s:err(msg)
  echohl ErrorMsg
  echom '[vim-plug] '.a:msg
  echohl None
endfunction

function! s:warn(cmd, msg)
  echohl WarningMsg
  execute a:cmd 'a:msg'
  echohl None
endfunction

function! s:esc(path)
  return escape(a:path, ' ')
endfunction

function! s:escrtp(path)
  return escape(a:path, ' ,')
endfunction

function! s:remove_rtp()
  for name in s:loaded_names()
    let rtp = s:rtp(g:plugs[name])
    execute 'set rtp-='.s:escrtp(rtp)
    let after = globpath(rtp, 'after')
    if isdirectory(after)
      execute 'set rtp-='.s:escrtp(after)
    endif
  endfor
endfunction

function! s:reorg_rtp()
  if !empty(s:first_rtp)
    execute 'set rtp-='.s:first_rtp
    execute 'set rtp-='.s:last_rtp
  endif

  " &rtp is modified from outside
  if exists('s:prtp') && s:prtp !=# &rtp
    call s:remove_rtp()
    unlet! s:middle
  endif

  let s:middle = get(s:, 'middle', &rtp)
  let rtps     = map(s:loaded_names(), 's:rtp(g:plugs[v:val])')
  let afters   = filter(map(copy(rtps), 'globpath(v:val, "after")'), '!empty(v:val)')
  let rtp      = join(map(rtps, 'escape(v:val, ",")'), ',')
                 \ . ','.s:middle.','
                 \ . join(map(afters, 'escape(v:val, ",")'), ',')
  let &rtp     = substitute(substitute(rtp, ',,*', ',', 'g'), '^,\|,$', '', 'g')
  let s:prtp   = &rtp

  if !empty(s:first_rtp)
    execute 'set rtp^='.s:first_rtp
    execute 'set rtp+='.s:last_rtp
  endif
endfunction

function! s:doautocmd(...)
  if exists('#'.join(a:000, '#'))
    execute 'doautocmd' ((v:version > 703 || has('patch442')) ? '<nomodeline>' : '') join(a:000)
  endif
endfunction

function! s:dobufread(names)
  for name in a:names
    let path = s:rtp(g:plugs[name]).'/**'
    for dir in ['ftdetect', 'ftplugin']
      if len(finddir(dir, path))
        if exists('#BufRead')
          doautocmd BufRead
        endif
        return
      endif
    endfor
  endfor
endfunction

function! plug#load(...)
  if a:0 == 0
    return s:err('Argument missing: plugin name(s) required')
  endif
  if !exists('g:plugs')
    return s:err('plug#begin was not called')
  endif
  let names = a:0 == 1 && type(a:1) == s:TYPE.list ? a:1 : a:000
  let unknowns = filter(copy(names), '!has_key(g:plugs, v:val)')
  if !empty(unknowns)
    let s = len(unknowns) > 1 ? 's' : ''
    return s:err(printf('Unknown plugin%s: %s', s, join(unknowns, ', ')))
  end
  let unloaded = filter(copy(names), '!get(s:loaded, v:val, 0)')
  if !empty(unloaded)
    for name in unloaded
      call s:lod([name], ['ftdetect', 'after/ftdetect', 'plugin', 'after/plugin'])
    endfor
    call s:dobufread(unloaded)
    return 1
  end
  return 0
endfunction

function! s:remove_triggers(name)
  if !has_key(s:triggers, a:name)
    return
  endif
  for cmd in s:triggers[a:name].cmd
    execute 'silent! delc' cmd
  endfor
  for map in s:triggers[a:name].map
    execute 'silent! unmap' map
    execute 'silent! iunmap' map
  endfor
  call remove(s:triggers, a:name)
endfunction

function! s:lod(names, types, ...)
  for name in a:names
    call s:remove_triggers(name)
    let s:loaded[name] = 1
  endfor
  call s:reorg_rtp()

  for name in a:names
    let rtp = s:rtp(g:plugs[name])
    for dir in a:types
      call s:source(rtp, dir.'/**/*.vim')
    endfor
    if a:0
      if !s:source(rtp, a:1) && !empty(s:glob(rtp, a:2))
        execute 'runtime' a:1
      endif
      call s:source(rtp, a:2)
    endif
    call s:doautocmd('User', name)
  endfor
endfunction

function! s:lod_ft(pat, names)
  let syn = 'syntax/'.a:pat.'.vim'
  call s:lod(a:names, ['plugin', 'after/plugin'], syn, 'after/'.syn)
  execute 'autocmd! PlugLOD FileType' a:pat
  call s:doautocmd('filetypeplugin', 'FileType')
  call s:doautocmd('filetypeindent', 'FileType')
endfunction

function! s:lod_cmd(cmd, bang, l1, l2, args, names)
  call s:lod(a:names, ['ftdetect', 'after/ftdetect', 'plugin', 'after/plugin'])
  call s:dobufread(a:names)
  execute printf('%s%s%s %s', (a:l1 == a:l2 ? '' : (a:l1.','.a:l2)), a:cmd, a:bang, a:args)
endfunction

function! s:lod_map(map, names, with_prefix, prefix)
  call s:lod(a:names, ['ftdetect', 'after/ftdetect', 'plugin', 'after/plugin'])
  call s:dobufread(a:names)
  let extra = ''
  while 1
    let c = getchar(0)
    if c == 0
      break
    endif
    let extra .= nr2char(c)
  endwhile

  if a:with_prefix
    let prefix = v:count ? v:count : ''
    let prefix .= '"'.v:register.a:prefix
    if mode(1) == 'no'
      if v:operator == 'c'
        let prefix = "\<esc>" . prefix
      endif
      let prefix .= v:operator
    endif
    call feedkeys(prefix, 'n')
  endif
  call feedkeys(substitute(a:map, '^<Plug>', "\<Plug>", '') . extra)
endfunction

function! plug#(repo, ...)
  if a:0 > 1
    return s:err('Invalid number of arguments (1..2)')
  endif

  try
    let repo = s:trim(a:repo)
    let opts = a:0 == 1 ? s:parse_options(a:1) : s:base_spec
    let name = get(opts, 'as', fnamemodify(repo, ':t:s?\.git$??'))
    let spec = extend(s:infer_properties(name, repo), opts)
    if !has_key(g:plugs, name)
      call add(g:plugs_order, name)
    endif
    let g:plugs[name] = spec
    let s:loaded[name] = get(s:loaded, name, 0)
  catch
    return s:err(v:exception)
  endtry
endfunction

function! s:parse_options(arg)
  let opts = copy(s:base_spec)
  let type = type(a:arg)
  if type == s:TYPE.string
    let opts.tag = a:arg
  elseif type == s:TYPE.dict
    call extend(opts, a:arg)
    if has_key(opts, 'dir')
      let opts.dir = s:dirpath(expand(opts.dir))
    endif
  else
    throw 'Invalid argument type (expected: string or dictionary)'
  endif
  return opts
endfunction

function! s:infer_properties(name, repo)
  let repo = a:repo
  if s:is_local_plug(repo)
    return { 'dir': s:dirpath(expand(repo)) }
  else
    if repo =~ ':'
      let uri = repo
    else
      if repo !~ '/'
        throw printf('Invalid argument: %s (implicit `vim-scripts'' expansion is deprecated)', repo)
      endif
      let fmt = get(g:, 'plug_url_format', 'https://git::@github.com/%s.git')
      let uri = printf(fmt, repo)
    endif
    return { 'dir': s:dirpath(g:plug_home.'/'.a:name), 'uri': uri }
  endif
endfunction

function! s:install(force, names)
  call s:update_impl(0, a:force, a:names)
endfunction

function! s:update(force, names)
  call s:update_impl(1, a:force, a:names)
endfunction

function! plug#helptags()
  if !exists('g:plugs')
    return s:err('plug#begin was not called')
  endif
  for spec in values(g:plugs)
    let docd = join([s:rtp(spec), 'doc'], '/')
    if isdirectory(docd)
      silent! execute 'helptags' s:esc(docd)
    endif
  endfor
  return 1
endfunction

function! s:syntax()
  syntax clear
  syntax region plug1 start=/\%1l/ end=/\%2l/ contains=plugNumber
  syntax region plug2 start=/\%2l/ end=/\%3l/ contains=plugBracket,plugX
  syn match plugNumber /[0-9]\+[0-9.]*/ contained
  syn match plugBracket /[[\]]/ contained
  syn match plugX /x/ contained
  syn match plugDash /^-/
  syn match plugPlus /^+/
  syn match plugStar /^*/
  syn match plugMessage /\(^- \)\@<=.*/
  syn match plugName /\(^- \)\@<=[^ ]*:/
  syn match plugSha /\%(: \)\@<=[0-9a-f]\{4,}$/
  syn match plugTag /(tag: [^)]\+)/
  syn match plugInstall /\(^+ \)\@<=[^:]*/
  syn match plugUpdate /\(^* \)\@<=[^:]*/
  syn match plugCommit /^  \X*[0-9a-f]\{7,9} .*/ contains=plugRelDate,plugEdge,plugTag
  syn match plugEdge /^  \X\+$/
  syn match plugEdge /^  \X*/ contained nextgroup=plugSha
  syn match plugSha /[0-9a-f]\{7,9}/ contained
  syn match plugRelDate /([^)]*)$/ contained
  syn match plugNotLoaded /(not loaded)$/
  syn match plugError /^x.*/
  syn region plugDeleted start=/^\~ .*/ end=/^\ze\S/
  syn match plugH2 /^.*:\n-\+$/
  syn keyword Function PlugInstall PlugStatus PlugUpdate PlugClean
  hi def link plug1       Title
  hi def link plug2       Repeat
  hi def link plugH2      Type
  hi def link plugX       Exception
  hi def link plugBracket Structure
  hi def link plugNumber  Number

  hi def link plugDash    Special
  hi def link plugPlus    Constant
  hi def link plugStar    Boolean

  hi def link plugMessage Function
  hi def link plugName    Label
  hi def link plugInstall Function
  hi def link plugUpdate  Type

  hi def link plugError   Error
  hi def link plugDeleted Ignore
  hi def link plugRelDate Comment
  hi def link plugEdge    PreProc
  hi def link plugSha     Identifier
  hi def link plugTag     Constant

  hi def link plugNotLoaded Comment
endfunction

function! s:lpad(str, len)
  return a:str . repeat(' ', a:len - len(a:str))
endfunction

function! s:lines(msg)
  return split(a:msg, "[\r\n]")
endfunction

function! s:lastline(msg)
  return get(s:lines(a:msg), -1, '')
endfunction

function! s:new_window()
  execute get(g:, 'plug_window', 'vertical topleft new')
endfunction

function! s:plug_window_exists()
  let buflist = tabpagebuflist(s:plug_tab)
  return !empty(buflist) && index(buflist, s:plug_buf) >= 0
endfunction

function! s:switch_in()
  if !s:plug_window_exists()
    return 0
  endif

  if winbufnr(0) != s:plug_buf
    let s:pos = [tabpagenr(), winnr(), winsaveview()]
    execute 'normal!' s:plug_tab.'gt'
    let winnr = bufwinnr(s:plug_buf)
    execute winnr.'wincmd w'
    call add(s:pos, winsaveview())
  else
    let s:pos = [winsaveview()]
  endif

  setlocal modifiable
  return 1
endfunction

function! s:switch_out(...)
  call winrestview(s:pos[-1])
  setlocal nomodifiable
  if a:0 > 0
    execute a:1
  endif

  if len(s:pos) > 1
    execute 'normal!' s:pos[0].'gt'
    execute s:pos[1] 'wincmd w'
    call winrestview(s:pos[2])
  endif
endfunction

function! s:finish_bindings()
  nnoremap <silent> <buffer> R  :call <SID>retry()<cr>
  nnoremap <silent> <buffer> D  :PlugDiff<cr>
  nnoremap <silent> <buffer> S  :PlugStatus<cr>
  nnoremap <silent> <buffer> U  :call <SID>status_update()<cr>
  xnoremap <silent> <buffer> U  :call <SID>status_update()<cr>
  nnoremap <silent> <buffer> ]] :silent! call <SID>section('')<cr>
  nnoremap <silent> <buffer> [[ :silent! call <SID>section('b')<cr>
endfunction

function! s:prepare(...)
  if empty(getcwd())
    throw 'Invalid current working directory. Cannot proceed.'
  endif

  for evar in ['$GIT_DIR', '$GIT_WORK_TREE']
    if exists(evar)
      throw evar.' detected. Cannot proceed.'
    endif
  endfor

  call s:job_abort()
  if s:switch_in()
    if b:plug_preview == 1
      pc
    endif
    enew
  else
    call s:new_window()
  endif

  nnoremap <silent> <buffer> q  :if b:plug_preview==1<bar>pc<bar>endif<bar>bd<cr>
  if a:0 == 0
    call s:finish_bindings()
  endif
  let b:plug_preview = -1
  let s:plug_tab = tabpagenr()
  let s:plug_buf = winbufnr(0)
  call s:assign_name()

  for k in ['<cr>', 'L', 'o', 'X', 'd', 'dd']
    execute 'silent! unmap <buffer>' k
  endfor
  setlocal buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile nowrap cursorline modifiable nospell
  if exists('+colorcolumn')
    setlocal colorcolumn=
  endif
  setf vim-plug
  if exists('g:syntax_on')
    call s:syntax()
  endif
endfunction

function! s:assign_name()
  " Assign buffer name
  let prefix = '[Plugins]'
  let name   = prefix
  let idx    = 2
  while bufexists(name)
    let name = printf('%s (%s)', prefix, idx)
    let idx = idx + 1
  endwhile
  silent! execute 'f' fnameescape(name)
endfunction

function! s:chsh(swap)
  let prev = [&shell, &shellcmdflag, &shellredir]
  if s:is_win
    set shell=cmd.exe shellcmdflag=/c shellredir=>%s\ 2>&1
  elseif a:swap
    set shell=sh shellredir=>%s\ 2>&1
  endif
  return prev
endfunction

function! s:bang(cmd, ...)
  try
    let [sh, shellcmdflag, shrd] = s:chsh(a:0)
    " FIXME: Escaping is incomplete. We could use shellescape with eval,
    "        but it won't work on Windows.
    let cmd = a:0 ? s:with_cd(a:cmd, a:1) : a:cmd
    if s:is_win
      let batchfile = tempname().'.bat'
      call writefile(["@echo off\r", cmd . "\r"], batchfile)
      let cmd = batchfile
    endif
    let g:_plug_bang = (s:is_win && has('gui_running') ? 'silent ' : '').'!'.escape(cmd, '#!%')
    execute "normal! :execute g:_plug_bang\<cr>\<cr>"
  finally
    unlet g:_plug_bang
    let [&shell, &shellcmdflag, &shellredir] = [sh, shellcmdflag, shrd]
    if s:is_win
      call delete(batchfile)
    endif
  endtry
  return v:shell_error ? 'Exit status: ' . v:shell_error : ''
endfunction

function! s:regress_bar()
  let bar = substitute(getline(2)[1:-2], '.*\zs=', 'x', '')
  call s:progress_bar(2, bar, len(bar))
endfunction

function! s:is_updated(dir)
  return !empty(s:system_chomp('git log --pretty=format:"%h" "HEAD...HEAD@{1}"', a:dir))
endfunction

function! s:do(pull, force, todo)
  for [name, spec] in items(a:todo)
    if !isdirectory(spec.dir)
      continue
    endif
    let installed = has_key(s:update.new, name)
    let updated = installed ? 0 :
      \ (a:pull && index(s:update.errors, name) < 0 && s:is_updated(spec.dir))
    if a:force || installed || updated
      execute 'cd' s:esc(spec.dir)
      call append(3, '- Post-update hook for '. name .' ... ')
      let error = ''
      let type = type(spec.do)
      if type == s:TYPE.string
        if spec.do[0] == ':'
          if !get(s:loaded, name, 0)
            let s:loaded[name] = 1
            call s:reorg_rtp()
          endif
          call s:load_plugin(spec)
          try
            execute spec.do[1:]
          catch
            let error = v:exception
          endtry
          if !s:plug_window_exists()
            cd -
            throw 'Warning: vim-plug was terminated by the post-update hook of '.name
          endif
        else
          let error = s:bang(spec.do)
        endif
      elseif type == s:TYPE.funcref
        try
          let status = installed ? 'installed' : (updated ? 'updated' : 'unchanged')
          call spec.do({ 'name': name, 'status': status, 'force': a:force })
        catch
          let error = v:exception
        endtry
      else
        let error = 'Invalid hook type'
      endif
      call s:switch_in()
      call setline(4, empty(error) ? (getline(4) . 'OK')
                                 \ : ('x' . getline(4)[1:] . error))
      if !empty(error)
        call add(s:update.errors, name)
        call s:regress_bar()
      endif
      cd -
    endif
  endfor
endfunction

function! s:hash_match(a, b)
  return stridx(a:a, a:b) == 0 || stridx(a:b, a:a) == 0
endfunction

function! s:checkout(spec)
  let sha = a:spec.commit
  let output = s:system('git rev-parse HEAD', a:spec.dir)
  if !v:shell_error && !s:hash_match(sha, s:lines(output)[0])
    let output = s:system(
          \ 'git fetch --depth 999999 && git checkout '.s:esc(sha).' --', a:spec.dir)
  endif
  return output
endfunction

function! s:finish(pull)
  let new_frozen = len(filter(keys(s:update.new), 'g:plugs[v:val].frozen'))
  if new_frozen
    let s = new_frozen > 1 ? 's' : ''
    call append(3, printf('- Installed %d frozen plugin%s', new_frozen, s))
  endif
  call append(3, '- Finishing ... ') | 4
  redraw
  call plug#helptags()
  call plug#end()
  call setline(4, getline(4) . 'Done!')
  redraw
  let msgs = []
  if !empty(s:update.errors)
    call add(msgs, "Press 'R' to retry.")
  endif
  if a:pull && len(s:update.new) < len(filter(getline(5, '$'),
                \ "v:val =~ '^- ' && v:val !~# 'Already up.to.date'"))
    call add(msgs, "Press 'D' to see the updated changes.")
  endif
  echo join(msgs, ' ')
  call s:finish_bindings()
endfunction

function! s:retry()
  if empty(s:update.errors)
    return
  endif
  echo
  call s:update_impl(s:update.pull, s:update.force,
        \ extend(copy(s:update.errors), [s:update.threads]))
endfunction

function! s:is_managed(name)
  return has_key(g:plugs[a:name], 'uri')
endfunction

function! s:names(...)
  return sort(filter(keys(g:plugs), 'stridx(v:val, a:1) == 0 && s:is_managed(v:val)'))
endfunction

function! s:check_ruby()
  silent! ruby require 'thread'; VIM::command("let g:plug_ruby = '#{RUBY_VERSION}'")
  if !exists('g:plug_ruby')
    redraw!
    return s:warn('echom', 'Warning: Ruby interface is broken')
  endif
  let ruby_version = split(g:plug_ruby, '\.')
  unlet g:plug_ruby
  return s:version_requirement(ruby_version, [1, 8, 7])
endfunction

function! s:update_impl(pull, force, args) abort
  let sync = index(a:args, '--sync') >= 0 || has('vim_starting')
  let args = filter(copy(a:args), 'v:val != "--sync"')
  let threads = (len(args) > 0 && args[-1] =~ '^[1-9][0-9]*$') ?
                  \ remove(args, -1) : get(g:, 'plug_threads', 16)

  let managed = filter(copy(g:plugs), 's:is_managed(v:key)')
  let todo = empty(args) ? filter(managed, '!v:val.frozen || !isdirectory(v:val.dir)') :
                         \ filter(managed, 'index(args, v:key) >= 0')

  if empty(todo)
    return s:warn('echo', 'No plugin to '. (a:pull ? 'update' : 'install'))
  endif

  if !s:is_win && s:git_version_requirement(2, 3)
    let s:git_terminal_prompt = exists('$GIT_TERMINAL_PROMPT') ? $GIT_TERMINAL_PROMPT : ''
    let $GIT_TERMINAL_PROMPT = 0
    for plug in values(todo)
      let plug.uri = substitute(plug.uri,
            \ '^https://git::@github\.com', 'https://github.com', '')
    endfor
  endif

  if !isdirectory(g:plug_home)
    try
      call mkdir(g:plug_home, 'p')
    catch
      return s:err(printf('Invalid plug directory: %s. '.
              \ 'Try to call plug#begin with a valid directory', g:plug_home))
    endtry
  endif

  if has('nvim') && !exists('*jobwait') && threads > 1
    call s:warn('echom', '[vim-plug] Update Neovim for parallel installer')
  endif

  let use_job = s:nvim || s:vim8
  let python = (has('python') || has('python3')) && !use_job
  let ruby = has('ruby') && !use_job && (v:version >= 703 || v:version == 702 && has('patch374')) && !(s:is_win && has('gui_running')) && threads > 1 && s:check_ruby()

  let s:update = {
    \ 'start':   reltime(),
    \ 'all':     todo,
    \ 'todo':    copy(todo),
    \ 'errors':  [],
    \ 'pull':    a:pull,
    \ 'force':   a:force,
    \ 'new':     {},
    \ 'threads': (python || ruby || use_job) ? min([len(todo), threads]) : 1,
    \ 'bar':     '',
    \ 'fin':     0
  \ }

  call s:prepare(1)
  call append(0, ['', ''])
  normal! 2G
  silent! redraw

  let s:clone_opt = get(g:, 'plug_shallow', 1) ?
        \ '--depth 1' . (s:git_version_requirement(1, 7, 10) ? ' --no-single-branch' : '') : ''

  if has('win32unix')
    let s:clone_opt .= ' -c core.eol=lf -c core.autocrlf=input'
  endif

  let s:submodule_opt = s:git_version_requirement(2, 8) ? ' --jobs='.threads : ''

  " Python version requirement (>= 2.7)
  if python && !has('python3') && !ruby && !use_job && s:update.threads > 1
    redir => pyv
    silent python import platform; print platform.python_version()
    redir END
    let python = s:version_requirement(
          \ map(split(split(pyv)[0], '\.'), 'str2nr(v:val)'), [2, 6])
  endif

  if (python || ruby) && s:update.threads > 1
    try
      let imd = &imd
      if s:mac_gui
        set noimd
      endif
      if ruby
        call s:update_ruby()
      else
        call s:update_python()
      endif
    catch
      let lines = getline(4, '$')
      let printed = {}
      silent! 4,$d _
      for line in lines
        let name = s:extract_name(line, '.', '')
        if empty(name) || !has_key(printed, name)
          call append('$', line)
          if !empty(name)
            let printed[name] = 1
            if line[0] == 'x' && index(s:update.errors, name) < 0
              call add(s:update.errors, name)
            end
          endif
        endif
      endfor
    finally
      let &imd = imd
      call s:update_finish()
    endtry
  else
    call s:update_vim()
    while use_job && sync
      sleep 100m
      if s:update.fin
        break
      endif
    endwhile
  endif
endfunction

function! s:log4(name, msg)
  call setline(4, printf('- %s (%s)', a:msg, a:name))
  redraw
endfunction

function! s:update_finish()
  if exists('s:git_terminal_prompt')
    let $GIT_TERMINAL_PROMPT = s:git_terminal_prompt
  endif
  if s:switch_in()
    call append(3, '- Updating ...') | 4
    for [name, spec] in items(filter(copy(s:update.all), 'index(s:update.errors, v:key) < 0 && (s:update.force || s:update.pull || has_key(s:update.new, v:key))'))
      let [pos, _] = s:logpos(name)
      if !pos
        continue
      endif
      if has_key(spec, 'commit')
        call s:log4(name, 'Checking out '.spec.commit)
        let out = s:checkout(spec)
      elseif has_key(spec, 'tag')
        let tag = spec.tag
        if tag =~ '\*'
          let tags = s:lines(s:system('git tag --list '.s:shellesc(tag).' --sort -version:refname 2>&1', spec.dir))
          if !v:shell_error && !empty(tags)
            let tag = tags[0]
            call s:log4(name, printf('Latest tag for %s -> %s', spec.tag, tag))
            call append(3, '')
          endif
        endif
        call s:log4(name, 'Checking out '.tag)
        let out = s:system('git checkout -q '.s:esc(tag).' -- 2>&1', spec.dir)
      else
        let branch = s:esc(get(spec, 'branch', 'master'))
        call s:log4(name, 'Merging origin/'.branch)
        let out = s:system('git checkout -q '.branch.' -- 2>&1'
              \. (has_key(s:update.new, name) ? '' : ('&& git merge --ff-only origin/'.branch.' 2>&1')), spec.dir)
      endif
      if !v:shell_error && filereadable(spec.dir.'/.gitmodules') &&
            \ (s:update.force || has_key(s:update.new, name) || s:is_updated(spec.dir))
        call s:log4(name, 'Updating submodules. This may take a while.')
        let out .= s:bang('git submodule update --init --recursive'.s:submodule_opt.' 2>&1', spec.dir)
      endif
      let msg = s:format_message(v:shell_error ? 'x': '-', name, out)
      if v:shell_error
        call add(s:update.errors, name)
        call s:regress_bar()
        silent execute pos 'd _'
        call append(4, msg) | 4
      elseif !empty(out)
        call setline(pos, msg[0])
      endif
      redraw
    endfor
    silent 4 d _
    try
      call s:do(s:update.pull, s:update.force, filter(copy(s:update.all), 'index(s:update.errors, v:key) < 0 && has_key(v:val, "do")'))
    catch
      call s:warn('echom', v:exception)
      call s:warn('echo', '')
      return
    endtry
    call s:finish(s:update.pull)
    call setline(1, 'Updated. Elapsed time: ' . split(reltimestr(reltime(s:update.start)))[0] . ' sec.')
    call s:switch_out('normal! gg')
  endif
endfunction

function! s:job_abort()
  if (!s:nvim && !s:vim8) || !exists('s:jobs')
    return
  endif

  for [name, j] in items(s:jobs)
    if s:nvim
      silent! call jobstop(j.jobid)
    elseif s:vim8
      silent! call job_stop(j.jobid)
    endif
    if j.new
      call s:system('rm -rf ' . s:shellesc(g:plugs[name].dir))
    endif
  endfor
  let s:jobs = {}
endfunction

function! s:last_non_empty_line(lines)
  let len = len(a:lines)
  for idx in range(len)
    let line = a:lines[len-idx-1]
    if !empty(line)
      return line
    endif
  endfor
  return ''
endfunction

function! s:job_out_cb(self, data) abort
  let self = a:self
  let data = remove(self.lines, -1) . a:data
  let lines = map(split(data, "\n", 1), 'split(v:val, "\r", 1)[-1]')
  call extend(self.lines, lines)
  " To reduce the number of buffer updates
  let self.tick = get(self, 'tick', -1) + 1
  if !self.running || self.tick % len(s:jobs) == 0
    let bullet = self.running ? (self.new ? '+' : '*') : (self.error ? 'x' : '-')
    let result = self.error ? join(self.lines, "\n") : s:last_non_empty_line(self.lines)
    call s:log(bullet, self.name, result)
  endif
endfunction

function! s:job_exit_cb(self, data) abort
  let a:self.running = 0
  let a:self.error = a:data != 0
  call s:reap(a:self.name)
  call s:tick()
endfunction

function! s:job_cb(fn, job, ch, data)
  if !s:plug_window_exists() " plug window closed
    return s:job_abort()
  endif
  call call(a:fn, [a:job, a:data])
endfunction

function! s:nvim_cb(job_id, data, event) dict abort
  return a:event == 'stdout' ?
    \ s:job_cb('s:job_out_cb',  self, 0, join(a:data, "\n")) :
    \ s:job_cb('s:job_exit_cb', self, 0, a:data)
endfunction

function! s:spawn(name, cmd, opts)
  let job = { 'name': a:name, 'running': 1, 'error': 0, 'lines': [''],
            \ 'batchfile': (s:is_win && (s:nvim || s:vim8)) ? tempname().'.bat' : '',
            \ 'new': get(a:opts, 'new', 0) }
  let s:jobs[a:name] = job
  let cmd = has_key(a:opts, 'dir') ? s:with_cd(a:cmd, a:opts.dir) : a:cmd
  if !empty(job.batchfile)
    call writefile(["@echo off\r", cmd . "\r"], job.batchfile)
    let cmd = job.batchfile
  endif
  let argv = add(s:is_win ? ['cmd', '/c'] : ['sh', '-c'], cmd)

  if s:nvim
    call extend(job, {
    \ 'on_stdout': function('s:nvim_cb'),
    \ 'on_exit':   function('s:nvim_cb'),
    \ })
    let jid = jobstart(argv, job)
    if jid > 0
      let job.jobid = jid
    else
      let job.running = 0
      let job.error   = 1
      let job.lines   = [jid < 0 ? argv[0].' is not executable' :
            \ 'Invalid arguments (or job table is full)']
    endif
  elseif s:vim8
    let jid = job_start(s:is_win ? join(argv, ' ') : argv, {
    \ 'out_cb':   function('s:job_cb', ['s:job_out_cb',  job]),
    \ 'exit_cb':  function('s:job_cb', ['s:job_exit_cb', job]),
    \ 'out_mode': 'raw'
    \})
    if job_status(jid) == 'run'
      let job.jobid = jid
    else
      let job.running = 0
      let job.error   = 1
      let job.lines   = ['Failed to start job']
    endif
  else
    let job.lines = s:lines(call('s:system', [cmd]))
    let job.error = v:shell_error != 0
    let job.running = 0
  endif
endfunction

function! s:reap(name)
  let job = s:jobs[a:name]
  if job.error
    call add(s:update.errors, a:name)
  elseif get(job, 'new', 0)
    let s:update.new[a:name] = 1
  endif
  let s:update.bar .= job.error ? 'x' : '='

  let bullet = job.error ? 'x' : '-'
  let result = job.error ? join(job.lines, "\n") : s:last_non_empty_line(job.lines)
  call s:log(bullet, a:name, empty(result) ? 'OK' : result)
  call s:bar()

  if has_key(job, 'batchfile') && !empty(job.batchfile)
    call delete(job.batchfile)
  endif
  call remove(s:jobs, a:name)
endfunction

function! s:bar()
  if s:switch_in()
    let total = len(s:update.all)
    call setline(1, (s:update.pull ? 'Updating' : 'Installing').
          \ ' plugins ('.len(s:update.bar).'/'.total.')')
    call s:progress_bar(2, s:update.bar, total)
    call s:switch_out()
  endif
endfunction

function! s:logpos(name)
  for i in range(4, line('$'))
    if getline(i) =~# '^[-+x*] '.a:name.':'
      for j in range(i + 1, line('$'))
        if getline(j) !~ '^ '
          return [i, j - 1]
        endif
      endfor
      return [i, i]
    endif
  endfor
  return [0, 0]
endfunction

function! s:log(bullet, name, lines)
  if s:switch_in()
    let [b, e] = s:logpos(a:name)
    if b > 0
      silent execute printf('%d,%d d _', b, e)
      if b > winheight('.')
        let b = 4
      endif
    else
      let b = 4
    endif
    " FIXME For some reason, nomodifiable is set after :d in vim8
    setlocal modifiable
    call append(b - 1, s:format_message(a:bullet, a:name, a:lines))
    call s:switch_out()
  endif
endfunction

function! s:update_vim()
  let s:jobs = {}

  call s:bar()
  call s:tick()
endfunction

function! s:tick()
  let pull = s:update.pull
  let prog = s:progress_opt(s:nvim || s:vim8)
while 1 " Without TCO, Vim stack is bound to explode
  if empty(s:update.todo)
    if empty(s:jobs) && !s:update.fin
      call s:update_finish()
      let s:update.fin = 1
    endif
    return
  endif

  let name = keys(s:update.todo)[0]
  let spec = remove(s:update.todo, name)
  let new  = !isdirectory(spec.dir)

  call s:log(new ? '+' : '*', name, pull ? 'Updating ...' : 'Installing ...')
  redraw

  let has_tag = has_key(spec, 'tag')
  if !new
    let [error, _] = s:git_validate(spec, 0)
    if empty(error)
      if pull
        let fetch_opt = (has_tag && !empty(globpath(spec.dir, '.git/shallow'))) ? '--depth 99999999' : ''
        call s:spawn(name, printf('git fetch %s %s 2>&1', fetch_opt, prog), { 'dir': spec.dir })
      else
        let s:jobs[name] = { 'running': 0, 'lines': ['Already installed'], 'error': 0 }
      endif
    else
      let s:jobs[name] = { 'running': 0, 'lines': s:lines(error), 'error': 1 }
    endif
  else
    call s:spawn(name,
          \ printf('git clone %s %s %s %s 2>&1',
          \ has_tag ? '' : s:clone_opt,
          \ prog,
          \ s:shellesc(spec.uri),
          \ s:shellesc(s:trim(spec.dir))), { 'new': 1 })
  endif

  if !s:jobs[name].running
    call s:reap(name)
  endif
  if len(s:jobs) >= s:update.threads
    break
  endif
endwhile
endfunction

function! s:update_python()
let py_exe = has('python') ? 'python' : 'python3'
execute py_exe "<< EOF"
import datetime
import functools
import os
try:
  import queue
except ImportError:
  import Queue as queue
import random
import re
import shutil
import signal
import subprocess
import tempfile
import threading as thr
import time
import traceback
import vim

G_NVIM = vim.eval("has('nvim')") == '1'
G_PULL = vim.eval('s:update.pull') == '1'
G_RETRIES = int(vim.eval('get(g:, "plug_retries", 2)')) + 1
G_TIMEOUT = int(vim.eval('get(g:, "plug_timeout", 60)'))
G_CLONE_OPT = vim.eval('s:clone_opt')
G_PROGRESS = vim.eval('s:progress_opt(1)')
G_LOG_PROB = 1.0 / int(vim.eval('s:update.threads'))
G_STOP = thr.Event()
G_IS_WIN = vim.eval('s:is_win') == '1'

class PlugError(Exception):
  def __init__(self, msg):
    self.msg = msg
class CmdTimedOut(PlugError):
  pass
class CmdFailed(PlugError):
  pass
class InvalidURI(PlugError):
  pass
class Action(object):
  INSTALL, UPDATE, ERROR, DONE = ['+', '*', 'x', '-']

class Buffer(object):
  def __init__(self, lock, num_plugs, is_pull):
    self.bar = ''
    self.event = 'Updating' if is_pull else 'Installing'
    self.lock = lock
    self.maxy = int(vim.eval('winheight(".")'))
    self.num_plugs = num_plugs

  def __where(self, name):
    """ Find first line with name in current buffer. Return line num. """
    found, lnum = False, 0
    matcher = re.compile('^[-+x*] {0}:'.format(name))
    for line in vim.current.buffer:
      if matcher.search(line) is not None:
        found = True
        break
      lnum += 1

    if not found:
      lnum = -1
    return lnum

  def header(self):
    curbuf = vim.current.buffer
    curbuf[0] = self.event + ' plugins ({0}/{1})'.format(len(self.bar), self.num_plugs)

    num_spaces = self.num_plugs - len(self.bar)
    curbuf[1] = '[{0}{1}]'.format(self.bar, num_spaces * ' ')

    with self.lock:
      vim.command('normal! 2G')
      vim.command('redraw')

  def write(self, action, name, lines):
    first, rest = lines[0], lines[1:]
    msg = ['{0} {1}{2}{3}'.format(action, name, ': ' if first else '', first)]
    msg.extend(['    ' + line for line in rest])

    try:
      if action == Action.ERROR:
        self.bar += 'x'
        vim.command("call add(s:update.errors, '{0}')".format(name))
      elif action == Action.DONE:
        self.bar += '='

      curbuf = vim.current.buffer
      lnum = self.__where(name)
      if lnum != -1: # Found matching line num
        del curbuf[lnum]
        if lnum > self.maxy and action in set([Action.INSTALL, Action.UPDATE]):
          lnum = 3
      else:
        lnum = 3
      curbuf.append(msg, lnum)

      self.header()
    except vim.error:
      pass

class Command(object):
  CD = 'cd /d' if G_IS_WIN else 'cd'

  def __init__(self, cmd, cmd_dir=None, timeout=60, cb=None, clean=None):
    self.cmd = cmd
    if cmd_dir:
      self.cmd = '{0} {1} && {2}'.format(Command.CD, cmd_dir, self.cmd)
    self.timeout = timeout
    self.callback = cb if cb else (lambda msg: None)
    self.clean = clean if clean else (lambda: None)
    self.proc = None

  @property
  def alive(self):
    """ Returns true only if command still running. """
    return self.proc and self.proc.poll() is None

  def execute(self, ntries=3):
    """ Execute the command with ntries if CmdTimedOut.
        Returns the output of the command if no Exception.
    """
    attempt, finished, limit = 0, False, self.timeout

    while not finished:
      try:
        attempt += 1
        result = self.try_command()
        finished = True
        return result
      except CmdTimedOut:
        if attempt != ntries:
          self.notify_retry()
          self.timeout += limit
        else:
          raise

  def notify_retry(self):
    """ Retry required for command, notify user. """
    for count in range(3, 0, -1):
      if G_STOP.is_set():
        raise KeyboardInterrupt
      msg = 'Timeout. Will retry in {0} second{1} ...'.format(
            count, 's' if count != 1 else '')
      self.callback([msg])
      time.sleep(1)
    self.callback(['Retrying ...'])

  def try_command(self):
    """ Execute a cmd & poll for callback. Returns list of output.
        Raises CmdFailed   -> return code for Popen isn't 0
        Raises CmdTimedOut -> command exceeded timeout without new output
    """
    first_line = True

    try:
      tfile = tempfile.NamedTemporaryFile(mode='w+b')
      preexec_fn = not G_IS_WIN and os.setsid or None
      self.proc = subprocess.Popen(self.cmd, stdout=tfile,
                                   stderr=subprocess.STDOUT,
                                   stdin=subprocess.PIPE, shell=True,
                                   preexec_fn=preexec_fn)
      thrd = thr.Thread(target=(lambda proc: proc.wait()), args=(self.proc,))
      thrd.start()

      thread_not_started = True
      while thread_not_started:
        try:
          thrd.join(0.1)
          thread_not_started = False
        except RuntimeError:
          pass

      while self.alive:
        if G_STOP.is_set():
          raise KeyboardInterrupt

        if first_line or random.random() < G_LOG_PROB:
          first_line = False
          line = '' if G_IS_WIN else nonblock_read(tfile.name)
          if line:
            self.callback([line])

        time_diff = time.time() - os.path.getmtime(tfile.name)
        if time_diff > self.timeout:
          raise CmdTimedOut(['Timeout!'])

        thrd.join(0.5)

      tfile.seek(0)
      result = [line.decode('utf-8', 'replace').rstrip() for line in tfile]

      if self.proc.returncode != 0:
        raise CmdFailed([''] + result)

      return result
    except:
      self.terminate()
      raise

  def terminate(self):
    """ Terminate process and cleanup. """
    if self.alive:
      if G_IS_WIN:
        os.kill(self.proc.pid, signal.SIGINT)
      else:
        os.killpg(self.proc.pid, signal.SIGTERM)
    self.clean()

class Plugin(object):
  def __init__(self, name, args, buf_q, lock):
    self.name = name
    self.args = args
    self.buf_q = buf_q
    self.lock = lock
    self.tag = args.get('tag', 0)

  def manage(self):
    try:
      if os.path.exists(self.args['dir']):
        self.update()
      else:
        self.install()
        with self.lock:
          thread_vim_command("let s:update.new['{0}'] = 1".format(self.name))
    except PlugError as exc:
      self.write(Action.ERROR, self.name, exc.msg)
    except KeyboardInterrupt:
      G_STOP.set()
      self.write(Action.ERROR, self.name, ['Interrupted!'])
    except:
      # Any exception except those above print stack trace
      msg = 'Trace:\n{0}'.format(traceback.format_exc().rstrip())
      self.write(Action.ERROR, self.name, msg.split('\n'))
      raise

  def install(self):
    target = self.args['dir']
    if target[-1] == '\\':
      target = target[0:-1]

    def clean(target):
      def _clean():
        try:
          shutil.rmtree(target)
        except OSError:
          pass
      return _clean

    self.write(Action.INSTALL, self.name, ['Installing ...'])
    callback = functools.partial(self.write, Action.INSTALL, self.name)
    cmd = 'git clone {0} {1} {2} {3} 2>&1'.format(
          '' if self.tag else G_CLONE_OPT, G_PROGRESS, self.args['uri'],
          esc(target))
    com = Command(cmd, None, G_TIMEOUT, callback, clean(target))
    result = com.execute(G_RETRIES)
    self.write(Action.DONE, self.name, result[-1:])

  def repo_uri(self):
    cmd = 'git rev-parse --abbrev-ref HEAD 2>&1 && git config -f .git/config remote.origin.url'
    command = Command(cmd, self.args['dir'], G_TIMEOUT,)
    result = command.execute(G_RETRIES)
    return result[-1]

  def update(self):
    actual_uri = self.repo_uri()
    expect_uri = self.args['uri']
    regex = re.compile(r'^(?:\w+://)?(?:[^@/]*@)?([^:/]*(?::[0-9]*)?)[:/](.*?)(?:\.git)?/?$')
    ma = regex.match(actual_uri)
    mb = regex.match(expect_uri)
    if ma is None or mb is None or ma.groups() != mb.groups():
      msg = ['',
             'Invalid URI: {0}'.format(actual_uri),
             'Expected     {0}'.format(expect_uri),
             'PlugClean required.']
      raise InvalidURI(msg)

    if G_PULL:
      self.write(Action.UPDATE, self.name, ['Updating ...'])
      callback = functools.partial(self.write, Action.UPDATE, self.name)
      fetch_opt = '--depth 99999999' if self.tag and os.path.isfile(os.path.join(self.args['dir'], '.git/shallow')) else ''
      cmd = 'git fetch {0} {1} 2>&1'.format(fetch_opt, G_PROGRESS)
      com = Command(cmd, self.args['dir'], G_TIMEOUT, callback)
      result = com.execute(G_RETRIES)
      self.write(Action.DONE, self.name, result[-1:])
    else:
      self.write(Action.DONE, self.name, ['Already installed'])

  def write(self, action, name, msg):
    self.buf_q.put((action, name, msg))

class PlugThread(thr.Thread):
  def __init__(self, tname, args):
    super(PlugThread, self).__init__()
    self.tname = tname
    self.args = args

  def run(self):
    thr.current_thread().name = self.tname
    buf_q, work_q, lock = self.args

    try:
      while not G_STOP.is_set():
        name, args = work_q.get_nowait()
        plug = Plugin(name, args, buf_q, lock)
        plug.manage()
        work_q.task_done()
    except queue.Empty:
      pass

class RefreshThread(thr.Thread):
  def __init__(self, lock):
    super(RefreshThread, self).__init__()
    self.lock = lock
    self.running = True

  def run(self):
    while self.running:
      with self.lock:
        thread_vim_command('noautocmd normal! a')
      time.sleep(0.33)

  def stop(self):
    self.running = False

if G_NVIM:
  def thread_vim_command(cmd):
    vim.session.threadsafe_call(lambda: vim.command(cmd))
else:
  def thread_vim_command(cmd):
    vim.command(cmd)

def esc(name):
  return '"' + name.replace('"', '\"') + '"'

def nonblock_read(fname):
  """ Read a file with nonblock flag. Return the last line. """
  fread = os.open(fname, os.O_RDONLY | os.O_NONBLOCK)
  buf = os.read(fread, 100000).decode('utf-8', 'replace')
  os.close(fread)

  line = buf.rstrip('\r\n')
  left = max(line.rfind('\r'), line.rfind('\n'))
  if left != -1:
    left += 1
    line = line[left:]

  return line

def main():
  thr.current_thread().name = 'main'
  nthreads = int(vim.eval('s:update.threads'))
  plugs = vim.eval('s:update.todo')
  mac_gui = vim.eval('s:mac_gui') == '1'

  lock = thr.Lock()
  buf = Buffer(lock, len(plugs), G_PULL)
  buf_q, work_q = queue.Queue(), queue.Queue()
  for work in plugs.items():
    work_q.put(work)

  start_cnt = thr.active_count()
  for num in range(nthreads):
    tname = 'PlugT-{0:02}'.format(num)
    thread = PlugThread(tname, (buf_q, work_q, lock))
    thread.start()
  if mac_gui:
    rthread = RefreshThread(lock)
    rthread.start()

  while not buf_q.empty() or thr.active_count() != start_cnt:
    try:
      action, name, msg = buf_q.get(True, 0.25)
      buf.write(action, name, ['OK'] if not msg else msg)
      buf_q.task_done()
    except queue.Empty:
      pass
    except KeyboardInterrupt:
      G_STOP.set()

  if mac_gui:
    rthread.stop()
    rthread.join()

main()
EOF
endfunction

function! s:update_ruby()
  ruby << EOF
  module PlugStream
    SEP = ["\r", "\n", nil]
    def get_line
      buffer = ''
      loop do
        char = readchar rescue return
        if SEP.include? char.chr
          buffer << $/
          break
        else
          buffer << char
        end
      end
      buffer
    end
  end unless defined?(PlugStream)

  def esc arg
    %["#{arg.gsub('"', '\"')}"]
  end

  def killall pid
    pids = [pid]
    if /mswin|mingw|bccwin/ =~ RUBY_PLATFORM
      pids.each { |pid| Process.kill 'INT', pid.to_i rescue nil }
    else
      unless `which pgrep 2> /dev/null`.empty?
        children = pids
        until children.empty?
          children = children.map { |pid|
            `pgrep -P #{pid}`.lines.map { |l| l.chomp }
          }.flatten
          pids += children
        end
      end
      pids.each { |pid| Process.kill 'TERM', pid.to_i rescue nil }
    end
  end

  def compare_git_uri a, b
    regex = %r{^(?:\w+://)?(?:[^@/]*@)?([^:/]*(?::[0-9]*)?)[:/](.*?)(?:\.git)?/?$}
    regex.match(a).to_a.drop(1) == regex.match(b).to_a.drop(1)
  end

  require 'thread'
  require 'fileutils'
  require 'timeout'
  running = true
  iswin = VIM::evaluate('s:is_win').to_i == 1
  pull  = VIM::evaluate('s:update.pull').to_i == 1
  base  = VIM::evaluate('g:plug_home')
  all   = VIM::evaluate('s:update.todo')
  limit = VIM::evaluate('get(g:, "plug_timeout", 60)')
  tries = VIM::evaluate('get(g:, "plug_retries", 2)') + 1
  nthr  = VIM::evaluate('s:update.threads').to_i
  maxy  = VIM::evaluate('winheight(".")').to_i
  vim7  = VIM::evaluate('v:version').to_i <= 703 && RUBY_PLATFORM =~ /darwin/
  cd    = iswin ? 'cd /d' : 'cd'
  tot   = VIM::evaluate('len(s:update.todo)') || 0
  bar   = ''
  skip  = 'Already installed'
  mtx   = Mutex.new
  take1 = proc { mtx.synchronize { running && all.shift } }
  logh  = proc {
    cnt = bar.length
    $curbuf[1] = "#{pull ? 'Updating' : 'Installing'} plugins (#{cnt}/#{tot})"
    $curbuf[2] = '[' + bar.ljust(tot) + ']'
    VIM::command('normal! 2G')
    VIM::command('redraw')
  }
  where = proc { |name| (1..($curbuf.length)).find { |l| $curbuf[l] =~ /^[-+x*] #{name}:/ } }
  log   = proc { |name, result, type|
    mtx.synchronize do
      ing  = ![true, false].include?(type)
      bar += type ? '=' : 'x' unless ing
      b = case type
          when :install  then '+' when :update then '*'
          when true, nil then '-' else
            VIM::command("call add(s:update.errors, '#{name}')")
            'x'
          end
      result =
        if type || type.nil?
          ["#{b} #{name}: #{result.lines.to_a.last || 'OK'}"]
        elsif result =~ /^Interrupted|^Timeout/
          ["#{b} #{name}: #{result}"]
        else
          ["#{b} #{name}"] + result.lines.map { |l| "    " << l }
        end
      if lnum = where.call(name)
        $curbuf.delete lnum
        lnum = 4 if ing && lnum > maxy
      end
      result.each_with_index do |line, offset|
        $curbuf.append((lnum || 4) - 1 + offset, line.gsub(/\e\[./, '').chomp)
      end
      logh.call
    end
  }
  bt = proc { |cmd, name, type, cleanup|
    tried = timeout = 0
    begin
      tried += 1
      timeout += limit
      fd = nil
      data = ''
      if iswin
        Timeout::timeout(timeout) do
          tmp = VIM::evaluate('tempname()')
          system("(#{cmd}) > #{tmp}")
          data = File.read(tmp).chomp
          File.unlink tmp rescue nil
        end
      else
        fd = IO.popen(cmd).extend(PlugStream)
        first_line = true
        log_prob = 1.0 / nthr
        while line = Timeout::timeout(timeout) { fd.get_line }
          data << line
          log.call name, line.chomp, type if name && (first_line || rand < log_prob)
          first_line = false
        end
        fd.close
      end
      [$? == 0, data.chomp]
    rescue Timeout::Error, Interrupt => e
      if fd && !fd.closed?
        killall fd.pid
        fd.close
      end
      cleanup.call if cleanup
      if e.is_a?(Timeout::Error) && tried < tries
        3.downto(1) do |countdown|
          s = countdown > 1 ? 's' : ''
          log.call name, "Timeout. Will retry in #{countdown} second#{s} ...", type
          sleep 1
        end
        log.call name, 'Retrying ...', type
        retry
      end
      [false, e.is_a?(Interrupt) ? "Interrupted!" : "Timeout!"]
    end
  }
  main = Thread.current
  threads = []
  watcher = Thread.new {
    if vim7
      while VIM::evaluate('getchar(1)')
        sleep 0.1
      end
    else
      require 'io/console' # >= Ruby 1.9
      nil until IO.console.getch == 3.chr
    end
    mtx.synchronize do
      running = false
      threads.each { |t| t.raise Interrupt } unless vim7
    end
    threads.each { |t| t.join rescue nil }
    main.kill
  }
  refresh = Thread.new {
    while true
      mtx.synchronize do
        break unless running
        VIM::command('noautocmd normal! a')
      end
      sleep 0.2
    end
  } if VIM::evaluate('s:mac_gui') == 1

  clone_opt = VIM::evaluate('s:clone_opt')
  progress = VIM::evaluate('s:progress_opt(1)')
  nthr.times do
    mtx.synchronize do
      threads << Thread.new {
        while pair = take1.call
          name = pair.first
          dir, uri, tag = pair.last.values_at *%w[dir uri tag]
          exists = File.directory? dir
          ok, result =
            if exists
              chdir = "#{cd} #{iswin ? dir : esc(dir)}"
              ret, data = bt.call "#{chdir} && git rev-parse --abbrev-ref HEAD 2>&1 && git config -f .git/config remote.origin.url", nil, nil, nil
              current_uri = data.lines.to_a.last
              if !ret
                if data =~ /^Interrupted|^Timeout/
                  [false, data]
                else
                  [false, [data.chomp, "PlugClean required."].join($/)]
                end
              elsif !compare_git_uri(current_uri, uri)
                [false, ["Invalid URI: #{current_uri}",
                         "Expected:    #{uri}",
                         "PlugClean required."].join($/)]
              else
                if pull
                  log.call name, 'Updating ...', :update
                  fetch_opt = (tag && File.exist?(File.join(dir, '.git/shallow'))) ? '--depth 99999999' : ''
                  bt.call "#{chdir} && git fetch #{fetch_opt} #{progress} 2>&1", name, :update, nil
                else
                  [true, skip]
                end
              end
            else
              d = esc dir.sub(%r{[\\/]+$}, '')
              log.call name, 'Installing ...', :install
              bt.call "git clone #{clone_opt unless tag} #{progress} #{uri} #{d} 2>&1", name, :install, proc {
                FileUtils.rm_rf dir
              }
            end
          mtx.synchronize { VIM::command("let s:update.new['#{name}'] = 1") } if !exists && ok
          log.call name, result, ok
        end
      } if running
    end
  end
  threads.each { |t| t.join rescue nil }
  logh.call
  refresh.kill if refresh
  watcher.kill
EOF
endfunction

function! s:shellesc_cmd(arg)
  let escaped = substitute(a:arg, '[&|<>()@^]', '^&', 'g')
  let escaped = substitute(escaped, '%', '%%', 'g')
  let escaped = substitute(escaped, '"', '\\^&', 'g')
  let escaped = substitute(escaped, '\(\\\+\)\(\\^\)', '\1\1\2', 'g')
  return '^"'.substitute(escaped, '\(\\\+\)$', '\1\1', '').'^"'
endfunction

function! s:shellesc(arg)
  if &shell =~# 'cmd.exe$'
    return s:shellesc_cmd(a:arg)
  endif
  return shellescape(a:arg)
endfunction

function! s:glob_dir(path)
  return map(filter(s:glob(a:path, '**'), 'isdirectory(v:val)'), 's:dirpath(v:val)')
endfunction

function! s:progress_bar(line, bar, total)
  call setline(a:line, '[' . s:lpad(a:bar, a:total) . ']')
endfunction

function! s:compare_git_uri(a, b)
  " See `git help clone'
  " https:// [user@] github.com[:port] / junegunn/vim-plug [.git]
  "          [git@]  github.com[:port] : junegunn/vim-plug [.git]
  " file://                            / junegunn/vim-plug        [/]
  "                                    / junegunn/vim-plug        [/]
  let pat = '^\%(\w\+://\)\='.'\%([^@/]*@\)\='.'\([^:/]*\%(:[0-9]*\)\=\)'.'[:/]'.'\(.\{-}\)'.'\%(\.git\)\=/\?$'
  let ma = matchlist(a:a, pat)
  let mb = matchlist(a:b, pat)
  return ma[1:2] ==# mb[1:2]
endfunction

function! s:format_message(bullet, name, message)
  if a:bullet != 'x'
    return [printf('%s %s: %s', a:bullet, a:name, s:lastline(a:message))]
  else
    let lines = map(s:lines(a:message), '"    ".v:val')
    return extend([printf('x %s:', a:name)], lines)
  endif
endfunction

function! s:with_cd(cmd, dir)
  return printf('cd%s %s && %s', s:is_win ? ' /d' : '', s:shellesc(a:dir), a:cmd)
endfunction

function! s:system(cmd, ...)
  try
    let [sh, shellcmdflag, shrd] = s:chsh(1)
    let cmd = a:0 > 0 ? s:with_cd(a:cmd, a:1) : a:cmd
    if s:is_win
      let batchfile = tempname().'.bat'
      call writefile(["@echo off\r", cmd . "\r"], batchfile)
      let cmd = batchfile
    endif
    return system(s:is_win ? '('.cmd.')' : cmd)
  finally
    let [&shell, &shellcmdflag, &shellredir] = [sh, shellcmdflag, shrd]
    if s:is_win
      call delete(batchfile)
    endif
  endtry
endfunction

function! s:system_chomp(...)
  let ret = call('s:system', a:000)
  return v:shell_error ? '' : substitute(ret, '\n$', '', '')
endfunction

function! s:git_validate(spec, check_branch)
  let err = ''
  if isdirectory(a:spec.dir)
    let result = s:lines(s:system('git rev-parse --abbrev-ref HEAD 2>&1 && git config -f .git/config remote.origin.url', a:spec.dir))
    let remote = result[-1]
    if v:shell_error
      let err = join([remote, 'PlugClean required.'], "\n")
    elseif !s:compare_git_uri(remote, a:spec.uri)
      let err = join(['Invalid URI: '.remote,
                    \ 'Expected:    '.a:spec.uri,
                    \ 'PlugClean required.'], "\n")
    elseif a:check_branch && has_key(a:spec, 'commit')
      let result = s:lines(s:system('git rev-parse HEAD 2>&1', a:spec.dir))
      let sha = result[-1]
      if v:shell_error
        let err = join(add(result, 'PlugClean required.'), "\n")
      elseif !s:hash_match(sha, a:spec.commit)
        let err = join([printf('Invalid HEAD (expected: %s, actual: %s)',
                              \ a:spec.commit[:6], sha[:6]),
                      \ 'PlugUpdate required.'], "\n")
      endif
    elseif a:check_branch
      let branch = result[0]
      " Check tag
      if has_key(a:spec, 'tag')
        let tag = s:system_chomp('git describe --exact-match --tags HEAD 2>&1', a:spec.dir)
        if a:spec.tag !=# tag && a:spec.tag !~ '\*'
          let err = printf('Invalid tag: %s (expected: %s). Try PlugUpdate.',
                \ (empty(tag) ? 'N/A' : tag), a:spec.tag)
        endif
      " Check branch
      elseif a:spec.branch !=# branch
        let err = printf('Invalid branch: %s (expected: %s). Try PlugUpdate.',
              \ branch, a:spec.branch)
      endif
      if empty(err)
        let [ahead, behind] = split(s:lastline(s:system(printf(
              \ 'git rev-list --count --left-right HEAD...origin/%s',
              \ a:spec.branch), a:spec.dir)), '\t')
        if !v:shell_error && ahead
          if behind
            " Only mention PlugClean if diverged, otherwise it's likely to be
            " pushable (and probably not that messed up).
            let err = printf(
                  \ "Diverged from origin/%s (%d commit(s) ahead and %d commit(s) behind!\n"
                  \ .'Backup local changes and run PlugClean and PlugUpdate to reinstall it.', a:spec.branch, ahead, behind)
          else
            let err = printf("Ahead of origin/%s by %d commit(s).\n"
                  \ .'Cannot update until local changes are pushed.',
                  \ a:spec.branch, ahead)
          endif
        endif
      endif
    endif
  else
    let err = 'Not found'
  endif
  return [err, err =~# 'PlugClean']
endfunction

function! s:rm_rf(dir)
  if isdirectory(a:dir)
    call s:system((s:is_win ? 'rmdir /S /Q ' : 'rm -rf ') . s:shellesc(a:dir))
  endif
endfunction

function! s:clean(force)
  call s:prepare()
  call append(0, 'Searching for invalid plugins in '.g:plug_home)
  call append(1, '')

  " List of valid directories
  let dirs = []
  let errs = {}
  let [cnt, total] = [0, len(g:plugs)]
  for [name, spec] in items(g:plugs)
    if !s:is_managed(name)
      call add(dirs, spec.dir)
    else
      let [err, clean] = s:git_validate(spec, 1)
      if clean
        let errs[spec.dir] = s:lines(err)[0]
      else
        call add(dirs, spec.dir)
      endif
    endif
    let cnt += 1
    call s:progress_bar(2, repeat('=', cnt), total)
    normal! 2G
    redraw
  endfor

  let allowed = {}
  for dir in dirs
    let allowed[s:dirpath(fnamemodify(dir, ':h:h'))] = 1
    let allowed[dir] = 1
    for child in s:glob_dir(dir)
      let allowed[child] = 1
    endfor
  endfor

  let todo = []
  let found = sort(s:glob_dir(g:plug_home))
  while !empty(found)
    let f = remove(found, 0)
    if !has_key(allowed, f) && isdirectory(f)
      call add(todo, f)
      call append(line('$'), '- ' . f)
      if has_key(errs, f)
        call append(line('$'), '    ' . errs[f])
      endif
      let found = filter(found, 'stridx(v:val, f) != 0')
    end
  endwhile

  4
  redraw
  if empty(todo)
    call append(line('$'), 'Already clean.')
  else
    let s:clean_count = 0
    call append(3, ['Directories to delete:', ''])
    redraw!
    if a:force || s:ask_no_interrupt('Delete all directories?')
      call s:delete([6, line('$')], 1)
    else
      call setline(4, 'Cancelled.')
      nnoremap <silent> <buffer> d :set opfunc=<sid>delete_op<cr>g@
      nmap     <silent> <buffer> dd d_
      xnoremap <silent> <buffer> d :<c-u>call <sid>delete_op(visualmode(), 1)<cr>
      echo 'Delete the lines (d{motion}) to delete the corresponding directories'
    endif
  endif
  4
  setlocal nomodifiable
endfunction

function! s:delete_op(type, ...)
  call s:delete(a:0 ? [line("'<"), line("'>")] : [line("'["), line("']")], 0)
endfunction

function! s:delete(range, force)
  let [l1, l2] = a:range
  let force = a:force
  while l1 <= l2
    let line = getline(l1)
    if line =~ '^- ' && isdirectory(line[2:])
      execute l1
      redraw!
      let answer = force ? 1 : s:ask('Delete '.line[2:].'?', 1)
      let force = force || answer > 1
      if answer
        call s:rm_rf(line[2:])
        setlocal modifiable
        call setline(l1, '~'.line[1:])
        let s:clean_count += 1
        call setline(4, printf('Removed %d directories.', s:clean_count))
        setlocal nomodifiable
      endif
    endif
    let l1 += 1
  endwhile
endfunction

function! s:upgrade()
  echo 'Downloading the latest version of vim-plug'
  redraw
  let tmp = tempname()
  let new = tmp . '/plug.vim'

  try
    let out = s:system(printf('git clone --depth 1 %s %s', s:plug_src, tmp))
    if v:shell_error
      return s:err('Error upgrading vim-plug: '. out)
    endif

    if readfile(s:me) ==# readfile(new)
      echo 'vim-plug is already up-to-date'
      return 0
    else
      call rename(s:me, s:me . '.old')
      call rename(new, s:me)
      unlet g:loaded_plug
      echo 'vim-plug has been upgraded'
      return 1
    endif
  finally
    silent! call s:rm_rf(tmp)
  endtry
endfunction

function! s:upgrade_specs()
  for spec in values(g:plugs)
    let spec.frozen = get(spec, 'frozen', 0)
  endfor
endfunction

function! s:status()
  call s:prepare()
  call append(0, 'Checking plugins')
  call append(1, '')

  let ecnt = 0
  let unloaded = 0
  let [cnt, total] = [0, len(g:plugs)]
  for [name, spec] in items(g:plugs)
    let is_dir = isdirectory(spec.dir)
    if has_key(spec, 'uri')
      if is_dir
        let [err, _] = s:git_validate(spec, 1)
        let [valid, msg] = [empty(err), empty(err) ? 'OK' : err]
      else
        let [valid, msg] = [0, 'Not found. Try PlugInstall.']
      endif
    else
      if is_dir
        let [valid, msg] = [1, 'OK']
      else
        let [valid, msg] = [0, 'Not found.']
      endif
    endif
    let cnt += 1
    let ecnt += !valid
    " `s:loaded` entry can be missing if PlugUpgraded
    if is_dir && get(s:loaded, name, -1) == 0
      let unloaded = 1
      let msg .= ' (not loaded)'
    endif
    call s:progress_bar(2, repeat('=', cnt), total)
    call append(3, s:format_message(valid ? '-' : 'x', name, msg))
    normal! 2G
    redraw
  endfor
  call setline(1, 'Finished. '.ecnt.' error(s).')
  normal! gg
  setlocal nomodifiable
  if unloaded
    echo "Press 'L' on each line to load plugin, or 'U' to update"
    nnoremap <silent> <buffer> L :call <SID>status_load(line('.'))<cr>
    xnoremap <silent> <buffer> L :call <SID>status_load(line('.'))<cr>
  end
endfunction

function! s:extract_name(str, prefix, suffix)
  return matchstr(a:str, '^'.a:prefix.' \zs[^:]\+\ze:.*'.a:suffix.'$')
endfunction

function! s:status_load(lnum)
  let line = getline(a:lnum)
  let name = s:extract_name(line, '-', '(not loaded)')
  if !empty(name)
    call plug#load(name)
    setlocal modifiable
    call setline(a:lnum, substitute(line, ' (not loaded)$', '', ''))
    setlocal nomodifiable
  endif
endfunction

function! s:status_update() range
  let lines = getline(a:firstline, a:lastline)
  let names = filter(map(lines, 's:extract_name(v:val, "[x-]", "")'), '!empty(v:val)')
  if !empty(names)
    echo
    execute 'PlugUpdate' join(names)
  endif
endfunction

function! s:is_preview_window_open()
  silent! wincmd P
  if &previewwindow
    wincmd p
    return 1
  endif
endfunction

function! s:find_name(lnum)
  for lnum in reverse(range(1, a:lnum))
    let line = getline(lnum)
    if empty(line)
      return ''
    endif
    let name = s:extract_name(line, '-', '')
    if !empty(name)
      return name
    endif
  endfor
  return ''
endfunction

function! s:preview_commit()
  if b:plug_preview < 0
    let b:plug_preview = !s:is_preview_window_open()
  endif

  let sha = matchstr(getline('.'), '^  \X*\zs[0-9a-f]\{7,9}')
  if empty(sha)
    return
  endif

  let name = s:find_name(line('.'))
  if empty(name) || !has_key(g:plugs, name) || !isdirectory(g:plugs[name].dir)
    return
  endif

  if exists('g:plug_pwindow') && !s:is_preview_window_open()
    execute g:plug_pwindow
    execute 'e' sha
  else
    execute 'pedit' sha
    wincmd P
  endif
  setlocal previewwindow filetype=git buftype=nofile nobuflisted modifiable
  try
    let [sh, shellcmdflag, shrd] = s:chsh(1)
    let cmd = 'cd '.s:shellesc(g:plugs[name].dir).' && git show --no-color --pretty=medium '.sha
    if s:is_win
      let batchfile = tempname().'.bat'
      call writefile(["@echo off\r", cmd . "\r"], batchfile)
      let cmd = batchfile
    endif
    execute 'silent %!' cmd
  finally
    let [&shell, &shellcmdflag, &shellredir] = [sh, shellcmdflag, shrd]
    if s:is_win
      call delete(batchfile)
    endif
  endtry
  setlocal nomodifiable
  nnoremap <silent> <buffer> q :q<cr>
  wincmd p
endfunction

function! s:section(flags)
  call search('\(^[x-] \)\@<=[^:]\+:', a:flags)
endfunction

function! s:format_git_log(line)
  let indent = '  '
  let tokens = split(a:line, nr2char(1))
  if len(tokens) != 5
    return indent.substitute(a:line, '\s*$', '', '')
  endif
  let [graph, sha, refs, subject, date] = tokens
  let tag = matchstr(refs, 'tag: [^,)]\+')
  let tag = empty(tag) ? ' ' : ' ('.tag.') '
  return printf('%s%s%s%s%s (%s)', indent, graph, sha, tag, subject, date)
endfunction

function! s:append_ul(lnum, text)
  call append(a:lnum, ['', a:text, repeat('-', len(a:text))])
endfunction

function! s:diff()
  call s:prepare()
  call append(0, ['Collecting changes ...', ''])
  let cnts = [0, 0]
  let bar = ''
  let total = filter(copy(g:plugs), 's:is_managed(v:key) && isdirectory(v:val.dir)')
  call s:progress_bar(2, bar, len(total))
  for origin in [1, 0]
    let plugs = reverse(sort(items(filter(copy(total), (origin ? '' : '!').'(has_key(v:val, "commit") || has_key(v:val, "tag"))'))))
    if empty(plugs)
      continue
    endif
    call s:append_ul(2, origin ? 'Pending updates:' : 'Last update:')
    for [k, v] in plugs
      let range = origin ? '..origin/'.v.branch : 'HEAD@{1}..'
      let diff = s:system_chomp('git log --graph --color=never '.join(map(['--pretty=format:%x01%h%x01%d%x01%s%x01%cr', range], 's:shellesc(v:val)')), v.dir)
      if !empty(diff)
        let ref = has_key(v, 'tag') ? (' (tag: '.v.tag.')') : has_key(v, 'commit') ? (' '.v.commit) : ''
        call append(5, extend(['', '- '.k.':'.ref], map(s:lines(diff), 's:format_git_log(v:val)')))
        let cnts[origin] += 1
      endif
      let bar .= '='
      call s:progress_bar(2, bar, len(total))
      normal! 2G
      redraw
    endfor
    if !cnts[origin]
      call append(5, ['', 'N/A'])
    endif
  endfor
  call setline(1, printf('%d plugin(s) updated.', cnts[0])
        \ . (cnts[1] ? printf(' %d plugin(s) have pending updates.', cnts[1]) : ''))

  if cnts[0] || cnts[1]
    nnoremap <silent> <buffer> <plug>(plug-preview) :silent! call <SID>preview_commit()<cr>
    if empty(maparg("\<cr>", 'n'))
      nmap <buffer> <cr> <plug>(plug-preview)
    endif
    if empty(maparg('o', 'n'))
      nmap <buffer> o <plug>(plug-preview)
    endif
  endif
  if cnts[0]
    nnoremap <silent> <buffer> X :call <SID>revert()<cr>
    echo "Press 'X' on each block to revert the update"
  endif
  normal! gg
  setlocal nomodifiable
endfunction

function! s:revert()
  if search('^Pending updates', 'bnW')
    return
  endif

  let name = s:find_name(line('.'))
  if empty(name) || !has_key(g:plugs, name) ||
    \ input(printf('Revert the update of %s? (y/N) ', name)) !~? '^y'
    return
  endif

  call s:system('git reset --hard HEAD@{1} && git checkout '.s:esc(g:plugs[name].branch).' --', g:plugs[name].dir)
  setlocal modifiable
  normal! "_dap
  setlocal nomodifiable
  echo 'Reverted'
endfunction

function! s:snapshot(force, ...) abort
  call s:prepare()
  setf vim
  call append(0, ['" Generated by vim-plug',
                \ '" '.strftime("%c"),
                \ '" :source this file in vim to restore the snapshot',
                \ '" or execute: vim -S snapshot.vim',
                \ '', '', 'PlugUpdate!'])
  1
  let anchor = line('$') - 3
  let names = sort(keys(filter(copy(g:plugs),
        \'has_key(v:val, "uri") && !has_key(v:val, "commit") && isdirectory(v:val.dir)')))
  for name in reverse(names)
    let sha = s:system_chomp('git rev-parse --short HEAD', g:plugs[name].dir)
    if !empty(sha)
      call append(anchor, printf("silent! let g:plugs['%s'].commit = '%s'", name, sha))
      redraw
    endif
  endfor

  if a:0 > 0
    let fn = expand(a:1)
    if filereadable(fn) && !(a:force || s:ask(a:1.' already exists. Overwrite?'))
      return
    endif
    call writefile(getline(1, '$'), fn)
    echo 'Saved as '.a:1
    silent execute 'e' s:esc(fn)
    setf vim
  endif
endfunction

function! s:split_rtp()
  return split(&rtp, '\\\@<!,')
endfunction

let s:first_rtp = s:escrtp(get(s:split_rtp(), 0, ''))
let s:last_rtp  = s:escrtp(get(s:split_rtp(), -1, ''))

if exists('g:plugs')
  let g:plugs_order = get(g:, 'plugs_order', keys(g:plugs))
  call s:upgrade_specs()
  call s:define_commands()
endif

let &cpo = s:cpo_save
unlet s:cpo_save
