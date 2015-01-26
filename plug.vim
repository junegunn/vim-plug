" vim-plug: Vim plugin manager
" ============================
"
" Download plug.vim and put it in ~/.vim/autoload
"
"   mkdir -p ~/.vim/autoload
"   curl -fLo ~/.vim/autoload/plug.vim \
"     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"
" Edit your .vimrc
"
"   call plug#begin('~/.vim/plugged')
"
"   " Make sure you use single quotes
"   Plug 'junegunn/seoul256.vim'
"   Plug 'junegunn/vim-easy-align'
"
"   " On-demand loading
"   Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
"   Plug 'tpope/vim-fireplace', { 'for': 'clojure' }
"
"   " Using git URL
"   Plug 'https://github.com/junegunn/vim-github-dashboard.git'
"
"   " Plugin options
"   Plug 'nsf/gocode', { 'tag': 'go.weekly.2012-03-13', 'rtp': 'vim' }
"
"   " Plugin outside ~/.vim/plugged with post-update hook
"   Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install' }
"
"   " Unmanaged plugin (manually installed and updated)
"   Plug '~/my-prototype-plugin'
"
"   call plug#end()
"
" Then reload .vimrc and :PlugInstall to install plugins.
" Visit https://github.com/junegunn/vim-plug for more information.
"
"
" Copyright (c) 2014 Junegunn Choi
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

let s:plug_src = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
let s:plug_tab = get(s:, 'plug_tab', -1)
let s:plug_buf = get(s:, 'plug_buf', -1)
let s:mac_gui = has('gui_macvim') && has('gui_running')
let s:is_win = has('win32') || has('win64')
let s:nvim = has('nvim') && !s:is_win
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

  let g:plug_home = home
  let g:plugs = {}
  let g:plugs_order = []
  let s:triggers = {}

  call s:define_commands()
  return 1
endfunction

function! s:define_commands()
  command! -nargs=+ -bar Plug call s:add(<args>)
  if !executable('git')
    return s:err('`git` executable not found. vim-plug requires git.')
  endif
  command! -nargs=* -bar -bang -complete=customlist,s:names PlugInstall call s:install('<bang>' == '!', [<f-args>])
  command! -nargs=* -bar -bang -complete=customlist,s:names PlugUpdate  call s:update('<bang>' == '!', [<f-args>])
  command! -nargs=0 -bar -bang PlugClean call s:clean('<bang>' == '!')
  command! -nargs=0 -bar PlugUpgrade if s:upgrade() | execute 'source' s:me | endif
  command! -nargs=0 -bar PlugStatus  call s:status()
  command! -nargs=0 -bar PlugDiff    call s:diff()
  command! -nargs=? -bar PlugSnapshot call s:snapshot(<f-args>)
endfunction

function! s:to_a(v)
  return type(a:v) == s:TYPE.list ? a:v : [a:v]
endfunction

function! s:to_s(v)
  return type(a:v) == s:TYPE.string ? a:v : join(a:v, "\n") . "\n"
endfunction

function! s:source(from, ...)
  for pattern in a:000
    for vim in s:lines(globpath(a:from, pattern))
      execute 'source' vim
    endfor
  endfor
endfunction

