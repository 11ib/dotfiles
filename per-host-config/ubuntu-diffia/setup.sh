#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" > /dev/null

# Get some color codes
source ../../common-setup/bash.d/colors

function strip-comments(){
    grep -v '^#' $@
}

# make /usr/local owned by me
sudo chown -R $(whoami) /usr/local

echo -e $(blue Installing PPA software)
sudo apt-get install software-properties-common

echo -e $(blue Adding external package repositories ...)
while read line; do 

    # strip first four chars: 'ppa:' or 'deb '
    ppa=$(echo $line | sed 's/^....//')

    if $(grep -r -F "$ppa"  /etc/apt/ >> /dev/null); then
        continue
    fi

    sudo add-apt-repository --yes "$line"
    APT_SHOULD_UPDATE=yes
done < repos.local 

# Add keys
echo -e $(blue Adding keys for PPAs ...)
wget -q -O - https://davesteele.github.io/key-366150CE.pub.txt | sudo apt-key add -
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 

echo -e $(blue Updating package lists ...)
if [[ -n $APT_SHOULD_UPDATE ]]; then
    sudo apt-get update
fi


echo -e $(blue Installing local apps ...)
sudo apt-get install -y --no-install-recommends $(strip-comments apps.local)

# upgrade PIP
pip install --upgrade pip

echo -e $(blue Installing python packages ...)
pip install -r python.local 

echo -e $(blue Installing ruby packages ...)
while read line; do 
    if gem list -i $line > /dev/null; then
        continue
    fi

    sudo gem install $line; 
done < ruby.local 


if ! $(which n >> /dev/null); then
    # upgrade Node
    npm install -g n
    n stable
fi

echo -e $(blue Installing Snaps ...) # universal linux packages
installed=$(mktemp)
snap list 2>/dev/null |  awk '{if (NR>1){print $1}}' > $installed

#filters out patterns that are present in the other file, see https://stackoverflow.com/questions/4780203/deleting-lines-from-one-file-which-are-in-another-file
snaps=$(grep -v -f $installed snaps.local)
for pkg in $snaps; do
    snap install $pkg
done

echo -e $(blue Installing Node packages ...)
if which pick_json > /dev/null; then
    installed=$(mktemp)
    npm list -g --depth 1 --json | pick_json -k -e dependencies > $installed

    #filters out patterns that are present in the other file, see https://stackoverflow.com/questions/4780203/deleting-lines-from-one-file-which-are-in-another-file
    node_apps=$(grep -v -f $installed node.local)
else
    node_apps="$(cat node.local)"
fi
# if non-zero, https://unix.stackexchange.com/a/146945/18594
if [[ -n "${node_apps// }" ]]; then
    npm -g install $node_apps 
fi


# setup i3
rm -r ~/.config/i3
ln -s $SCRIPT_DIR/i3-config ~/.config/i3

# fix Alsa for Nforce
ln -sf $SCRIPT_DIR/asoundrc ~/.asoundrc

# for i3 - use custom Chrome to have argument added always
cp google-chrome ~/bin/

sudo apt-get autoremove --yes

# install Github 'hub'
if ! $(which hub >> /dev/null); then
    echo -e $(blue "Installing Github's Hub...")
    VERSION="2.3.0-pre10"
    BASENAME="hub-linux-amd64-$VERSION"
    wget "https://github.com/github/hub/releases/download/v${VERSION}/${BASENAME}.tgz"
    tar xvzf "$BASENAME.tgz"
    cd "$BASENAME"
    sudo ./install
    cd ..
    rimraf "${BASENAME}"*
fi

# install QR copier
go get github.com/claudiodangelis/qr-filetransfer

# Get icons for Caprine and PomoDone due to the Ubuntu XDG_... bug
 sudo cp desktop/*.desktop /usr/share/applications/

# restore current directory
popd > /dev/null
