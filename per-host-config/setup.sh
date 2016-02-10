#!/bin/bash

# Put your machine name in this file. 
# The name must match one of the subdirectories in this dir
MACHINE_NAME_FILE="$HOME/.dotfiles-machine"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes
source ../common-setup/bash.d/color_codes.dat

if [[ ! -e $MACHINE_NAME_FILE ]]; then
    echo -e "${dark_red}Missing name of this machine in $MACHINE_NAME_FILE${X}" >> /dev/stderr
    echo -e "${dark_yellow}Create it like this:$X echo my-computer-name > $MACHINE_NAME_FILE$X"
    exit 1
fi

MACHINE=$(cat "$MACHINE_NAME_FILE")

if [[ -e "$MACHINE" ]]; then 
    echo -e "${blue}Setting up local settings for this machine$X"
    cd $MACHINE
    ln -sf `pwd`/bashrc.local "$HOME/.bashrc.local"
    [[ -e ./setup.sh ]] && ./setup.sh
else
    echo -e "${dark_red}Missing local settings directory: $SCRIPT_DIR/$MACHINE$X" >> /dev/stderr
    exit 1
fi

popd >> /dev/null