function! s:assoc(dict, key, val)
  let a:dict[a:key] = add(get(a:dict, a:key, []), a:val)
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

  filetype off
  for name in g:plugs_order
    let plug = g:plugs[name]
    if get(s:loaded, name, 0) || !has_key(plug, 'on') && !has_key(plug, 'for')
      let s:loaded[name] = 1
      continue
    endif

    if has_key(plug, 'on')
      let s:triggers[name] = { 'map': [], 'cmd': [] }
      for cmd in s:to_a(plug.on)
        if cmd =~ '^<Plug>.\+'
          if empty(mapcheck(cmd)) && empty(mapcheck(cmd, 'i'))
            call s:assoc(lod.map, cmd, name)
          endif
          call add(s:triggers[name].map, cmd)
        elseif cmd =~ '^[A-Z]'
          if exists(':'.cmd) != 2
            call s:assoc(lod.cmd, cmd, name)
          endif
          call add(s:triggers[name].cmd, cmd)
        endif
      endfor
    endif

    if has_key(plug, 'for')
      let types = s:to_a(plug.for)
      if !empty(types)
        call s:source(s:rtp(plug), 'ftdetect/**/*.vim', 'after/ftdetect/**/*.vim')
      endif
      for type in types
        call s:assoc(lod.ft, type, name)
      endfor
    endif
  endfor

  for [cmd, names] in items(lod.cmd)
    execute printf(
    \ 'command! -nargs=* -range -bang %s call s:lod_cmd(%s, "<bang>", <line1>, <line2>, <q-args>, %s)',
    \ cmd, string(cmd), string(names))
  endfor

  for [map, names] in items(lod.map)
    for [mode, map_prefix, key_prefix] in
          \ [['i', '<C-O>', ''], ['n', '', ''], ['v', '', 'gv'], ['o', '', '']]
      execute printf(
      \ '%snoremap <silent> %s %s:<C-U>call <SID>lod_map(%s, %s, "%s")<CR>',
      \ mode, map, map_prefix, string(map), string(names), key_prefix)
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
    syntax enable
  else
    call s:reload()
  endif
endfunction

function! s:loaded_names()
  return filter(copy(g:plugs_order), 'get(s:loaded, v:val, 0)')
endfunction

function! s:reload()
  for name in s:loaded_names()
    call s:source(s:rtp(g:plugs[name]), 'plugin/**/*.vim', 'after/plugin/**/*.vim')
  endfor
endfunction

function! s:trim(str)
  return substitute(a:str, '[\/]\+$', '', '')
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
    return a:repo =~? '^[a-z]:'
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
  echom a:msg
  echohl None
  return 0
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
  let afters   = filter(map(copy(rtps), 'globpath(v:val, "after")'), 'isdirectory(v:val)')
  let rtp      = join(map(rtps, 's:escrtp(v:val)'), ',')
                 \ . ','.s:middle.','
                 \ . join(map(afters, 's:escrtp(v:val)'), ',')
  let &rtp     = substitute(substitute(rtp, ',,*', ',', 'g'), '^,\|,$', '', 'g')
  let s:prtp   = &rtp

  if !empty(s:first_rtp)
    execute 'set rtp^='.s:first_rtp
    execute 'set rtp+='.s:last_rtp
  endif
endfunction

function! plug#load(...)
  if a:0 == 0
    return s:err('Argument missing: plugin name(s) required')
  endif
  if !exists('g:plugs')
    return s:err('plug#begin was not called')
  endif
  let unknowns = filter(copy(a:000), '!has_key(g:plugs, v:val)')
  if !empty(unknowns)
    let s = len(unknowns) > 1 ? 's' : ''
    return s:err(printf('Unknown plugin%s: %s', s, join(unknowns, ', ')))
  end
  for name in a:000
    call s:lod([name], ['ftdetect', 'after/ftdetect', 'plugin', 'after/plugin'])
  endfor
  doautocmd BufRead
  return 1
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

function! s:lod(names, types)
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
  endfor
endfunction

function! s:lod_ft(pat, names)
  call s:lod(a:names, ['plugin', 'after/plugin'])
  execute 'autocmd! PlugLOD FileType' a:pat
  doautocmd filetypeplugin FileType
  doautocmd filetypeindent FileType
endfunction

function! s:lod_cmd(cmd, bang, l1, l2, args, names)
  call s:lod(a:names, ['ftdetect', 'after/ftdetect', 'plugin', 'after/plugin'])
  execute printf('%s%s%s %s', (a:l1 == a:l2 ? '' : (a:l1.','.a:l2)), a:cmd, a:bang, a:args)
endfunction

