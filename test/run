#!/bin/bash

# Privileged mode, ignores $CDPATH etc.
set -p
set -eu

cd "$(dirname "${BASH_SOURCE[0]}")"

export BASE="$PWD"
export PLUG_SRC="$PWD/../plug.vim"
export PLUG_FIXTURES="$PWD/fixtures"
mkdir -p "$PLUG_FIXTURES"
export TEMP=/tmp/vim-plug-test
rm -rf "$TEMP"
mkdir -p "$TEMP"

cat > $TEMP/mini-vimrc << VIMRC
set rtp+=$TEMP/junegunn/vader.vim
set shell=/bin/bash
VIMRC

clone() {
  if [ ! -d "$2" ]; then
    git clone "$1" "$2"
  fi
}

clone_repos() (
  cd $TEMP
  mkdir -p junegunn vim-scripts jg
  for repo in vader.vim goyo.vim rust.vim seoul256.vim vim-easy-align vim-fnr \
              vim-oblique vim-pseudocl vim-redis vim-emoji; do
    clone https://github.com/junegunn/${repo}.git junegunn/$repo &
  done
  clone https://github.com/vim-scripts/beauty256.git vim-scripts/beauty256 &
  clone https://github.com/junegunn/fzf.git fzf &
  clone https://github.com/yous/subsubmodule.git yous/subsubmodule && \
    (cd yous/subsubmodule && git submodule update --init --recursive &) &
  wait

  clone junegunn/vim-emoji jg/vim-emoji
  cd junegunn/seoul256.vim && git checkout no-t_co && git checkout master
)

make_dirs() (
  rm -rf "$PLUG_FIXTURES/$1"
  mkdir -p "$PLUG_FIXTURES/$1"
  cd "$PLUG_FIXTURES/$1"
  mkdir -p autoload colors ftdetect ftplugin indent plugin syntax
  for d in *; do
    [ -d "$d" ] || continue
    cat > "$d/xxx.vim" << EOF
    " echom expand('<sfile>')
    let g:total_order = get(g:, 'total_order', [])
    let g:$2 = get(g:, '$2', [])
    let s:name = join(filter(['$2', '${1:4}', '$d'], '!empty(v:val)'), '/')
    call add(g:$2, s:name)
    call add(g:total_order, s:name)
EOF
  done
)

gitinit() (
  cd "$PLUG_FIXTURES/$1"
  git init -b master
  git commit -m 'commit' --allow-empty
)

prepare() {
  make_dirs xxx/ xxx
  make_dirs xxx/after xxx
  mkdir -p "$PLUG_FIXTURES/xxx/doc"
  cat > "$PLUG_FIXTURES/xxx/doc/xxx.txt" << DOC
hello *xxx*
DOC
  gitinit xxx

  make_dirs yyy/ yyy
  make_dirs yyy/after yyy
  mkdir -p "$PLUG_FIXTURES/yyy/rtp/doc"
  cat > "$PLUG_FIXTURES/yyy/rtp/doc/yyy.txt" << DOC
hello *yyy*
DOC
  gitinit yyy

  make_dirs z1/ z1
  make_dirs z2/ z2

  rm -rf "$PLUG_FIXTURES/ftplugin-msg"
  mkdir -p "$PLUG_FIXTURES"/ftplugin-msg/{plugin,ftplugin}
  echo "echomsg 'ftplugin-c'" > "$PLUG_FIXTURES/ftplugin-msg/ftplugin/c.vim"
  echo "echomsg 'ftplugin-java'" > "$PLUG_FIXTURES/ftplugin-msg/ftplugin/java.vim"

  chmod +w "$PLUG_FIXTURES/cant-delete/autoload" || rm -rf "$PLUG_FIXTURES/cant-delete"
  mkdir -p "$PLUG_FIXTURES/cant-delete/autoload"
  touch "$PLUG_FIXTURES/cant-delete/autoload/cant-delete.vim"
  chmod -w "$PLUG_FIXTURES/cant-delete/autoload"

  rm -rf $TEMP/new-branch
  cd $TEMP
  git init new-branch -b master
  cd new-branch
  mkdir plugin
  echo 'let g:foo = 1' > plugin/foo.vim
  git add plugin/foo.vim
  git commit -m initial
  git checkout -b plugin
  git checkout master

  cd "$BASE"
}

select_vim() {
  local vim=/usr/bin/vim
  if [ -n "${DEPS:-}" ] && [ -e "${DEPS}/bin/vim" ]; then
    vim="${DEPS}/bin/vim"
  elif [ -e "/usr/local/bin/vim" ]; then
    vim=/usr/local/bin/vim
  fi
  echo $vim
}

clone_repos
prepare

git --version
vim=$(select_vim)
echo "Selected Vim: $vim"
if [ "${1:-}" = '!' ]; then
  FAIL=0
  $vim -Nu $TEMP/mini-vimrc -c 'Vader! test.vader' > /dev/null || FAIL=1
  prepare
  $vim -Nu $TEMP/mini-vimrc -c 'let g:plug_threads = 1 | Vader! test.vader' > /dev/null || FAIL=1
  test $FAIL -eq 0
else
  $vim -Nu $TEMP/mini-vimrc -c 'Vader test.vader'
fi
