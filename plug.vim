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
"   call plug#begin()
"
"   Plug 'junegunn/seoul256.vim'
"   Plug 'junegunn/vim-easy-align'
"   " Plug 'user/repo1', 'branch_or_tag'
"   " Plug 'user/repo2', { 'rtp': 'vim/plugin/dir', 'branch': 'devel' }
"   " ...
"
"   call plug#end()
"
" Then :PlugInstall to install plugins. (default: ~/.vim/plugged)
" You can change the location of the plugins with plug#begin(path) call.
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
let s:plug_file = 'Plugfile'
let s:plug_win = 0
let s:is_win = has('win32') || has('win64')
let s:me = expand('<sfile>:p')

function! plug#begin(...)
  let home = a:0 > 0 ? fnamemodify(a:1, ':p') :
        \ get(g:, 'plug_home', split(&rtp, ',')[0].'/plugged')
  if !isdirectory(home)
    try
      call mkdir(home, 'p')
    catch
      echoerr 'Invalid plug directory: '. home
      return 0
    endtry
  endif
  if !executable('git')
    echoerr "`git' executable not found. vim-plug requires git."
    return 0
  endif

  let g:plug_home = home
  let g:plugs = {}

  command! -nargs=+ Plug        call s:add(1, <args>)
  command! -nargs=* PlugInstall call s:install(<f-args>)
  command! -nargs=* PlugUpdate  call s:update(<f-args>)
  command! -nargs=0 -bang PlugClean call s:clean('<bang>' == '!')
  command! -nargs=0 PlugUpgrade if s:upgrade() | execute "source ". s:me | endif
  command! -nargs=0 PlugStatus  call s:status()

  return 1
endfunction

function! plug#end()
  let keys = keys(g:plugs)
  while !empty(keys)
    let keys = keys(s:extend(keys))
  endwhile

  set nocompatible
  filetype off
  for plug in values(g:plugs)
    let rtp = s:rtp(plug)
    execute "set rtp^=".rtp
    if isdirectory(rtp.'after')
      execute "set rtp+=".rtp.'after'
    endif
  endfor
  filetype plugin indent on
  syntax on
endfunction

function! s:rtp(spec)
  let rtp = s:dirpath(a:spec.dir . get(a:spec, 'rtp', ''))
  if s:is_win
    let rtp = substitute(rtp, '\\*$', '', '')
  endif
  return rtp
endfunction

function! s:add(...)
  let force = a:1
  let opts = { 'branch': 'master' }
  if a:0 == 2
    let plugin = a:2
  elseif a:0 == 3
    let plugin = a:2
    if type(a:3) == 1
      let opts.branch = a:3
    elseif type(a:3) == 4
      call extend(opts, a:3)
    else
      echoerr "Invalid argument type (expected: string or dictionary)"
      return
    endif
  else
    echoerr "Invalid number of arguments (1..2)"
    return
  endif

  if plugin =~ ':'
    let uri = plugin
  else
    if plugin !~ '/'
      let plugin = 'vim-scripts/'. plugin
    endif
    let uri = 'https://git:@github.com/' . plugin . '.git'
  endif

  let name = substitute(split(plugin, '/')[-1], '\.git$', '', '')
  if !force && has_key(g:plugs, name) | return | endif

  let dir  = s:dirpath( fnamemodify(join([g:plug_home, name], '/'), ':p') )
  let spec = extend(opts, { 'dir': dir, 'uri': uri })
  let g:plugs[name] = spec
endfunction

function! s:install(...)
  call s:update_impl(0, a:000)
endfunction

function! s:update(...)
  call s:update_impl(1, a:000)
endfunction

function! s:apply()
  for spec in values(g:plugs)
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
  syn match plugNumber /[0-9]\+[0-9.]*/ containedin=plug1 contained
  syn match plugBracket /[[\]]/ containedin=plug2 contained
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
  let lines = split(system(a:cmd), '\n')
  return get(lines, -1, '')
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
  let threads = len(a:args) > 0 ? a:args[0] : get(g:, 'plug_threads', 16)

  call s:prepare()
  call append(0, a:pull ? 'Updating plugins' : 'Installing plugins')
  call append(1, '['. s:lpad('', len(g:plugs)) .']')
  normal! 2G
  redraw

  if has('ruby') && threads > 1
    call s:update_parallel(a:pull, threads)
  else
    call s:update_serial(a:pull)
  endif
  call s:finish()
endfunction

function! s:extend(names)
  let prev = copy(g:plugs)
  try
    command! -nargs=+ Plug call s:add(0, <args>)
    for name in a:names
      let plugfile = s:rtp(g:plugs[name]) . s:plug_file
      if filereadable(plugfile)
        execute "source ". plugfile
      endif
    endfor
  finally
    command! -nargs=+ Plug call s:add(1, <args>)
  endtry
  return filter(copy(g:plugs), '!has_key(prev, v:key)')