function! s:lod_map(map, names, prefix)
  call s:lod(a:names, ['ftdetect', 'after/ftdetect', 'plugin', 'after/plugin'])
  let extra = ''
  while 1
    let c = getchar(0)
    if c == 0
      break
    endif
    let extra .= nr2char(c)
  endwhile
  call feedkeys(a:prefix . substitute(a:map, '^<Plug>', "\<Plug>", '') . extra)
endfunction

function! s:add(repo, ...)
  if a:0 > 1
    return s:err('Invalid number of arguments (1..2)')
  endif

  try
    let repo = s:trim(a:repo)
    let name = fnamemodify(repo, ':t:s?\.git$??')
    let spec = extend(s:infer_properties(name, repo),
                    \ a:0 == 1 ? s:parse_options(a:1) : s:base_spec)
    let g:plugs[name] = spec
    let g:plugs_order += [name]
    let s:loaded[name] = 0
  catch
    return s:err(v:exception)
  endtry
endfunction

function! s:parse_options(arg)
  let opts = copy(s:base_spec)
  let type = type(a:arg)
  if type == s:TYPE.string
    let opts.branch = a:arg
  elseif type == s:TYPE.dict
    call extend(opts, a:arg)
    if has_key(opts, 'tag')
      let opts.branch = remove(opts, 'tag')
    endif
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
        let repo = 'vim-scripts/'. repo
      endif
      let fmt = get(g:, 'plug_url_format', 'https://git::@github.com/%s.git')
      let uri = printf(fmt, repo)
    endif
    let dir = s:dirpath( fnamemodify(join([g:plug_home, a:name], '/'), ':p') )
    return { 'dir': dir, 'uri': uri }
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
    let docd = join([spec.dir, 'doc'], '/')
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
  syn match plugInstall /\(^+ \)\@<=[^:]*/
  syn match plugUpdate /\(^* \)\@<=[^:]*/
  syn match plugCommit /^  [0-9a-z]\{7} .*/ contains=plugRelDate,plugSha
  syn match plugSha /\(^  \)\@<=[0-9a-z]\{7}/ contained
  syn match plugRelDate /([^)]*)$/ contained
  syn match plugNotLoaded /(not loaded)$/
  syn match plugError /^x.*/
  syn keyword Function PlugInstall PlugStatus PlugUpdate PlugClean
  hi def link plug1       Title
  hi def link plug2       Repeat
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
  hi def link plugRelDate Comment
  hi def link plugSha     Identifier

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

function! s:prepare()
  call s:job_abort()
  if s:switch_in()
    silent %d _
  else
    call s:new_window()
    nnoremap <silent> <buffer> q  :if b:plug_preview==1<bar>pc<bar>endif<bar>echo<bar>q<cr>
    nnoremap <silent> <buffer> R  :silent! call <SID>retry()<cr>
    nnoremap <silent> <buffer> D  :PlugDiff<cr>
    nnoremap <silent> <buffer> S  :PlugStatus<cr>
    nnoremap <silent> <buffer> U  :call <SID>status_update()<cr>
    xnoremap <silent> <buffer> U  :call <SID>status_update()<cr>
    nnoremap <silent> <buffer> ]] :silent! call <SID>section('')<cr>
    nnoremap <silent> <buffer> [[ :silent! call <SID>section('b')<cr>
    let b:plug_preview = -1
    let s:plug_tab = tabpagenr()
    let s:plug_buf = winbufnr(0)
    call s:assign_name()
  endif
  silent! unmap <buffer> <cr>
  silent! unmap <buffer> L
  silent! unmap <buffer> X
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap cursorline modifiable
  setf vim-plug
  call s:syntax()
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

function! s:do(pull, force, todo)
  for [name, spec] in items(a:todo)
    if !isdirectory(spec.dir)
      continue
    endif
    let installed = has_key(s:update.new, name)
    let updated = installed ? 0 :
      \ (a:pull && !empty(s:system_chomp('git log --pretty=format:"%h" "HEAD...HEAD@{1}"', spec.dir)))
    if a:force || installed || updated
      execute 'cd' s:esc(spec.dir)
      call append(3, '- Post-update hook for '. name .' ... ')
      let type = type(spec.do)
      if type == s:TYPE.string
        try
          " FIXME: Escaping is incomplete. We could use shellescape with eval,
          "        but it won't work on Windows.
          let g:_plug_do = '!'.escape(spec.do, '#!%')
          execute "normal! :execute g:_plug_do\<cr>\<cr>"
        finally
          let result = v:shell_error ? ('Exit status: '.v:shell_error) : 'Done!'
          unlet g:_plug_do
        endtry
      elseif type == s:TYPE.funcref
        try
          let status = installed ? 'installed' : (updated ? 'updated' : 'unchanged')
          call spec.do({ 'name': name, 'status': status, 'force': a:force })
          let result = 'Done!'
        catch
          let result = 'Error: ' . v:exception
        endtry
      else
        let result = 'Error: Invalid type!'
      endif
      call setline(4, getline(4) . result)
      cd -
    endif
  endfor
endfunction

function! s:finish(pull)
  let new_frozen = len(filter(keys(s:update.new), 'g:plugs[v:val].frozen'))
  if new_frozen
    let s = new_frozen > 1 ? 's' : ''
    call append(3, printf('- Installed %d frozen plugin%s', new_frozen, s))
  endif
  call append(3, '- Finishing ... ')
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
                \ "v:val =~ '^- ' && stridx(v:val, 'Already up-to-date') < 0"))
    call add(msgs, "Press 'D' to see the updated changes.")
  endif
  echo join(msgs, ' ')
