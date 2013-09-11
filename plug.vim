" vim-plug: Vim plugin manager
" ============================
"
" Download plug.vim and put it in ~/.vim/autoload
"
"   mkdir -p ~/.vim/autoload
"   curl -fLo ~/.vim/autoload/plug.vim \
"     https://raw.github.com/junegunn/vim-plug/master/plug.vim
"
" Edit your .vimrc
"
"   call plug#init()
"
"   Plug 'junegunn/seoul256'
"   " Plug 'user/repo', 'branch_or_tag'
"   " ...
"
" Then :PlugInstall to install plugins. (default: ~/.vim/plugged)
" You can change the location of the plugins with plug#init(path) call.
"
"
" Copyright (c) 2013 Junegunn Choi
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

let s:plug_source = 'https://raw.github.com/junegunn/vim-plug/master/plug.vim'
let s:plug_win = 0
let s:is_win = has('win32') || has('win64')
let s:me = expand('<sfile>:p')

function! plug#init(...)
  set nocompatible
  filetype off
  filetype plugin indent on
  let home = a:0 > 0 ? fnamemodify(a:1, ':p') : (split(&rtp, ',')[0].'/plugged')
  if !isdirectory(home)
    try
      call mkdir(home, 'p')
    catch
      echoerr 'Invalid plug directory: '. home
      return
    endtry
  endif
  if !executable('git')
    echoerr "`git' executable not found. vim-plug requires git."
    return
  endif

  let g:plug_home = home
  let g:plug = {}

  command! -nargs=+ Plug        call s:add(<args>)
  command! -nargs=* PlugInstall call s:install(<f-args>)
  command! -nargs=* PlugUpdate  call s:update(<f-args>)
  command! -nargs=0 PlugClean   call s:clean()
  command! -nargs=0 PlugUpgrade if s:upgrade() | execute "source ". s:me | endif
endfunction

function! s:add(...)
  if a:0 == 1
    let [plugin, branch] = [a:1, 'master']
  elseif a:0 == 2
    let [plugin, branch] = a:000
  else
    echoerr "Invalid number of arguments (1..2)"
    return
  endif

  if plugin !~ '/'
    let plugin = 'vim-scripts/'. plugin
  endif

  let name = split(plugin, '/')[-1]
  let dir  = fnamemodify(join([g:plug_home, plugin, branch], '/'), ':p')
  let uri  = 'https://git:@github.com/' . plugin . '.git'
  let spec = { 'name': name, 'dir': dir, 'uri': uri, 'branch': branch }
  execute "set rtp+=".dir
  let g:plug[plugin] = spec
endfunction

function! s:install(...)
  call s:update_impl(0, a:000)
endfunction

function! s:update(...)
  call s:update_impl(1, a:000)
endfunction

function! s:apply()
  for spec in values(g:plug)
    let docd = join([spec.dir, 'doc'], '/')
    if isdirectory(docd)
      execute "helptags ". join([spec.dir, 'doc'], '/')
    endif
  endfor
  runtime! plugin/*.vim
  runtime! after/*.vim
  silent! source $MYVIMRC
endfunction

function! s:syntax()
  syntax clear
  syntax region plug1 start=/\%1l/ end=/\%2l/ contains=ALL
  syntax region plug2 start=/\%2l/ end=/\%3l/ contains=ALL
  syn match plugNumber /[0-9]\+[0-9.]*/ containedin=plug1
  syn match plugBracket /[[\]]/ containedin=plug2
  syn match plugDash /^-/
  syn match plugName /\(^- \)\@<=[^:]*/
  syn match plugError /^- [^:]\+: (x).*/
  hi def link plug1       Title
  hi def link plug2       Repeat
  hi def link plugBracket Structure
  hi def link plugNumber  Number
  hi def link plugDash    Special
  hi def link plugName    Label
  hi def link plugError   Error
endfunction

function! s:lpad(str, len)
  return a:str . repeat(' ', a:len - len(a:str))
endfunction

function! s:system(cmd)
  return split(system(a:cmd), '\n')[-1]
endfunction

function! s:prepare()
  execute s:plug_win . 'wincmd w'
  if exists('b:plug')
    %d
  else
    vertical topleft new
    noremap <silent> <buffer> q :q<cr>
    let b:plug = 1
    let s:plug_win = winnr()
    call s:assign_name()
  endif
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap cursorline
  setf vim-plug
  call s:syntax()
endfunction

function! s:assign_name()
  " Assign buffer name
  let prefix = '[Plugins]'
  let name   = prefix
  let idx    = 2
  while bufexists(name)
    let name = printf("%s (%s)", prefix, idx)
    let idx = idx + 1
  endwhile
  silent! execute "f ".fnameescape(name)
endfunction

function! s:finish()
  call append(line('$'), '')
  call append(line('$'), 'Finishing ... ')
  redraw
  call s:apply()
  call s:syntax()
  call setline(line('$'), getline(line('$')) . 'Done!')
  normal! G
endfunction

