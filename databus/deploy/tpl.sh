#!/usr/bin/env bash

function List() {
    find tpl -maxdepth 1 -name 'environment*' | awk -v FS="." '{if ($1 == "tpl/environment") print $3}'
}

function Render() {
    mkdir -p tmp
    tpl=$1
    gomplate -f "tpl/environment.sh.${tpl}.tpl" -c .="$HOME/.gomplate/root.json" > "tmp/environment.sh"
}

function Help() {
    echo "sh tpl.sh <action> [env]"
    echo "example:"
    echo "  sh tpl.sh ls"
    echo "  sh tpl.sh render shici2stdout"
}

function main() {
    case "$1" in
        "ls") List;;
        "render") Render "$2";;
        *) Help;;
    esac
}

main "$@"