endfunction

function! s:retry()
  if empty(s:update.errors)
    return
  endif
  call s:update_impl(s:update.pull, s:update.force,
        \ extend(copy(s:update.errors), [s:update.threads]))
endfunction

function! s:is_managed(name)
  return has_key(g:plugs[a:name], 'uri')
endfunction

function! s:names(...)
  return sort(filter(keys(g:plugs), 'stridx(v:val, a:1) == 0 && s:is_managed(v:val)'))
endfunction

function! s:update_impl(pull, force, args) abort
  let args = copy(a:args)
  let threads = (len(args) > 0 && args[-1] =~ '^[1-9][0-9]*$') ?
                  \ remove(args, -1) : get(g:, 'plug_threads', 16)

  let managed = filter(copy(g:plugs), 's:is_managed(v:key)')
  let todo = empty(args) ? filter(managed, '!v:val.frozen || !isdirectory(v:val.dir)') :
                         \ filter(managed, 'index(args, v:key) >= 0')

  if empty(todo)
    echohl WarningMsg
    echo 'No plugin to '. (a:pull ? 'update' : 'install') . '.'
    echohl None
    return
  endif

  if !isdirectory(g:plug_home)
    try
      call mkdir(g:plug_home, 'p')
    catch
      return s:err(printf('Invalid plug directory: %s. '.
              \ 'Try to call plug#begin with a valid directory', g:plug_home))
    endtry
  endif

  let s:update = {
    \ 'start':   reltime(),
    \ 'all':     todo,
    \ 'todo':    copy(todo),
    \ 'errors':  [],
    \ 'pull':    a:pull,
    \ 'force':   a:force,
    \ 'new':     {},
    \ 'threads': (has('ruby') || s:nvim) ? min([len(todo), threads]) : 1,
    \ 'bar':     '',
    \ 'fin':     0
  \ }

  call s:prepare()
  call append(0, ['', ''])
  normal! 2G

  if has('ruby') && s:update.threads > 1
    try
      let imd = &imd
      if s:mac_gui
        set noimd
      endif
      call s:update_ruby()
    catch
      let lines = getline(4, '$')
      let printed = {}
      silent 4,$d _
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
  endif
endfunction

function! s:update_finish()
  if s:switch_in()
    call s:do(s:update.pull, s:update.force, filter(copy(s:update.all), 'has_key(v:val, "do")'))
    call s:finish(s:update.pull)
    call setline(1, 'Updated. Elapsed time: ' . split(reltimestr(reltime(s:update.start)))[0] . ' sec.')
    call s:switch_out('normal! gg')
  endif