endfunction

function! s:update_progress(pull, cnt, total)
  call setline(1, (a:pull ? 'Updating' : 'Installing').
        \ " plugins (".a:cnt."/".a:total.")")
  call s:progress_bar(2, a:cnt, a:total)
  normal! 2G
  redraw
endfunction

function! s:update_serial(pull)
  let st    = reltime()
  let base  = g:plug_home
  let todo  = copy(g:plugs)
  let total = len(todo)
  let done  = {}

  while !empty(todo)
    for [name, spec] in items(todo)
      let done[name] = 1
      if isdirectory(spec.dir)
        execute 'cd '.spec.dir
        let [valid, msg] = s:git_valid(spec, 0)
        if valid
          let result = a:pull ?
            \ s:system(
            \ printf('git checkout -q %s 2>&1 && git pull origin %s 2>&1',
            \   spec.branch, spec.branch)) : 'Already installed'
          let error = a:pull ? v:shell_error != 0 : 0
        else
          let result = msg
          let error = 1
        endif
      else
        if !isdirectory(base)
          call mkdir(base, 'p')
        endif
        execute 'cd '.base
        let d = shellescape(substitute(spec.dir, '[\/]\+$', '', ''))
        let result = s:system(
              \ printf('git clone --recursive %s -b %s %s 2>&1',
              \ shellescape(spec.uri), shellescape(spec.branch), d))
        let error = v:shell_error != 0
      endif
      cd -
      if error
        let result = '(x) ' . result
      endif
      call append(3, '- ' . name . ': ' . result)
      call s:update_progress(a:pull, len(done), total)
    endfor

    if !empty(s:extend(keys(todo)))
      let todo = filter(copy(g:plugs), '!has_key(done, v:key)')
      let total += len(todo)
      call s:update_progress(a:pull, len(done), total)
    else
      break
    endif
  endwhile

  call setline(1, "Updated. Elapsed time: " . split(reltimestr(reltime(st)))[0] . ' sec.')
endfunction

