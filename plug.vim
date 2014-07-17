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
"   Plug 'junegunn/goyo.vim', { 'on': 'Goyo' }
"   " Plug 'user/repo1', 'branch_or_tag'
"   " Plug 'user/repo2', { 'rtp': 'vim/plugin/dir', 'branch': 'branch_or_tag' }
"   " ...
"
"   call plug#end()
"
" Then :PlugInstall to install plugins. (default: ~/.vim/plugged)
" You can change the location of the plugins with plug#begin(path) call.
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

let s:plug_source = 'https://raw.github.com/junegunn/vim-plug/master/plug.vim'
let s:plug_file = 'Plugfile'
let s:plug_buf = -1
let s:is_win = has('win32') || has('win64')
let s:me = expand('<sfile>:p')

function! plug#begin(...)
  if a:0 > 0
    let home = s:path(fnamemodify(a:1, ':p'))
  elseif exists('g:plug_home')
    let home = s:path(g:plug_home)
  elseif !empty(&rtp)
    let home = s:path(split(&rtp, ',')[0]) . '/plugged'
  else
    echoerr "Unable to determine plug home. Try calling plug#begin() with a path argument."
    return 0
  endif

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
  " we want to keep track of the order plugins where registered.
  let g:plugs_order = []

  command! -nargs=+ -bar Plug   call s:add(1, <args>)
  command! -nargs=* -complete=customlist,s:names PlugInstall call s:install(<f-args>)
  command! -nargs=* -complete=customlist,s:names PlugUpdate  call s:update(<f-args>)
  command! -nargs=0 -bang PlugClean call s:clean('<bang>' == '!')
  command! -nargs=0 PlugUpgrade if s:upgrade() | execute "source ". s:me | endif
  command! -nargs=0 PlugStatus  call s:status()
  command! -nargs=0 PlugDiff    call s:diff()

  return 1
endfunction

function! s:to_a(v)
  return type(a:v) == 3 ? a:v : [a:v]
endfunction

function! plug#end()
  if !exists('g:plugs')
    echoerr 'Call plug#begin() first'
    return
  endif
  let keys = keys(g:plugs)
  while !empty(keys)
    let keys = keys(s:extend(keys))
  endwhile

  if exists('#PlugLOD')
    augroup PlugLOD
      autocmd!
    augroup END
    augroup! PlugLOD
  endif
  let lod = {}

  filetype off
  " we want to make sure the plugin directories are added to rtp in the same
  " order that they are registered with the Plug command. since the s:add_rtp
  " function uses ^= to add plugin directories to the front of the rtp, we
  " need to loop through the plugins in reverse
  for name in reverse(copy(g:plugs_order))
    let plug = g:plugs[name]
    if !has_key(plug, 'on') && !has_key(plug, 'for')
      call s:add_rtp(s:rtp(plug))
      continue
    endif

    if has_key(plug, 'on')
      let commands = s:to_a(plug.on)
      for cmd in commands
        if cmd =~ '^<Plug>.\+'
          if empty(mapcheck(cmd)) && empty(mapcheck(cmd, 'i'))
            for [mode, map_prefix, key_prefix] in
                  \ [['i', "<C-O>", ''], ['n', '', ''], ['v', '', 'gv'], ['o', '', '']]
              execute printf(
              \ "%snoremap <silent> %s %s:<C-U>call <SID>lod_map(%s, %s, '%s')<CR>",
              \ mode, cmd, map_prefix, string(cmd), string(name), key_prefix)
            endfor
          endif
        elseif !exists(':'.cmd)
          execute printf(
          \ "command! -nargs=* -range -bang %s call s:lod_cmd(%s, '<bang>', <line1>, <line2>, <q-args>, %s)",
          \ cmd, string(cmd), string(name))
        endif
      endfor
    endif

    if has_key(plug, 'for')
      for vim in split(globpath(s:rtp(plug), 'ftdetect/**/*.vim'), '\n')
        execute 'source '.vim
      endfor
      for key in s:to_a(plug.for)
        if !has_key(lod, key)
          let lod[key] = []
        endif
        call add(lod[key], name)
      endfor
    endif
  endfor

  for [key, names] in items(lod)
    augroup PlugLOD
      execute printf('autocmd FileType %s call <SID>lod_ft(%s, %s)',
            \ key, string(key), string(reverse(names)))
    augroup END
  endfor
  call s:reorg_rtp()
  filetype plugin indent on
  syntax on