endfunction

function! s:job_abort()
  if !s:nvim || !exists('s:jobs')
    return
  endif
  augroup PlugJobControl
    autocmd!
  augroup END
  for [name, j] in items(s:jobs)
    silent! call jobstop(j.jobid)
    if j.new
      call system('rm -rf ' . s:shellesc(g:plugs[name].dir))
    endif
  endfor
  let s:jobs = {}
endfunction

function! s:job_handler(name) abort
  if !s:plug_window_exists() " plug window closed
    return s:job_abort()
  endif

  if !has_key(s:jobs, a:name)
    return
  endif
  let job = s:jobs[a:name]

  if v:job_data[1] == 'exit'
    let job.running = 0
    if s:lastline(job.result) ==# 'Error'
      let job.error = 1
      let job.result = substitute(job.result, "Error[\r\n]$", '', '')
    endif
    call s:reap(a:name)
    call s:tick()
  else
    let job.result .= s:to_s(v:job_data[2])
    " To reduce the number of buffer updates
    let job.tick = get(job, 'tick', -1) + 1
    if job.tick % len(s:jobs) == 0
      call s:log(job.new ? '+' : '*', a:name, job.result)
    endif
  endif
endfunction

function! s:spawn(name, cmd, opts)
  let job = { 'running': 1, 'new': get(a:opts, 'new', 0),
            \ 'error': 0, 'result': '' }
  let s:jobs[a:name] = job

  if s:nvim
    let x = jobstart(a:name, 'sh', ['-c',
            \ (has_key(a:opts, 'dir') ? s:with_cd(a:cmd, a:opts.dir) : a:cmd)
            \ . ' || echo Error'])
    if x > 0
      let job.jobid = x
      augroup PlugJobControl
        execute 'autocmd JobActivity' a:name printf('call s:job_handler(%s)', string(a:name))
      augroup END
    else
      let job.running = 0
      let job.error   = 1
      let job.result  = x < 0 ? 'sh is not executable' :
            \ 'Invalid arguments (or job table is full)'
    endif
  else
    let params = has_key(a:opts, 'dir') ? [a:cmd, a:opts.dir] : [a:cmd]
    let job.result = call('s:system', params)
    let job.error = v:shell_error != 0
    let job.running = 0
  endif
endfunction

function! s:reap(name)
  if s:nvim
    silent! execute 'autocmd! PlugJobControl JobActivity' a:name
  endif

  let job = s:jobs[a:name]
  if job.error
    call add(s:update.errors, a:name)
  elseif get(job, 'new', 0)
    let s:update.new[a:name] = 1
  endif
  let s:update.bar .= job.error ? 'x' : '='

  call s:log(job.error ? 'x' : '-', a:name, job.result)
  call s:bar()

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
  for i in range(1, line('$'))
    if getline(i) =~# '^[-+x*] '.a:name.':'
      return i
    endif
  endfor
  return 0
endfunction

function! s:log(bullet, name, lines)
  if s:switch_in()
    let pos = s:logpos(a:name)
    if pos > 0
      execute pos 'd _'
      if pos > winheight('.')
        let pos = 4
      endif
    else
      let pos = 4
    endif
    call append(pos - 1, s:format_message(a:bullet, a:name, a:lines))
    call s:switch_out()
  endif
endfunction

function! s:update_vim()
  let s:jobs = {}

  call s:bar()
  call s:tick()
endfunction