function! s:update_parallel(pull, threads)
  ruby << EOF
  st    = Time.now
  require 'thread'
  require 'fileutils'
  require 'timeout'
  running = true
  iswin = VIM::evaluate('s:is_win').to_i == 1
  pull  = VIM::evaluate('a:pull').to_i == 1
  base  = VIM::evaluate('g:plug_home')
  all   = VIM::evaluate('copy(g:plugs)')
  limit = VIM::evaluate('get(g:, "plug_timeout", 60)')
  nthr  = VIM::evaluate('a:threads').to_i
  cd    = iswin ? 'cd /d' : 'cd'
  done  = {}
  tot   = 0
  skip  = 'Already installed'
  mtx   = Mutex.new
  take1 = proc { mtx.synchronize { running && all.shift } }
  logh  = proc {
    cnt = done.length
    tot = VIM::evaluate('len(g:plugs)') || tot
    $curbuf[1] = "#{pull ? 'Updating' : 'Installing'} plugins (#{cnt}/#{tot})"
    $curbuf[2] = '[' + ('=' * cnt).ljust(tot) + ']'
    VIM::command('normal! 2G')
    VIM::command('redraw') unless iswin
  }
  log = proc { |name, result, ok|
    mtx.synchronize do
      done[name] = true
      result = '(x) ' + result unless ok
      result = "- #{name}: #{result}"
      $curbuf.append 3, result
      logh.call
    end
  }
  bt = proc { |cmd|
    begin
      fd = nil
      Timeout::timeout(limit) do
        if iswin
          tmp = VIM::evaluate('tempname()')
          system("#{cmd} > #{tmp}")
          data = File.read(tmp).chomp
          File.unlink tmp rescue nil
        else
          fd = IO.popen(cmd)
          data = fd.read.chomp
          fd.close
        end
        [$? == 0, data]
      end
    rescue Timeout::Error, Interrupt => e
      if fd && !fd.closed?
        pids = [fd.pid]
        unless `which pgrep`.empty?
          children = pids
          until children.empty?
            children = children.map { |pid|
              `pgrep -P #{pid}`.lines.map(&:chomp)
            }.flatten
            pids += children
          end
        end
        pids.each { |pid| Process.kill 'TERM', pid.to_i rescue nil }
        fd.close
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

  until all.empty?
    names = all.keys
    [names.length, nthr].min.times do
      mtx.synchronize do
        threads << Thread.new {
          while pair = take1.call
            name = pair.first
            dir, uri, branch = pair.last.values_at *%w[dir uri branch]
            ok, result =
              if File.directory? dir
                ret, data = bt.call "#{cd} #{dir} && git rev-parse --abbrev-ref HEAD 2>&1 && git config remote.origin.url"
                current_uri = data.lines.to_a.last
                if ret && current_uri == uri
                  if pull
                    bt.call "#{cd} #{dir} && git checkout -q #{branch} 2>&1 && git pull origin #{branch} 2>&1"
                  else
                    [true, skip]
                  end
                elsif current_uri =~ /^Interrupted|^Timeout/
                  [false, current_uri]
                else
                  [false, "PlugClean required: #{current_uri}"]
                end
              else
                FileUtils.mkdir_p(base)
                d = dir.sub(%r{[\\/]+$}, '')
                bt.call "#{cd} #{base} && git clone --recursive #{uri} -b #{branch} #{d} 2>&1"
              end
            result = result.lines.to_a.last
            log.call name, (result && result.strip), ok
          end
        } if running
      end
    end
    threads.each(&:join)
    mtx.synchronize { threads.clear }
    all.merge!(VIM::evaluate("s:extend(#{names.inspect})") || {})
    logh.call
  end
  watcher.kill
  $curbuf[1] = "Updated. Elapsed time: #{"%.6f" % (Time.now - st)} sec."
EOF
endfunction

function! s:path(path)
  return substitute(s:is_win ? substitute(a:path, '/', '\', 'g') : a:path,
        \ '[/\\]*$', '', '')
endfunction

function! s:dirpath(path)
  let path = s:path(a:path)
  if s:is_win
    return path !~ '\\$' ? path.'\' : path
  else
    return path !~ '/$' ? path.'/' : path
  endif
endfunction

function! s:glob_dir(path)
  return map(filter(split(globpath(a:path, '**'), '\n'), 'isdirectory(v:val)'), 's:dirpath(v:val)')
endfunction

function! s:progress_bar(line, cnt, total)
  call setline(a:line, '[' . s:lpad(repeat('=', a:cnt), a:total) . ']')
endfunction

function! s:git_valid(spec, cd)
  let ret = 1
  let msg = 'OK'
  if isdirectory(a:spec.dir)
    if a:cd | execute "cd " . a:spec.dir | endif
    let remote = s:system("git config remote.origin.url")

    if remote != a:spec.uri
      let msg = 'Invalid remote: ' . remote . '. Try PlugClean.'
      let ret = 0
    else
      let branch = s:system('git rev-parse --abbrev-ref HEAD')
      if v:shell_error != 0
        let msg = 'Invalid git repository. Try PlugClean.'
        let ret = 0
      elseif a:spec.branch != branch
        let msg = 'Invalid branch: '.branch.'. Try PlugUpdate.'
        let ret = 0
      endif
    endif
    if a:cd | cd - | endif
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
  for spec in values(g:plugs)
    if s:git_valid(spec, 1)[0]
      call add(dirs, spec.dir)
    endif
    let cnt += 1
    call s:progress_bar(2, cnt, total)
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
    let yes = a:force || (input("Proceed? (Y/N) ") =~? '^y')
    call inputrestore()
    if yes
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
    let cp = s:is_win ? 'copy /Y' : 'cp -f'
    call system(printf(
      \ "curl -fLo %s %s && ".cp." %s %s.old && ".mv." %s %s",
      \ new, s:plug_source, mee, mee, new, mee))
    if v:shell_error == 0
      unlet g:loaded_plug
      echo "Downloaded ". s:plug_source
      return 1
    else
      echoerr "Error upgrading vim-plug"
      return 0
    endif
  elseif has('ruby')
    echo "Downloading ". s:plug_source
    ruby << EOF
      require 'open-uri'
      require 'fileutils'
      me  = VIM::evaluate('s:me')
      old = me + '.old'
      new = me + '.new'
      File.open(new, 'w') do |f|
        f << open(VIM::evaluate('s:plug_source')).read
      end
      FileUtils.cp me, old
      File.rename  new, me
EOF
    unlet g:loaded_plug
    echo "Downloaded ". s:plug_source
    return 1
  else
    echoerr "curl executable or ruby support not found"
    return 0
  endif
endfunction

function! s:status()
  call s:prepare()
  call append(0, 'Checking plugins')

  let errs = 0
  for [name, spec] in items(g:plugs)
    let err = 'OK'
    if isdirectory(spec.dir)
      execute 'cd '.spec.dir
      let [valid, msg] = s:git_valid(spec, 0)
      if !valid
        let err = '(x) '. msg
      endif
      cd -
    else
      let err = '(x) Not found. Try PlugInstall.'
    endif
    let errs += err != 'OK'
    call append(2, printf('- %s: %s', name, err))
    call cursor(3, 1)
    redraw
  endfor
  call setline(1, 'Finished. '.errs.' error(s).')
endfunction