function! s:update_impl(pull, args)
  if has('ruby') && get(g:, 'plug_parallel', 1)
    let threads = min(
      \ [len(g:plug), len(a:args) > 0 ? a:args[0] : get(g:, 'plug_threads', 16)])
  else
    let threads = 1
  endif

  call s:prepare()
  call append(0, 'Updating plugins')
  call append(1, '['. s:lpad('', len(g:plug)) .']')
  normal! 2G
  redraw

  if threads > 1
    call s:update_parallel(a:pull, threads)
  else
    call s:update_serial(a:pull)
  endif
  call s:finish()
endfunction

function! s:update_serial(pull)
  let st = reltime()
  let base = g:plug_home
  let cnt = 0
  let total = len(g:plug)

  for [name, spec] in items(g:plug)
    let cnt += 1
    let d = shellescape(spec.dir)
    if isdirectory(spec.dir)
      execute 'cd '.spec.dir
      let result = a:pull ? s:system('git pull 2>&1') : 'Already installed'
      let error = a:pull ? v:shell_error != 0 : 0
    else
      if !isdirectory(base)
        call mkdir(base, 'p')
      endif
      execute 'cd '.base
      let result = s:system(
            \ printf('git clone --recursive %s -b %s %s 2>&1',
            \ shellescape(spec.uri), shellescape(spec.branch), d))
      let error = v:shell_error != 0
    endif
    cd -
    if error
      let result = '(x) ' . result
    endif
    call setline(1, "Updating plugins (".cnt."/".total.")")
    call setline(2, '[' . s:lpad(repeat('=', cnt), total) . ']')
    call append(line('$'), '- ' . name . ': ' . result)
    normal! 2G
    redraw
  endfor

  call setline(1, "Updated. Elapsed time: " . split(reltimestr(reltime(st)))[0] . ' sec.')
endfunction

function! s:update_parallel(pull, threads)
  ruby << EOF
  require 'thread'
  require 'fileutils'
  st    = Time.now
  cd    = VIM::evaluate('s:is_win').to_i == 1 ? 'cd /d' : 'cd'
  pull  = VIM::evaluate('a:pull').to_i == 1
  base  = VIM::evaluate('g:plug_home')
  all   = VIM::evaluate('g:plug')
  total = all.length
  cnt   = 0
  skip  = 'Already installed'
  mtx   = Mutex.new
  take1 = proc { mtx.synchronize { all.shift } }
  log   = proc { |name, result, ok|
    mtx.synchronize {
      result = '(x) ' + result unless ok
      result = "- #{name}: #{result}"
      $curbuf[1] = "Updating plugins (#{cnt += 1}/#{total})"
      $curbuf[2] = '[' + ('=' * cnt).ljust(total) + ']'
      $curbuf.append $curbuf.count, result
      VIM::command('normal! 2G')
      VIM::command('redraw')
    }
  }
  VIM::evaluate('a:threads').to_i.times.map { |i|
    Thread.new(i) do |ii|
      while pair = take1.call
        name, dir, uri, branch = pair.last.values_at *%w[name dir uri branch]
        result =
          if File.directory? dir
            pull ? `#{cd} #{dir} && git pull 2>&1` : skip
          else
            FileUtils.mkdir_p(base)
            `#{cd} #{base} && git clone --recursive #{uri} -b #{branch} #{dir} 2>&1`
          end.lines.to_a.last.strip
        log.call name, result, ($? == 0 || result == skip)
      end
    end
  }.each(&:join)
  $curbuf[1] = "Updated. Elapsed time: #{"%.6f" % (Time.now - st)} sec."
EOF
endfunction

function! s:path(path)
  return substitute(s:is_win ? substitute(a:path, '/', '\', 'g') : a:path,
        \ '[/\\]*$', '', '')
endfunction

function! s:glob_dir(path)
  return map(filter(split(globpath(a:path, '**'), '\n'), 'isdirectory(v:val)'), 's:path(v:val)')
endfunction

function! s:clean()
  call s:prepare()
  call append(0, 'Removing unused plugins in '.g:plug_home)

  " List of files
  let dirs = map(values(g:plug), 's:path(v:val.dir)')
  let alldirs = dirs +
        \ map(copy(dirs), 'fnamemodify(v:val, ":h")') +
        \ map(copy(dirs), 'fnamemodify(v:val, ":h:h")')
  for dir in dirs
    let alldirs += s:glob_dir(dir)
  endfor
  let allowed = {}
  for dir in alldirs
    let allowed[dir] = 1
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
    let yes = input("Proceed? (Y/N) ")
    call inputrestore()
    if yes =~? '^y'
      for dir in todo
        if isdirectory(dir)
          call system((s:is_win ? 'rmdir /S /Q ' : 'rm -rf ') . dir)
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
  if executable('curl')
    let mee = shellescape(s:me)
    let new = shellescape(s:me . '.new')
    echo "Downloading ". s:plug_source
    redraw
    let mv = s:is_win ? 'move /Y' : 'mv -f'
    call system(printf(
      \ "curl -fLo %s %s && ".mv." %s %s.old && ".mv." %s %s",
      \ new, s:plug_source, mee, mee, new, mee))
    if v:shell_error == 0
      unlet g:loaded_plug
      echo "Downloaded ". s:plug_source
      return 1
    else
      echoerr "Error upgrading vim-plug"
      return 0
    endif
  else
    echoerr "`curl' not found"
    return 0
  endif
endfunction