endfunction

if s:is_win
  function! s:rtp(spec)
    let rtp = s:dirpath(a:spec.dir . get(a:spec, 'rtp', ''))
    return substitute(rtp, '\\*$', '', '')
  endfunction

  function! s:path(path)
    return substitute(substitute(a:path, '/', '\', 'g'), '[/\\]*$', '', '')
  endfunction

  function! s:dirpath(path)
    return s:path(a:path) . '\'
  endfunction
else
  function! s:rtp(spec)
    return s:dirpath(a:spec.dir . get(a:spec, 'rtp', ''))
  endfunction

  function! s:path(path)
    return substitute(a:path, '[/\\]*$', '', '')
  endfunction

  function! s:dirpath(path)
    return s:path(a:path) . '/'
  endfunction
endif

function! s:esc(path)
  return substitute(a:path, ' ', '\\ ', 'g')
endfunction

function! s:add_rtp(rtp)
  execute "set rtp^=".s:esc(a:rtp)
  let after = globpath(a:rtp, 'after')
  if isdirectory(after)
    execute "set rtp+=".s:esc(after)
  endif
endfunction

function! s:reorg_rtp()
  if !empty(s:first_rtp)
    execute 'set rtp-='.s:first_rtp
    execute 'set rtp^='.s:first_rtp
  endif
  if s:last_rtp !=# s:first_rtp
    execute 'set rtp-='.s:last_rtp
    execute 'set rtp+='.s:last_rtp
  endif
endfunction

function! s:lod(plug, types)
  let rtp = s:rtp(a:plug)
  call s:add_rtp(rtp)
  for dir in a:types
    for vim in split(globpath(rtp, dir.'/**/*.vim'), '\n')
      execute 'source '.vim
    endfor
  endfor
endfunction

function! s:lod_ft(pat, names)
  for name in a:names
    call s:lod(g:plugs[name], ['plugin', 'after'])
  endfor
  call s:reorg_rtp()
  execute 'autocmd! PlugLOD FileType ' . a:pat
  silent! doautocmd filetypeplugin FileType
endfunction

function! s:lod_cmd(cmd, bang, l1, l2, args, name)
  execute 'delc '.a:cmd
  call s:lod(g:plugs[a:name], ['plugin', 'ftdetect', 'after'])
  call s:reorg_rtp()
  execute printf("%s%s%s %s", (a:l1 == a:l2 ? '' : (a:l1.','.a:l2)), a:cmd, a:bang, a:args)
endfunction

function! s:lod_map(map, name, prefix)
  execute 'unmap '.a:map
  execute 'iunmap '.a:map
  call s:lod(g:plugs[a:name], ['plugin', 'ftdetect', 'after'])
  call s:reorg_rtp()
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

function! s:add(force, ...)
  let opts = { 'branch': 'master', 'frozen': 0 }
  if a:0 == 1
    let plugin = a:1
  elseif a:0 == 2
    let plugin = a:1
    if type(a:2) == 1
      let opts.branch = a:2
    elseif type(a:2) == 4
      call extend(opts, a:2)
      if has_key(opts, 'tag')
        let opts.branch = remove(opts, 'tag')
      endif
    else
      echoerr "Invalid argument type (expected: string or dictionary)"
      return
    endif
  else
    echoerr "Invalid number of arguments (1..2)"
    return
  endif

  let plugin = substitute(plugin, '[/\\]*$', '', '')
  let name = substitute(split(plugin, '/')[-1], '\.git$', '', '')
  if !a:force && has_key(g:plugs, name)
    let s:extended[name] = g:plugs[name]
    return
  endif

  if plugin[0] =~ '[/$~]' || plugin =~? '^[a-z]:'
    let spec = extend(opts, { 'dir': s:dirpath(expand(plugin)) })
  else
    if plugin =~ ':'
      let uri = plugin
    else
      if plugin !~ '/'
        let plugin = 'vim-scripts/'. plugin
      endif
      let uri = 'https://git:@github.com/' . plugin . '.git'
    endif
    let dir = s:dirpath( fnamemodify(join([g:plug_home, name], '/'), ':p') )
    let spec = extend(opts, { 'dir': dir, 'uri': uri })
  endif

  let g:plugs[name] = spec
  if !a:force
    let s:extended[name] = spec
  endif
  let g:plugs_order += [name]
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
      silent! execute "helptags ". join([spec.dir, 'doc'], '/')
    endif
  endfor
  runtime! plugin/*.vim
  runtime! after/*.vim
  silent! source $MYVIMRC
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
  syn match plugName /\(^- \)\@<=[^:]*/
  syn match plugInstall /\(^+ \)\@<=[^:]*/
  syn match plugUpdate /\(^* \)\@<=[^:]*/
  syn match plugCommit /^  [0-9a-z]\{7} .*/ contains=plugRelDate,plugSha
  syn match plugSha /\(^  \)\@<=[0-9a-z]\{7}/ contained
  syn match plugRelDate /([^)]*)$/ contained
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

  hi def link plugName    Label
  hi def link plugInstall Function
  hi def link plugUpdate  Type

  hi def link plugError   Error
  hi def link plugRelDate Comment
  hi def link plugSha     Identifier
endfunction

function! s:lpad(str, len)
  return a:str . repeat(' ', a:len - len(a:str))
endfunction

function! s:lastline(msg)
  let lines = split(a:msg, '\n')
  return get(lines, -1, '')
endfunction

function! s:prepare()
  if bufexists(s:plug_buf)
    let winnr = bufwinnr(s:plug_buf)
    if winnr < 0
      vertical topleft new
      execute 'buffer ' . s:plug_buf
    else
      execute winnr . 'wincmd w'
    endif
    silent %d _
  else
    vertical topleft new
    nnoremap <silent> <buffer> q  :if b:plug_preview==1<bar>pc<bar>endif<bar>q<cr>
    nnoremap <silent> <buffer> D  :PlugDiff<cr>
    nnoremap <silent> <buffer> S  :PlugStatus<cr>
    nnoremap <silent> <buffer> ]] :silent! call <SID>section('')<cr>
    nnoremap <silent> <buffer> [[ :silent! call <SID>section('b')<cr>
    let b:plug_preview = -1
    let s:plug_buf = winbufnr(0)
    call s:assign_name()
  endif
  silent! unmap <buffer> <cr>
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

function! s:finish(pull)
  call append(3, '- Finishing ... ')
  redraw
  call s:apply()
  call s:syntax()
  call setline(4, getline(4) . 'Done!')
  normal! gg
  redraw
  if a:pull
    echo "Press 'D' to see the updated changes."
  endif
endfunction

function! s:is_managed(name)
  return has_key(g:plugs[a:name], 'uri')
endfunction

function! s:names(...)
  return filter(keys(g:plugs), 'stridx(v:val, a:1) == 0 && s:is_managed(v:val)')
endfunction

function! s:update_impl(pull, args) abort
  let args = copy(a:args)
  let threads = (len(args) > 0 && args[-1] =~ '^[1-9][0-9]*$') ?
                  \ remove(args, -1) : get(g:, 'plug_threads', 16)

  let managed = filter(copy(g:plugs), 's:is_managed(v:key)')
  let todo = empty(args) ? filter(managed, '!v:val.frozen') :
                         \ filter(managed, 'index(args, v:key) >= 0')

  if empty(todo)
    echohl WarningMsg
    echo 'No plugin to '. (a:pull ? 'update' : 'install') . '.'
    echohl None
    return
  endif

  call s:prepare()
  call append(0, a:pull ? 'Updating plugins' : 'Installing plugins')
  call append(1, '['. s:lpad('', len(todo)) .']')
  normal! 2G
  redraw

  let len = len(g:plugs)
  if has('ruby') && threads > 1
    try
      call s:update_parallel(a:pull, todo, threads)
    catch
      let lines = getline(4, '$')
      let printed = {}
      silent 4,$d
      for line in lines
        let name = get(matchlist(line, '^. \([^:]\+\):'), 1, '')
        if empty(name) || !has_key(printed, name)
          let printed[name] = 1
          call append('$', line)
        endif
      endfor
      echoerr v:exception
    endtry
  else
    call s:update_serial(a:pull, todo)
  endif
  if len(g:plugs) > len
    call plug#end()
  endif
  call s:finish(a:pull)
endfunction

function! s:extend(names)
  let s:extended = {}
  try
    command! -nargs=+ Plug call s:add(0, <args>)
    for name in a:names
      let plugfile = globpath(s:rtp(g:plugs[name]), s:plug_file)
      if filereadable(plugfile)
        execute "source ". s:esc(plugfile)
      endif
    endfor
  finally
    command! -nargs=+ Plug call s:add(1, <args>)
  endtry
  return s:extended
endfunction

function! s:update_progress(pull, cnt, bar, total)
  call setline(1, (a:pull ? 'Updating' : 'Installing').
        \ " plugins (".a:cnt."/".a:total.")")
  call s:progress_bar(2, a:bar, a:total)
  normal! 2G
  redraw
endfunction

function! s:update_serial(pull, todo)
  let st    = reltime()
  let base  = g:plug_home
  let todo  = copy(a:todo)
  let total = len(todo)
  let done  = {}
  let bar   = ''

  while !empty(todo)
    for [name, spec] in items(todo)
      let done[name] = 1
      if isdirectory(spec.dir)
        execute 'cd '.s:esc(spec.dir)
        let [valid, msg] = s:git_valid(spec, 0, 0)
        if valid
          let result = a:pull ?
            \ s:system(
            \ printf('git checkout -q %s 2>&1 && git pull origin %s 2>&1 && git submodule update --init --recursive 2>&1',
            \   s:shellesc(spec.branch), s:shellesc(spec.branch))) : 'Already installed'
          let error = a:pull ? v:shell_error != 0 : 0
        else
          let result = msg
          let error = 1
        endif
        cd -
      else
        if !isdirectory(base)
          call mkdir(base, 'p')
        endif
        let result = s:system(
              \ printf('git clone --recursive %s -b %s %s 2>&1 && cd %s && git submodule update --init --recursive 2>&1',
              \ s:shellesc(spec.uri),
              \ s:shellesc(spec.branch),
              \ s:shellesc(substitute(spec.dir, '[\/]\+$', '', '')),
              \ s:shellesc(spec.dir)))
        let error = v:shell_error != 0
      endif
      let bar .= error ? 'x' : '='
      call append(3, s:format_message(!error, name, result))
      call s:update_progress(a:pull, len(done), bar, total)
    endfor

    let extended = s:extend(keys(todo))
    if !empty(extended)
      let todo = filter(extended, '!has_key(done, v:key)')
      let total += len(todo)
      call s:update_progress(a:pull, len(done), bar, total)
    else
      break
    endif
  endwhile

  call setline(1, "Updated. Elapsed time: " . split(reltimestr(reltime(st)))[0] . ' sec.')
endfunction

function! s:update_parallel(pull, todo, threads)
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

  require 'set'
  require 'thread'
  require 'fileutils'
  require 'timeout'
  running = true
  st    = Time.now
  iswin = VIM::evaluate('s:is_win').to_i == 1
  pull  = VIM::evaluate('a:pull').to_i == 1
  base  = VIM::evaluate('g:plug_home')
  all   = VIM::evaluate('copy(a:todo)')
  limit = VIM::evaluate('get(g:, "plug_timeout", 60)')
  nthr  = VIM::evaluate('a:threads').to_i
  maxy  = VIM::evaluate('winheight(".")').to_i
  cd    = iswin ? 'cd /d' : 'cd'
  tot   = VIM::evaluate('len(a:todo)') || 0
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
          when true, nil then '-' else 'x' end
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
  bt = proc { |cmd, name, type|
    begin
      fd = nil
      data = ''
      if iswin
        Timeout::timeout(limit) do
          tmp = VIM::evaluate('tempname()')
          system("#{cmd} > #{tmp}")
          data = File.read(tmp).chomp
          File.unlink tmp rescue nil
        end
      else
        fd = IO.popen(cmd).extend(PlugStream)
        first_line = true
        log_prob = 1.0 / nthr
        while line = Timeout::timeout(limit) { fd.get_line }
          data << line
          log.call name, line.chomp, type if name && (first_line || rand < log_prob)
          first_line = false
        end
        fd.close
      end
      [$? == 0, data.chomp]
    rescue Timeout::Error, Interrupt => e
      if fd && !fd.closed?
        pids = [fd.pid]
        unless `which pgrep`.empty?
          children = pids
          until children.empty?
            children = children.map { |pid|
              `pgrep -P #{pid}`.lines.map { |l| l.chomp }
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

  processed = Set.new
  progress = iswin ? '' : '--progress'
  until all.empty?
    names = all.keys
    processed.merge names
    [names.length, nthr].min.times do
      mtx.synchronize do
        threads << Thread.new {
          while pair = take1.call
            name = pair.first
            dir, uri, branch = pair.last.values_at *%w[dir uri branch]
            branch = esc branch
            subm = "git submodule update --init --recursive 2>&1"
            ok, result =
              if File.directory? dir
                dir = esc dir
                ret, data = bt.call "#{cd} #{dir} && git rev-parse --abbrev-ref HEAD 2>&1 && git config remote.origin.url", nil, nil
                current_uri = data.lines.to_a.last
                if !ret
                  if data =~ /^Interrupted|^Timeout/
                    [false, data]
                  else
                    [false, [data.chomp, "PlugClean required."].join($/)]
                  end
                elsif current_uri.sub(/git:@/, '') != uri.sub(/git:@/, '')
                  [false, ["Invalid URI: #{current_uri}",
                           "Expected:    #{uri}",
                           "PlugClean required."].join($/)]
                else
                  if pull
                    log.call name, 'Updating ...', :update
                    bt.call "#{cd} #{dir} && git checkout -q #{branch} 2>&1 && (git pull origin #{branch} #{progress} 2>&1 && #{subm})", name, :update
                  else
                    [true, skip]
                  end
                end
              else
                FileUtils.mkdir_p(base)
                d = esc dir.sub(%r{[\\/]+$}, '')
                log.call name, 'Installing ...', :install
                bt.call "(git clone #{progress} --recursive #{uri} -b #{branch} #{d} 2>&1 && cd #{esc dir} && #{subm})", name, :install
              end
            log.call name, result, ok
          end
        } if running
      end
    end
    threads.each { |t| t.join rescue nil }
    mtx.synchronize { threads.clear }
    extended = Hash[(VIM::evaluate("s:extend(#{names.inspect})") || {}).reject { |k, _|
      processed.include? k
    }]
    tot += extended.length
    all.merge!(extended)
    logh.call
  end
  watcher.kill
  $curbuf[1] = "Updated. Elapsed time: #{"%.6f" % (Time.now - st)} sec."
EOF
endfunction

function! s:shellesc(arg)
  return '"'.substitute(a:arg, '"', '\\"', 'g').'"'
endfunction

function! s:glob_dir(path)
  return map(filter(split(globpath(a:path, '**'), '\n'), 'isdirectory(v:val)'), 's:dirpath(v:val)')
endfunction

function! s:progress_bar(line, bar, total)
  call setline(a:line, '[' . s:lpad(a:bar, a:total) . ']')
endfunction

function! s:compare_git_uri(a, b)
  let a = substitute(a:a, 'git:@', '', '')
  let b = substitute(a:b, 'git:@', '', '')
  return a ==# b
endfunction

function! s:format_message(ok, name, message)
  if a:ok
    return [printf('- %s: %s', a:name, s:lastline(a:message))]
  else
    let lines = map(split(a:message, '\n'), '"    ".v:val')
    return extend([printf('x %s:', a:name)], lines)
  endif
endfunction

function! s:system(cmd)
  return system(s:is_win ? '('.a:cmd.')' : a:cmd)
endfunction

function! s:system_chomp(str)
  let ret = s:system(a:str)
  return v:shell_error ? '' : substitute(ret, '\n$', '', '')
endfunction

function! s:git_valid(spec, check_branch, cd)
  let ret = 1
  let msg = 'OK'
  if isdirectory(a:spec.dir)
    if a:cd | execute "cd " . s:esc(a:spec.dir) | endif
    let result = split(s:system("git rev-parse --abbrev-ref HEAD 2>&1 && git config remote.origin.url"), '\n')
    let remote = result[-1]
    if v:shell_error
      let msg = join([remote, "PlugClean required."], "\n")
      let ret = 0
    elseif !s:compare_git_uri(remote, a:spec.uri)
      let msg = join(['Invalid URI: '.remote,
                    \ 'Expected:    '.a:spec.uri,
                    \ "PlugClean required."], "\n")
      let ret = 0
    elseif a:check_branch
      let branch = result[0]
      if a:spec.branch !=# branch
        let tag = s:system_chomp('git describe --exact-match --tags HEAD 2>&1')
        if a:spec.branch !=# tag
          let msg = printf('Invalid branch/tag: %s (expected: %s). Try PlugUpdate.',
                \ (empty(tag) ? branch : tag), a:spec.branch)
          let ret = 0
        endif
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
  let managed = filter(copy(g:plugs), 's:is_managed(v:key)')
  let [cnt, total] = [0, len(managed)]
  for spec in values(managed)
    if s:git_valid(spec, 0, 1)[0]
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
    let yes = a:force || (input("Proceed? (Y/N) ") =~? '^y')
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
  if executable('curl')
    let mee = s:shellesc(s:me)
    let new = s:shellesc(s:me . '.new')
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
  call append(1, '')

  let ecnt = 0
  let [cnt, total] = [0, len(g:plugs)]
  for [name, spec] in items(g:plugs)
    if has_key(spec, 'uri')
      if isdirectory(spec.dir)
        let [valid, msg] = s:git_valid(spec, 1, 1)
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
    call s:progress_bar(2, repeat('=', cnt), total)
    call append(3, s:format_message(valid, name, msg))
    normal! 2G
    redraw
  endfor
  call setline(1, 'Finished. '.ecnt.' error(s).')
  normal! gg
endfunction

function! s:is_preview_window_open()
  silent! wincmd P
  if &previewwindow
    wincmd p
    return 1
  endif
  return 0
endfunction

function! s:preview_commit()
  if b:plug_preview < 0
    let b:plug_preview = !s:is_preview_window_open()
  endif

  let sha = matchstr(getline('.'), '\(^  \)\@<=[0-9a-z]\{7}')
  if !empty(sha)
    let lnum = line('.')
    while lnum > 1
      let lnum -= 1
      let line = getline(lnum)
      let name = matchstr(line, '\(^- \)\@<=[^:]\+')
      if !empty(name)
        let dir = g:plugs[name].dir
        if isdirectory(dir)
          execute 'cd '.s:esc(dir)
          execute 'pedit '.sha
          wincmd P
          setlocal filetype=git buftype=nofile nobuflisted
          execute 'silent read !git show '.sha
          normal! ggdd
          wincmd p
          cd -
        endif
        break
      endif
    endwhile
  endif
endfunction

function! s:section(flags)
  call search('\(^- \)\@<=.', a:flags)
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

    execute 'cd '.s:esc(v.dir)
    let diff = system('git log --pretty=format:"%h %s (%cr)" "HEAD@{0}...HEAD@{1}"')
    if !v:shell_error && !empty(diff)
      call append(1, '')
      call append(2, '- '.k.':')
      call append(3, map(split(diff, '\n'), '"  ". v:val'))
      let cnt += 1
      normal! gg
      redraw
    endif
    cd -
  endfor

  call setline(1, cnt == 0 ? 'No updates.' : 'Last update:')
  nnoremap <silent> <buffer> <cr> :silent! call <SID>preview_commit()<cr>
  normal! gg
endfunction

let s:first_rtp = s:esc(get(split(&rtp, ','), 0, ''))
let s:last_rtp = s:esc(get(split(&rtp, ','), -1, ''))

let &cpo = s:cpo_save
unlet s:cpo_save