function! s:tick()
while 1 " Without TCO, Vim stack is bound to explode
  if empty(s:update.todo)
    if empty(s:jobs) && !s:update.fin
      let s:update.fin = 1
      call s:update_finish()
    endif
    return
  endif

  let name = keys(s:update.todo)[0]
  let spec = remove(s:update.todo, name)
  let pull = s:update.pull
  let new  = !isdirectory(spec.dir)

  call s:log(new ? '+' : '*', name, pull ? 'Updating ...' : 'Installing ...')
  redraw

  if !new
    let [valid, msg] = s:git_valid(spec, 0)
    if valid
      if pull
        call s:spawn(name,
          \ printf('(git fetch --progress 2>&1 && git checkout -q %s 2>&1 && git merge --ff-only origin/%s 2>&1 && git submodule update --init --recursive 2>&1)',
          \ s:shellesc(spec.branch), s:shellesc(spec.branch)), { 'dir': spec.dir })
      else
        let s:jobs[name] = { 'running': 0, 'result': 'Already installed', 'error': 0 }
      endif
    else
      let s:jobs[name] = { 'running': 0, 'result': msg, 'error': 1 }
    endif
  else
    call s:spawn(name,
          \ printf('git clone --progress --recursive %s -b %s %s 2>&1',
          \ s:shellesc(spec.uri),
          \ s:shellesc(spec.branch),
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
    VIM::command('redraw') unless iswin
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
          ["#{b} #{name}: #{result.lines.to_a.last}"]
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
          system("#{cmd} > #{tmp}")
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
    while VIM::evaluate('getchar(1)')
      sleep 0.1
    end
    mtx.synchronize do
      running = false
      threads.each { |t| t.raise Interrupt }
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

  progress = iswin ? '' : '--progress'
  nthr.times do
    mtx.synchronize do
      threads << Thread.new {
        while pair = take1.call
          name = pair.first
          dir, uri, branch = pair.last.values_at *%w[dir uri branch]
          branch = esc branch
          subm = "git submodule update --init --recursive 2>&1"
          exists = File.directory? dir
          ok, result =
            if exists
              dir = esc dir
              ret, data = bt.call "#{cd} #{dir} && git rev-parse --abbrev-ref HEAD 2>&1 && git config remote.origin.url", nil, nil, nil
              current_uri = data.lines.to_a.last
              if !ret
                if data =~ /^Interrupted|^Timeout/
                  [false, data]
                else
                  [false, [data.chomp, "PlugClean required."].join($/)]
                end
              elsif current_uri.sub(/git::?@/, '') != uri.sub(/git::?@/, '')
                [false, ["Invalid URI: #{current_uri}",
                         "Expected:    #{uri}",
                         "PlugClean required."].join($/)]
              else
                if pull
                  log.call name, 'Updating ...', :update
                  bt.call "#{cd} #{dir} && (git fetch #{progress} 2>&1 && git checkout -q #{branch} 2>&1 && git merge --ff-only origin/#{branch} 2>&1 && #{subm})", name, :update, nil
                else
                  [true, skip]
                end
              end
            else
              d = esc dir.sub(%r{[\\/]+$}, '')
              log.call name, 'Installing ...', :install
              bt.call "git clone #{progress} --recursive #{uri} -b #{branch} #{d} 2>&1", name, :install, proc {
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

function! s:shellesc(arg)
  return '"'.substitute(a:arg, '"', '\\"', 'g').'"'
endfunction

function! s:glob_dir(path)
  return map(filter(s:lines(globpath(a:path, '**')), 'isdirectory(v:val)'), 's:dirpath(v:val)')
endfunction

function! s:progress_bar(line, bar, total)
  call setline(a:line, '[' . s:lpad(a:bar, a:total) . ']')
endfunction

function! s:compare_git_uri(a, b)
  let a = substitute(a:a, 'git:\{1,2}@', '', '')
  let b = substitute(a:b, 'git:\{1,2}@', '', '')
  return a ==# b
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
  return 'cd '.s:esc(a:dir).' && '.a:cmd
endfunction

function! s:system(cmd, ...)
  let cmd = a:0 > 0 ? s:with_cd(a:cmd, a:1) : a:cmd
  return system(s:is_win ? '('.cmd.')' : cmd)
endfunction

function! s:system_chomp(...)
  let ret = call('s:system', a:000)
  return v:shell_error ? '' : substitute(ret, '\n$', '', '')
endfunction

function! s:git_valid(spec, check_branch)
  let ret = 1
  let msg = 'OK'
  if isdirectory(a:spec.dir)
    let result = s:lines(s:system('git rev-parse --abbrev-ref HEAD 2>&1 && git config remote.origin.url', a:spec.dir))
    let remote = result[-1]
    if v:shell_error
      let msg = join([remote, 'PlugClean required.'], "\n")
      let ret = 0
    elseif !s:compare_git_uri(remote, a:spec.uri)
      let msg = join(['Invalid URI: '.remote,
                    \ 'Expected:    '.a:spec.uri,
                    \ 'PlugClean required.'], "\n")
      let ret = 0
    elseif a:check_branch
      let branch = result[0]
      if a:spec.branch !=# branch
        let tag = s:system_chomp('git describe --exact-match --tags HEAD 2>&1', a:spec.dir)
        if a:spec.branch !=# tag
          let msg = printf('Invalid branch/tag: %s (expected: %s). Try PlugUpdate.',
                \ (empty(tag) ? branch : tag), a:spec.branch)
          let ret = 0
        endif
      endif
    endif
  else
    let msg = 'Not found'
    let ret = 0
  endif
  return [ret, msg]
endfunction

function! s:clean(force)
  call s:prepare()
  call append(0, 'Searching for unused plugins in '.g:plug_home)
  call append(1, '')

  " List of valid directories
  let dirs = []
  let [cnt, total] = [0, len(g:plugs)]
  for [name, spec] in items(g:plugs)
    if !s:is_managed(name) || s:git_valid(spec, 0)[0]
      call add(dirs, spec.dir)
    endif
    let cnt += 1
    call s:progress_bar(2, repeat('=', cnt), total)
    normal! 2G
    redraw
  endfor

  let allowed = {}
  for dir in dirs
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
      let found = filter(found, 'stridx(v:val, f) != 0')
    end
  endwhile

  normal! G
  redraw
  if empty(todo)
    call append(line('$'), 'Already clean.')
  else
    call inputsave()
    let yes = a:force || (input('Proceed? (y/N) ') =~? '^y')
    call inputrestore()
    if yes
      for dir in todo
        if isdirectory(dir)
          call system((s:is_win ? 'rmdir /S /Q ' : 'rm -rf ') . s:shellesc(dir))
        endif
      endfor
      call append(line('$'), 'Removed.')
    else
      call append(line('$'), 'Cancelled.')
    endif
  endif
  normal! G
endfunction

function! s:upgrade()
  let new = s:me . '.new'
  echo 'Downloading '. s:plug_src
  redraw
  try
    if executable('curl')
      let output = system(printf('curl -fLo %s %s', s:shellesc(new), s:plug_src))
      if v:shell_error
        throw get(s:lines(output), -1, v:shell_error)
      endif
    elseif has('ruby')
      call s:upgrade_using_ruby(new)
    else
      return s:err('curl executable or ruby support not found')
    endif
  catch
    return s:err('Error upgrading vim-plug: '. v:exception)
  endtry

  if readfile(s:me) ==# readfile(new)
    echo 'vim-plug is already up-to-date'
    silent! call delete(new)
    return 0
  else
    call rename(s:me, s:me . '.old')
    call rename(new, s:me)
    unlet g:loaded_plug
    echo 'vim-plug has been upgraded'
    return 1
  endif
endfunction

function! s:upgrade_using_ruby(new)
  ruby << EOF
  require 'open-uri'
  File.open(VIM::evaluate('a:new'), 'w') do |f|
    f << open(VIM::evaluate('s:plug_src')).read
  end
EOF
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
    if has_key(spec, 'uri')
      if isdirectory(spec.dir)
        let [valid, msg] = s:git_valid(spec, 1)
      else
        let [valid, msg] = [0, 'Not found. Try PlugInstall.']
      endif
    else
      if isdirectory(spec.dir)
        let [valid, msg] = [1, 'OK']
      else
        let [valid, msg] = [0, 'Not found.']
      endif
    endif
    let cnt += 1
    let ecnt += !valid
    " `s:loaded` entry can be missing if PlugUpgraded
    if valid && get(s:loaded, name, -1) == 0
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
  return 0
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

  let sha = matchstr(getline('.'), '\(^  \)\@<=[0-9a-z]\{7}')
  if empty(sha)
    return
  endif

  let name = s:find_name(line('.'))
  if empty(name) || !has_key(g:plugs, name) || !isdirectory(g:plugs[name].dir)
    return
  endif

  execute 'pedit' sha
  wincmd P
  setlocal filetype=git buftype=nofile nobuflisted
  execute 'silent read !cd' s:esc(g:plugs[name].dir) '&& git show' sha
  normal! gg"_dd
  wincmd p
endfunction

function! s:section(flags)
  call search('\(^[x-] \)\@<=[^:]\+:', a:flags)
endfunction

function! s:diff()
  call s:prepare()
  call append(0, 'Collecting updated changes ...')
  normal! gg
  redraw

  let cnt = 0
  for [k, v] in items(g:plugs)
    if !isdirectory(v.dir) || !s:is_managed(k)
      continue
    endif

    let diff = s:system_chomp('git log --pretty=format:"%h %s (%cr)" "HEAD...HEAD@{1}"', v.dir)
    if !empty(diff)
      call append(1, '')
      call append(2, '- '.k.':')
      call append(3, map(s:lines(diff), '"  ". v:val'))
      let cnt += 1
      normal! gg
      redraw
    endif
  endfor

  call setline(1, cnt == 0 ? 'No updates.' : 'Last update:')
  nnoremap <silent> <buffer> <cr> :silent! call <SID>preview_commit()<cr>
  nnoremap <silent> <buffer> X    :call <SID>revert()<cr>
  normal! gg
  setlocal nomodifiable
  if cnt > 0
    echo "Press 'X' on each block to revert the update"
  endif
endfunction

function! s:revert()
  let name = s:find_name(line('.'))
  if empty(name) || !has_key(g:plugs, name) ||
    \ input(printf('Revert the update of %s? (y/N) ', name)) !~? '^y'
    return
  endif

  call s:system('git reset --hard HEAD@{1} && git checkout '.s:esc(g:plugs[name].branch), g:plugs[name].dir)
  setlocal modifiable
  normal! "_dap
  setlocal nomodifiable
  echo 'Reverted.'
endfunction

function! s:snapshot(...) abort
  let home = get(s:, 'plug_home_org', g:plug_home)
  let [type, var, header] = s:is_win ?
    \ ['dosbatch', '%PLUG_HOME%',
    \   ['@echo off', ':: Generated by vim-plug', ':: '.strftime("%c"), '',
    \    ':: Make sure to PlugUpdate first', '', 'set PLUG_HOME='.s:esc(home)]] :
    \ ['sh', '$PLUG_HOME',
    \   ['#!/bin/bash',  '# Generated by vim-plug', '# '.strftime("%c"), '',
    \    'vim +PlugUpdate +qa', '', 'PLUG_HOME='.s:esc(home)]]

  call s:prepare()
  execute 'setf' type
  call append(0, header)
  call append('$', '')
  1
  redraw

  let dirs = sort(map(values(filter(copy(g:plugs),
        \'has_key(v:val, "uri") && isdirectory(v:val.dir)')), 'v:val.dir'))
  let anchor = line('$') - 1
  for dir in reverse(dirs)
    let sha = s:system_chomp('git rev-parse --short HEAD', dir)
    if !empty(sha)
      call append(anchor, printf('cd %s && git reset --hard %s',
            \ substitute(dir, '^'.g:plug_home, var, ''), sha))
      redraw
    endif
  endfor

  if a:0 > 0
    let fn = s:esc(expand(a:1))
    call writefile(getline(1, '$'), fn)
    if !s:is_win | call system('chmod +x ' . fn) | endif
    echo 'Saved to '.a:1
    silent execute 'e' fn
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

