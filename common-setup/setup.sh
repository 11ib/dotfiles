#!/bin/bash
# Run to setup with ./setup.sh
MAIN_DIR="$HOME" 
DEST="${MAIN_DIR}"
BASH_DIR="${MAIN_DIR}/.bash.d"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd $SCRIPT_DIR > /dev/null

source "$BASH_DIR"/color_codes.dat

if [ ! -e "$MAIN_DIR" ]; then
  echo Destination ${MAIN_DIR} does not exist
  exit 1
fi

if [ ! -e "$BASH_DIR" ]; then
  mkdir ${BASH_DIR}
fi

rm ${DEST}/.bash_completion.d
ln -sf "$SCRIPT_DIR"/bash_completion.d ${DEST}/.bash_completion.d

ln -sf "$SCRIPT_DIR"/profile ${DEST}/.profile
ln -sf "$SCRIPT_DIR"/bashrc ${DEST}/.bashrc
ln -sf "$SCRIPT_DIR"/gitconfig ${DEST}/.gitconfig
ln -sf "$SCRIPT_DIR"/gitignore_global ${DEST}/.gitignore_global
ln -sf "$SCRIPT_DIR"/pystartup ${DEST}/.pystartup
ln -sf "$SCRIPT_DIR"/tmux.conf ${DEST}/.tmux.conf

for file in "$SCRIPT_DIR"/bash.d/*; do
  ln -sf $file ${BASH_DIR}/
done

# Remove any existing symlink - will fail if it is a dir
rm ${DEST}/.vim 2>/dev/null
if [ ! -e ${DEST}/.vim ]; then  
    ln -sf $SCRIPT_DIR/vim/dotvim ${DEST}/.vim
fi

ln -sf $SCRIPT_DIR/vim/vimrc ${DEST}/.vimrc

# Checks out the Vundle submodule
git submodule update --init --recursive

# Installs all Vundle and quits all windows
    echo  -n -e "${blue}Installing all VIM plugins$X "
    echo -e "${dark_grey}(might take some time the first time ... )$X"
vim +PluginInstall +qall

# Check if YCM has been compiled already - if so, drop compiling again
if [[ ! -e ~/.vim/bundle/YouCompleteMe/third_party/ycmd/ycm_client_support.so ]]; then
	# Compiles YouCompleteMe with semenatic support for C-family languages
	# This needs to happen each time the YCM repo has been deleted
    echo -e "${blue}Compiling YouCompleteMe$X (takes a minute or two)"

	pushd ~/.vim/bundle/YouCompleteMe
	./install.py --clang-completer --gocode-completer
	popd
fi

# Semantic Typescript support for YCM
which tsc > /dev/null || npm install -g typescript

touch ${DEST}/.vimrc.local

popd > /dev/null
