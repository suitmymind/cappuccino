#!/usr/bin/env bash

function prompt () {
    while true; do
        echo "Enter \"yes\" or \"no\": "
        read response
        case $response
        in
            Y*) return 0 ;;
            y*) return 0 ;;
            N*) return 1 ;;
            n*) return 1 ;;
            *)
        esac
    done
}

function which () {
    echo "$PATH" | tr ":" "\n" | while read line; do [ -f "$line/$1" ] && return 0; done
}

function path_instructions () {
    echo "Add \"$INSTALL_DIRECTORY/bin\" to your PATH environment variable in your shell configuration file (e.x. .profile, .bashrc, .bash_profile)."
    echo "For example:"
    echo "    export PATH=$INSTALL_DIRECTORY/bin:\$PATH"
}

if [ "--clone" = "$1" ]; then
    GITCLONE=1
fi

INSTALL_DIRECTORY="/usr/local/narwhal"
TEMPZIP="/tmp/narwhal.zip"

ORIGINAL_PATH="$PATH"

if ! which "narwhal"; then
    echo "================================================================================"
    echo "Narwhal JavaScript platform is required. Install it automatically?"
    if prompt; then
        echo "================================================================================"
        echo "To use the default location, \"$INSTALL_DIRECTORY\", just hit enter/return, or enter another path:"
        read INSTALL_DIRECTORY_INPUT
        if [ "$INSTALL_DIRECTORY_INPUT" ]; then
            INSTALL_DIRECTORY="$INSTALL_DIRECTORY_INPUT"
        fi

        if [ "$GITCLONE" ]; then
            echo "Cloning Narwhal..."
            git clone git://github.com/280north/narwhal.git "$INSTALL_DIRECTORY"
        else
            echo "Downloading Narwhal..."
            curl -L -o "$TEMPZIP" "http://github.com/280north/narwhal/zipball/master"
            echo "Installing Narwhal..."
            unzip "$TEMPZIP" -d "$INSTALL_DIRECTORY"
            rm "$TEMPZIP"

            mv $INSTALL_DIRECTORY/280north-narwhal-*/* $INSTALL_DIRECTORY/.
            rm -rf $INSTALL_DIRECTORY/280north-narwhal-*
        fi
        
        if ! which "narwhal"; then
            export PATH="$INSTALL_DIRECTORY/bin:$PATH"
        fi
    else
        echo "Narwhal required, aborting installation. To install Narwhal manually follow the instructions at http://narwhaljs.org/"
        exit 1
    fi
fi

if ! which "narwhal"; then
    echo "Error: problem installing Narwhal"
    exit 1
fi

echo "Installing necessary dependencies..."

if [ "$GITCLONE" ]; then
    tusk update
    tusk clone browserjs jake
else
    tusk install browserjs jake
fi

if [ `uname` = "Darwin" ]; then
    echo "================================================================================"
    echo "Would you like to install the JavaScriptCore engine for Narwhal?"
    echo "This is optional but will make building and running Objective-J much faster."
    if prompt; then
        if [ "$GITCLONE" ]; then
            tusk clone narwhal-jsc
        else
            tusk install narwhal-jsc
        fi
        pushd "$INSTALL_DIRECTORY/packages/narwhal-jsc"
        make webkit
        popd
        
        # echo "================================================================================"
        # echo "Rhino is the default Narwhal engine, should we change the default to JavaScriptCore for you?"
        # echo "This can by overridden by setting the NARWHAL_ENGINE environment variable to \"jsc\" or \"rhino\"."
        # echo "(Note: you must use Rhino for certain tools such as \"tusk\")"
        # if prompt; then
        #     tusk engine jsc
        # fi
    fi
fi

export PATH="$ORIGINAL_PATH"
if ! which "narwhal"; then
    
    SHELL_CONFIG=""
    # use order outlined by http://hayne.net/MacDev/Notes/unixFAQ.html#shellStartup
    if [ -f "$HOME/.bash_profile" ]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    elif [ -f "$HOME/.bash_login" ]; then
        SHELL_CONFIG="$HOME/.bash_login"
    elif [ -f "$HOME/.profile" ]; then
        SHELL_CONFIG="$HOME/.profile"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    fi

    EXPORT_PATH_STRING="export PATH=\"$INSTALL_DIRECTORY/bin:\$PATH\""
    
    echo "================================================================================"
    echo "You must add Narwhal's \"bin\" directory to your PATH environment variable. Do this automatically now?"
    echo "\"$EXPORT_PATH_STRING\" will be appended to \"$SHELL_CONFIG\"."
    if prompt; then
        if [ "$SHELL_CONFIG" ]; then
            echo >> "$SHELL_CONFIG"
            echo "$EXPORT_PATH_STRING" >> "$SHELL_CONFIG"
            echo "Added to \"$SHELL_CONFIG\". Restart your shell or run \"source $SHELL_CONFIG\"."
        else
            echo "Couldn't find a shell configuration file."
            path_instructions
        fi
    else
        path_instructions
    fi
fi

echo "Bootstrapping of Narwhal and other required tools is complete. You can now build Cappuccino."
