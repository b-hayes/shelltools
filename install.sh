#!/usr/bin/env bash

#SETUP ERROR HANDLING SO WE DONT KEEP GOING WHEN SOMETHING ELSE FAILS
SCRIPT=$(readlink -f $0)
set -eE
trap 'catchError $LINENO' ERR
catchError() {
    echo "$(basename $SCRIPT) failed!in:
   in file $SCRIPT from line $1"
    exit $1
}

# Setup some vars
SCRIPT_PATH=$(dirname $SCRIPT)
BIN_PATH="$SCRIPT_PATH/bin"
OS=$($BIN_PATH/os)
#Translate bin path for wsl (often install devtools on NTFS so every distro can use the same copy of devtools).
if [[ $OS == "WSL"* ]]; then
    BIN_PATH=(wslpath -w $BIN_PATH)
fi

# Change to script path
cd $SCRIPT_PATH

#SETUP PROFILE
SHELL_RC='.bashrc' #most linux distros use this.
if [ "$OS" == 'Windows' ]; then
    #git bash for windows always runs as a --login shell and doesnt source .bashrc
    SHELL_RC=".bash_profile"
    if [ $(env | grep SESSIONNAME) ]; then
        echo "You should run this script as administrator. I'l re-open as admin for you."
        read -p "Press enter to continue..."
        ./bin/admin #-- install.sh
        exit 1
    fi
fi
if [[ "$OS" == "Mac"* ]]; then
    #Default shell of any modern mac is ZSH and loads zshrc.
    SHELL_RC='.zshrc'
fi


if cat ~/$SHELL_RC | grep -q "$SCRIPT_PATH"; then
    echo "Devtools paths exist."
else
    echo "Setting up devtools for $OS... $SHELL_RC will be used for profile setup."
    read -p "Press enter to continue..."

    #Add the profile
    if [ $OS == "Windows" ]; then
        # No such thing as sudo in windows
        echo "
#DEVTOOLS
# source $SCRIPT_PATH/profile/.profile
" >>~/$SHELL_RC
    else
        sudo echo "
#DEVTOOLS
# source $SCRIPT_PATH/profile/.profile
export PATH=\"$SCRIPT_PATH/bin:\$PATH\"
" >> ~/$SHELL_RC
    fi

    echo "Please close this terminal, open a new one."
    read -p "Press enter..."
    exit 0
fi
