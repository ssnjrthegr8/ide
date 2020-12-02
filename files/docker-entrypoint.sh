#!/bin/bash

set -e

trap "pkill -P $$ &>/dev/null; exit;" SIGTERM

BRANCH="master"
DIR=""
PREFIX="$HOME/workspace"
INIT_ONLY=0
while [ $# -gt 0 ]; do
    case $1 in
        -r|--repo)
            shift
            REPO="$1"
            ;;
        -b|--branch)
            shift
            BRANCH="$1"
            ;;
        -d|--dir)
            shift
            DIR="$1"
            ;;
        -p|--directory-prefix)
            shift
            PREFIX="$1"
            ;;
        --init-only)
            INIT_ONLY=1
            ;;
        *)
            echo "invalid option $1"
            exit 1
            ;;
    esac

    shift
done

if [[ -n "$REPO" ]]; then
    tmp="$(mktemp -d)"
    echo "cloning $REPO@$BRANCH into $tmp..."
    git clone --branch "$BRANCH" --depth 1 "$REPO"  "$tmp"

    # Ensure there's a leading /
    DIR="/${DIR#/}"

    # Remove trailing /
    SRC="$tmp${DIR%/}"

    echo "removing .cs50.y[a]ml..."
    rm --force "$SRC/.cs50.y{a,}ml"

    echo "moving "$SRC/*" into $PREFIX..."

    # shopt exists with 1 if disabled
    OPT=$(shopt -p dotglob || true)
    shopt -s dotglob
    mv --verbose "$SRC"/* "$PREFIX"
    $OPT

    rm --recursive --force "$tmp"
    if [[ $INIT_ONLY -eq 1 ]]; then
        exit 0
    fi
elif [[ $INIT_ONLY -eq 1 ]]; then
    echo "invalid option --init-only"
    exit 1
fi


echo "starting rsyslog..."
sudo service rsyslog start

USER="$(whoami)"
echo "changing ownership of $HOME/workspace to $USER:$USER..."
sudo chown --recursive "$USER":"$USER" "$HOME/workspace"

echo "removing sudo access..."
sudo sed -i "/^$USER ALL=(ALL) NOPASSWD:ALL$/d" /etc/sudoers


cd /opt/c9/packages/cs50 && npm run standalone$STANDALONE_MODE &
wait
